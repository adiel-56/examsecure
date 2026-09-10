from rest_framework import generics, permissions
from apps.core_utils.permissions import IsAdminRole
from apps.audit.utils import log_action
from .models import Filiere
from .serializers import FiliereSerializer

class AdminFiliereListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = FiliereSerializer
    queryset = Filiere.objects.all()

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, "FILIERE_CREATED", "Filiere", obj.id, obj.nom)

class AdminFiliereDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = FiliereSerializer
    queryset = Filiere.objects.all()

    def perform_update(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, "FILIERE_UPDATED", "Filiere", obj.id, obj.nom)

    def perform_destroy(self, instance):
        log_action(self.request.user, "FILIERE_DELETED", "Filiere", instance.id, instance.nom)
        instance.delete()
