"""
Génération et validation des tokens de téléchargement temporaires.

Le token brut n'est communiqué qu'une seule fois à Flutter, dans la
réponse HTTP. Seul son hash (SHA-256) est conservé côté serveur, afin
qu'une fuite de la base de données ne permette pas de reconstruire un
token exploitable (section 16 du cahier des charges).
"""
import hashlib
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from .models import DownloadToken


def _hash_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode()).hexdigest()


def issue_download_token(achat, device_id: str | None = None):
    raw_token = secrets.token_urlsafe(48)
    expiration = timezone.now() + timedelta(minutes=settings.DOWNLOAD_TOKEN_TTL_MINUTES)

    download_token = DownloadToken.objects.create(
        achat=achat,
        token_hash=_hash_token(raw_token),
        device_identifier=device_id or "",
        expiration=expiration,
    )
    return raw_token, download_token


class TokenValidationError(Exception):
    pass


def consume_download_token(raw_token: str, user, device_id: str | None = None):
    """
    Valide puis marque un token comme utilisé (usage unique). Vérifie :
    utilisateur propriétaire de l'achat, appareil (si renseigné),
    expiration, révocation, et non-réutilisation.
    """
    token_hash = _hash_token(raw_token)
    if not device_id:
        raise TokenValidationError("Identifiant appareil manquant.")

    with transaction.atomic():
        dt = DownloadToken.objects.select_for_update().select_related(
            "achat", "achat__etudiant"
        ).filter(token_hash=token_hash).first()

        if not dt:
            raise TokenValidationError("Token invalide.")
        if dt.revoked:
            raise TokenValidationError("Token révoqué.")
        if dt.used_at is not None:
            raise TokenValidationError("Token déjà utilisé.")
        if dt.expiration < timezone.now():
            raise TokenValidationError("Token expiré.")
        if dt.achat.etudiant_id != user.id:
            raise TokenValidationError("Ce token n'appartient pas à cet utilisateur.")
        if dt.device_identifier != device_id:
            raise TokenValidationError("Cet appareil ne correspond pas à la demande initiale.")

        dt.used_at = timezone.now()
        dt.save(update_fields=["used_at"])

        achat = dt.achat
        achat.nombre_telechargements += 1
        if achat.date_premier_telechargement is None:
            achat.date_premier_telechargement = timezone.now()
        update_fields = ["nombre_telechargements", "date_premier_telechargement"]
        if not achat.appareil_associe and device_id:
            from apps.devices.models import Device
            dev = Device.objects.filter(device_identifier=device_id).first()
            if dev:
                achat.appareil_associe = dev
                update_fields.append("appareil_associe")
        achat.save(update_fields=update_fields)

    return dt
