import uuid
from django.conf import settings
from django.db import models
from apps.exams.models import Document


class PaymentConfig(models.Model):
    """
    Configuration dynamique du paiement manuel Mobile Money.
    Modifiable par l'administrateur depuis le dashboard et récupérée par l'app Flutter.
    """
    momo_number = models.CharField(
        max_length=50,
        default="+229 97 00 00 00",
        help_text="Numéro Mobile Money de réception des paiements (ex: +229 97 00 00 00)"
    )
    beneficiary_name = models.CharField(
        max_length=150,
        default="Administration ExamSecure",
        help_text="Nom du compte / bénéficiaire Mobile Money"
    )
    instructions = models.TextField(
        default=(
            "Pour accéder à ce document, veuillez envoyer le montant indiqué au numéro "
            "Mobile Money de l'administration. Après le paiement, revenez dans l'application "
            "et envoyez votre reçu (capture d'écran ou PDF) pour vérification."
        ),
        help_text="Consignes affichées à l'étudiant avant le paiement"
    )
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Configuration Paiement Mobile Money"
        verbose_name_plural = "Configurations Paiement Mobile Money"

    def __str__(self):
        return f"Config Momo : {self.momo_number} ({self.beneficiary_name})"

    @classmethod
    def get_solo(cls):
        """Retourne l'unique instance de configuration ou en crée une par défaut."""
        config, _ = cls.objects.get_or_create(
            id=1,
            defaults={
                "momo_number": "+229 97 00 00 00",
                "beneficiary_name": "Administration ExamSecure",
                "instructions": (
                    "Pour accéder à ce document, veuillez envoyer le montant indiqué au numéro "
                    "Mobile Money de l'administration. Après le paiement, revenez dans l'application "
                    "et envoyez votre reçu (capture d'écran ou PDF) pour vérification."
                ),
                "is_active": True,
            }
        )
        return config


class Transaction(models.Model):
    class Statut(models.TextChoices):
        # Statuts Paiement Manuel
        PENDING_VERIFICATION = "PENDING_VERIFICATION", "Reçu soumis (En attente de validation)"
        PAID = "PAID", "Validé par l'administrateur"
        REJECTED = "REJECTED", "Rejeté par l'administrateur"
        # Statuts Rétro-compatibles KkiaPay
        PENDING = "PENDING", "En attente"
        SUCCESS = "SUCCESS", "Succès"
        FAILED = "FAILED", "Échoué"
        PAYMENT_SUBMITTED = "PAYMENT_SUBMITTED", "Paiement soumis"

    class MoyenPaiement(models.TextChoices):
        MOBILE_MONEY = "MOBILE_MONEY", "Mobile Money (Manuel)"
        KKIAPAY = "KKIAPAY", "KkiaPay (Automatique)"
        CARD = "CARD", "Carte bancaire"

    etudiant = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="transactions"
    )
    document = models.ForeignKey(
        Document,
        on_delete=models.CASCADE,
        related_name="transactions",
        db_column="epreuve_id"
    )
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    devise = models.CharField(max_length=10, default="XOF")
    moyen_paiement = models.CharField(
        max_length=20,
        choices=MoyenPaiement.choices,
        default=MoyenPaiement.MOBILE_MONEY
    )

    # Référence technique ou KkiaPay
    reference_kkiapay = models.CharField(max_length=150, blank=True)
    identifiant_externe = models.CharField(max_length=150, blank=True)

    # Données du paiement manuel Mobile Money
    numero_telephone = models.CharField(
        max_length=30,
        blank=True,
        help_text="Numéro utilisé par l'étudiant pour effectuer le transfert"
    )
    reference_recu = models.CharField(
        max_length=150,
        blank=True,
        help_text="Référence de transaction / SMS de confirmation"
    )
    recu_fichier = models.FileField(
        upload_to="receipts/%Y/%m/",
        null=True,
        blank=True,
        help_text="Preuve de paiement (Image ou PDF)"
    )
    commentaire_etudiant = models.TextField(
        blank=True,
        help_text="Commentaire facultatif de l'étudiant"
    )

    # Traitement Administrateur
    statut = models.CharField(
        max_length=25,
        choices=Statut.choices,
        default=Statut.PENDING_VERIFICATION
    )
    motif_refus = models.TextField(
        blank=True,
        help_text="Motif obligatoire en cas de rejet par l'administrateur"
    )
    administrateur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="transactions_traitees"
    )
    date_traitement = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"

    @property
    def epreuve(self):
        return self.document

    @epreuve.setter
    def epreuve(self, val):
        self.document = val

    def save(self, *args, **kwargs):
        if not self.reference_kkiapay:
            self.reference_kkiapay = f"MOMO-{uuid.uuid4().hex[:12].upper()}"
        super().save(*args, **kwargs)

    @property
    def is_validated(self):
        return self.statut in (self.Statut.PAID, self.Statut.SUCCESS)

    @property
    def is_pending(self):
        return self.statut in (self.Statut.PENDING_VERIFICATION, self.Statut.PAYMENT_SUBMITTED, self.Statut.PENDING)

    def __str__(self):
        return f"{self.etudiant} · {self.document.titre} · {self.montant} {self.devise} ({self.statut})"
