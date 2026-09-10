from rest_framework import generics, permissions
from .models import Document
from .serializers import DocumentListSerializer, DocumentDetailSerializer
from .filters import DocumentFilter

class DocumentListView(generics.ListAPIView):
    """Catalogue étudiant : uniquement les documents publiés."""

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DocumentListSerializer
    filterset_class = DocumentFilter
    search_fields = ["titre", "matieres__nom"]
    ordering_fields = ["prix", "date_publication", "created_at"]

    def get_queryset(self):
        return (
            Document.objects.filter(statut=Document.Statut.PUBLIE)
            .select_related("filiere")
            .prefetch_related("matieres")
            .distinct()
        )

class DocumentDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DocumentDetailSerializer

    def get_queryset(self):
        return (
            Document.objects.filter(statut=Document.Statut.PUBLIE)
            .select_related("filiere")
            .prefetch_related("matieres")
        )


# Alias de rétro-compatibilité
EpreuveListView = DocumentListView
EpreuveDetailView = DocumentDetailView
