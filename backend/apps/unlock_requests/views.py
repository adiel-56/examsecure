from rest_framework import generics, permissions
from .models import UnlockRequest
from .serializers import UnlockRequestSerializer, UnlockRequestCreateSerializer
from apps.audit.utils import log_action

class UnlockRequestListCreateView(generics.ListCreateAPIView):
    def get_serializer_class(self):
        return UnlockRequestCreateSerializer if self.request.method == "POST" else UnlockRequestSerializer

    def get_queryset(self):
        return UnlockRequest.objects.filter(etudiant=self.request.user)

    def perform_create(self, serializer):
        obj = serializer.save(etudiant=self.request.user)
        log_action(self.request.user, "UNLOCK_REQUEST_CREATED", "UnlockRequest", obj.id, obj.motif[:200])

class UnlockRequestDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UnlockRequestSerializer

    def get_queryset(self):
        return UnlockRequest.objects.filter(etudiant=self.request.user)
