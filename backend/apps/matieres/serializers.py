from rest_framework import serializers
from .models import Matiere

class MatiereSerializer(serializers.ModelSerializer):
    filiere_nom = serializers.CharField(source="filiere.nom", read_only=True)

    class Meta:
        model = Matiere
        fields = ["id", "nom", "filiere", "filiere_nom", "created_at", "updated_at"]
