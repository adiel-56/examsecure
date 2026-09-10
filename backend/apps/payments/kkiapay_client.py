"""
Client d'appel à l'API KkiaPay pour vérifier une transaction côté serveur.

RÈGLE ABSOLUE (section 21 du cahier des charges) :
la réponse envoyée par Flutter n'est JAMAIS suffisante pour valider un
paiement. Django doit systématiquement re-vérifier auprès de KkiaPay :
référence, montant, devise, statut.
"""
import requests
from django.conf import settings


class KkiaPayVerificationError(Exception):
    pass


def verify_transaction(reference: str) -> dict:
    """
    Interroge l'API KkiaPay pour un identifiant de transaction donné et
    retourne le statut réel côté fournisseur de paiement.
    """
    headers = {
        "x-private-key": settings.KKIAPAY_PRIVATE_KEY,
        "x-secret-key": settings.KKIAPAY_SECRET,
        "x-public-key": settings.KKIAPAY_PUBLIC_KEY,
        "Content-Type": "application/json",
    }
    try:
        response = requests.post(
            settings.KKIAPAY_VERIFY_URL,
            json={"transactionId": reference},
            headers=headers,
            timeout=15,
        )
    except requests.RequestException as exc:
        raise KkiaPayVerificationError(f"Impossible de contacter KkiaPay: {exc}") from exc

    if response.status_code != 200:
        raise KkiaPayVerificationError(f"Réponse KkiaPay invalide ({response.status_code})")

    return response.json()
