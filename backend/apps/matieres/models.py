from django.db import models
from apps.filieres.models import Filiere

class Matiere(models.Model):
    nom = models.CharField(max_length=150)
    filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE, related_name="matieres")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["nom"]
        unique_together = ("nom", "filiere")

    def __str__(self):
        return f"{self.nom} ({self.filiere.nom})"
