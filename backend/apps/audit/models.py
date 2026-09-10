from django.conf import settings
from django.db import models

class AuditLog(models.Model):
    utilisateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="audit_logs"
    )
    action = models.CharField(max_length=80)
    objet_type = models.CharField(max_length=80, blank=True)
    objet_id = models.CharField(max_length=40, blank=True, null=True)
    informations = models.TextField(blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.action} · {self.created_at:%Y-%m-%d %H:%M}"
