from django.utils import timezone
from django.db.models import Count
from rest_framework import generics, permissions
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from apps.core_utils.permissions import IsAdminRole
from apps.audit.utils import log_action
from .models import Document
from .serializers import DocumentAdminSerializer
from .filters import DocumentFilter

class AdminDocumentListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = DocumentAdminSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    queryset = (
        Document.objects.annotate(achats_count=Count("achats"))
        .select_related("filiere")
        .prefetch_related("matieres")
        .order_by("-created_at")
    )
    filterset_class = DocumentFilter
    search_fields = ["titre", "matieres__nom"]

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, "DOCUMENT_CREATED", "Document", obj.id, obj.titre)

class AdminDocumentDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = DocumentAdminSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    queryset = Document.objects.select_related("filiere").prefetch_related("matieres")

    def perform_update(self, serializer):
        obj = serializer.save()
        if obj.statut == Document.Statut.PUBLIE and not obj.date_publication:
            obj.date_publication = timezone.now()
            obj.save(update_fields=["date_publication"])
        log_action(self.request.user, "DOCUMENT_UPDATED", "Document", obj.id, obj.titre)

    def perform_destroy(self, instance):
        log_action(self.request.user, "DOCUMENT_DELETED", "Document", instance.id, instance.titre)
        instance.delete()


# Alias de rétro-compatibilité
AdminEpreuveListCreateView = AdminDocumentListCreateView
AdminEpreuveDetailView = AdminDocumentDetailView
