from rest_framework import serializers
from .models import Achat

class AchatSerializer(serializers.ModelSerializer):
    document_titre = serializers.CharField(source="document.titre", read_only=True)
    document_prix = serializers.DecimalField(source="document.prix", max_digits=10, decimal_places=2, read_only=True)
    couverture_url = serializers.SerializerMethodField()

    # Alias rétro-compatibilité
    epreuve_titre = serializers.CharField(source="document.titre", read_only=True)
    epreuve_prix = serializers.DecimalField(source="document.prix", max_digits=10, decimal_places=2, read_only=True)
    epreuve = serializers.PrimaryKeyRelatedField(source="document", read_only=True)

    class Meta:
        model = Achat
        fields = [
            "id", "etudiant", "document", "document_titre", "document_prix", "couverture_url",
            "epreuve", "epreuve_titre", "epreuve_prix", "transaction",
            "statut", "appareil_associe", "nombre_telechargements",
            "date_premier_telechargement", "created_at",
        ]
        read_only_fields = fields

    def get_couverture_url(self, obj):
        if obj.document and obj.document.couverture:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.document.couverture.url)
            return obj.document.couverture.url
        return None

class AchatAdminSerializer(AchatSerializer):
    etudiant_nom = serializers.CharField(source="etudiant.get_full_name", read_only=True)

    class Meta(AchatSerializer.Meta):
        fields = AchatSerializer.Meta.fields + ["etudiant_nom"]
