import django_filters
from apps.matieres.models import Matiere
from .models import Document


class DocumentFilter(django_filters.FilterSet):
    matiere = django_filters.NumberFilter(field_name="matieres__id", distinct=True)
    matieres = django_filters.ModelMultipleChoiceFilter(
        queryset=Matiere.objects.all(),
        field_name="matieres",
        distinct=True
    )
    filiere = django_filters.NumberFilter(field_name="filiere__id")

    class Meta:
        model = Document
        fields = ["filiere", "matiere", "matieres", "annee_academique", "type_contenu", "statut"]
