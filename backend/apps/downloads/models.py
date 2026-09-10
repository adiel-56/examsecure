from django.db import models
from apps.purchases.models import Achat

class DownloadToken(models.Model):
    achat = models.ForeignKey(Achat, on_delete=models.CASCADE, related_name="download_tokens")
    # Seul le hash est stocké : le token brut n'est jamais persisté (section 16)
    token_hash = models.CharField(max_length=128, unique=True)
    device_identifier = models.CharField(max_length=255, blank=True)
    expiration = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    revoked = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Token achat #{self.achat_id}"
