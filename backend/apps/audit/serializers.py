from rest_framework import serializers
from .models import AuditLog

class AuditLogSerializer(serializers.ModelSerializer):
    utilisateur_nom = serializers.SerializerMethodField()

    class Meta:
        model = AuditLog
        fields = ["id", "utilisateur", "utilisateur_nom", "action", "objet_type", "objet_id", "informations", "created_at"]

    def get_utilisateur_nom(self, obj):
        return str(obj.utilisateur) if obj.utilisateur else "Système"
