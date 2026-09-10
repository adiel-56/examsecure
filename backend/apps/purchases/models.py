from django.conf import settings
from django.db import models
from apps.exams.models import Document
from apps.payments.models import Transaction
from apps.devices.models import Device

class Achat(models.Model):
    class Statut(models.TextChoices):
        VALIDE = "VALID", "Validé"
        BLOQUE = "BLOCKED", "Bloqué (limite téléchargement atteinte)"
        REVOQUE = "REVOKED", "Révoqué"

    etudiant = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="achats")
    document = models.ForeignKey(Document, on_delete=models.CASCADE, related_name="achats", db_column="epreuve_id")
    transaction = models.OneToOneField(Transaction, on_delete=models.CASCADE, related_name="achat")

    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.VALIDE)
    appareil_associe = models.ForeignKey(Device, null=True, blank=True, on_delete=models.SET_NULL, related_name="achats")
    nombre_telechargements = models.PositiveIntegerField(default=0)
    date_premier_telechargement = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Règle métier : 1 téléchargement autorisé par défaut, sauf déblocage explicite admin
    LIMITE_TELECHARGEMENTS = 1

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Achat"
        verbose_name_plural = "Achats"

    @property
    def epreuve(self):
        return self.document

    @epreuve.setter
    def epreuve(self, value):
        self.document = value

    def peut_telecharger(self):
        return self.statut == self.Statut.VALIDE and self.nombre_telechargements < self.LIMITE_TELECHARGEMENTS

    def __str__(self):
        return f"{self.etudiant} · {self.document.titre}"
