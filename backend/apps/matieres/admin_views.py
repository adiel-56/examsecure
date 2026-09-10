from rest_framework import generics, permissions
from apps.core_utils.permissions import IsAdminRole
from apps.audit.utils import log_action
from .models import Matiere
from .serializers import MatiereSerializer

class AdminMatiereListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = MatiereSerializer
    queryset = Matiere.objects.all()

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, "MATIERE_CREATED", "Matiere", obj.id, obj.nom)

class AdminMatiereDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = MatiereSerializer
    queryset = Matiere.objects.all()

    def perform_update(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, "MATIERE_UPDATED", "Matiere", obj.id, obj.nom)

    def perform_destroy(self, instance):
        log_action(self.request.user, "MATIERE_DELETED", "Matiere", instance.id, instance.nom)
        instance.delete()
