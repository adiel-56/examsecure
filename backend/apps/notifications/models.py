from django.conf import settings
from django.db import models

class Notification(models.Model):
    class Type(models.TextChoices):
        PAYMENT = "PAYMENT", "Paiement"
        PURCHASE = "PURCHASE", "Achat"
        UNLOCK = "UNLOCK", "Déblocage"
        EXAM = "EXAM", "Nouveau document"
        INFO = "INFO", "Information"

    utilisateur = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    titre = models.CharField(max_length=150)
    message = models.TextField()
    type = models.CharField(max_length=10, choices=Type.choices, default=Type.INFO)
    lu = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.titre
