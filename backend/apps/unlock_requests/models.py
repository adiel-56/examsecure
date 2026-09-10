from django.conf import settings
from django.db import models
from apps.purchases.models import Achat
from apps.devices.models import Device

class UnlockRequest(models.Model):
    class Statut(models.TextChoices):
        PENDING = "PENDING", "En attente"
        APPROVED = "APPROVED", "Approuvée"
        REJECTED = "REJECTED", "Refusée"

    etudiant = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="unlock_requests")
    achat = models.ForeignKey(Achat, on_delete=models.CASCADE, related_name="unlock_requests")
    appareil_actuel = models.ForeignKey(Device, null=True, blank=True, on_delete=models.SET_NULL, related_name="unlock_requests")
    motif = models.TextField()
    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.PENDING)
    reponse_admin = models.TextField(blank=True)
    administrateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="unlock_requests_traitees"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Déblocage #{self.id} · {self.statut}"
