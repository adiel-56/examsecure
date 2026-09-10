from rest_framework import serializers
from .models import Filiere

class FiliereSerializer(serializers.ModelSerializer):
    matieres_count = serializers.IntegerField(source="matieres.count", read_only=True)

    class Meta:
        model = Filiere
        fields = ["id", "nom", "description", "matieres_count", "created_at", "updated_at"]
