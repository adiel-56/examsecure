from django.db import models
from apps.filieres.models import Filiere
from apps.matieres.models import Matiere
from .storage import private_storage

class Document(models.Model):
    class Statut(models.TextChoices):
        BROUILLON = "DRAFT", "Brouillon"
        PUBLIE = "PUBLISHED", "Publié"
        ARCHIVE = "ARCHIVED", "Archivé"

    class TypeContenu(models.TextChoices):
        EXAMEN = "EXAM", "Examen"
        TD = "TD", "Travaux dirigés"
        CORRIGE = "CORRECTION", "Corrigé"
        COURS = "COURSE", "Support de cours"
        DOCUMENT = "DOCUMENT", "Autre document"

    titre = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    matieres = models.ManyToManyField(Matiere, related_name="documents", blank=True)
    filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE, related_name="documents")
    annee_academique = models.CharField(max_length=20)
    prix = models.DecimalField(max_digits=10, decimal_places=2)
    devise = models.CharField(max_length=10, default="XOF")
    nombre_pages = models.PositiveIntegerField(default=0)
    type_contenu = models.CharField(max_length=15, choices=TypeContenu.choices, default=TypeContenu.EXAMEN)

    # Photo de couverture (stockage média standard / public)
    couverture = models.ImageField(upload_to="couvertures/", blank=True, null=True, verbose_name="Photo de couverture")

    # Ces fichiers ne sont JAMAIS exposés par une URL publique (stockage privé sécurisé)
    fichier_original = models.FileField(storage=private_storage, upload_to="originals/")
    fichier_securise = models.FileField(storage=private_storage, upload_to="secured/", blank=True, null=True)

    statut = models.CharField(max_length=15, choices=Statut.choices, default=Statut.BROUILLON)
    date_publication = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "exams_epreuve"
        ordering = ["-created_at"]
        verbose_name = "Document"
        verbose_name_plural = "Documents"

    def __str__(self):
        return self.titre

    @property
    def matiere(self):
        return self.matieres.first()

    @property
    def matiere_id(self):
        m = self.matieres.first()
        return m.id if m else None

    @property
    def matieres_noms_list(self):
        return list(self.matieres.values_list("nom", flat=True))

    @property
    def matieres_noms_str(self):
        noms = self.matieres_noms_list
        return ", ".join(noms) if noms else ""


# Alias de rétro-compatibilité Python
Epreuve = Document
