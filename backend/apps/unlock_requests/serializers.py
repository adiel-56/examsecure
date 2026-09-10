from rest_framework import serializers
from .models import UnlockRequest

class UnlockRequestSerializer(serializers.ModelSerializer):
    document_titre = serializers.CharField(source="achat.document.titre", read_only=True)
    epreuve_titre = serializers.CharField(source="achat.document.titre", read_only=True)

    class Meta:
        model = UnlockRequest
        fields = [
            "id", "etudiant", "achat", "document_titre", "epreuve_titre", "appareil_actuel", "motif",
            "statut", "reponse_admin", "administrateur", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "statut", "reponse_admin", "administrateur", "created_at", "updated_at"]

class UnlockRequestCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UnlockRequest
        fields = ["achat", "appareil_actuel", "motif"]

class UnlockRequestAdminUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UnlockRequest
        fields = ["statut", "reponse_admin"]
