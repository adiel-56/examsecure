from rest_framework import generics, permissions
from apps.core_utils.permissions import IsAdminRole
from .models import Achat
from .serializers import AchatAdminSerializer

class AdminAchatListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = AchatAdminSerializer
    queryset = Achat.objects.select_related("etudiant", "document", "transaction").all()
    filterset_fields = ["statut", "document"]
