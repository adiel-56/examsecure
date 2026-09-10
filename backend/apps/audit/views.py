from rest_framework import generics, permissions
from apps.core_utils.permissions import IsAdminRole
from .models import AuditLog
from .serializers import AuditLogSerializer

class AuditLogListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.select_related("utilisateur").all()
    filterset_fields = ["action", "utilisateur"]
    search_fields = ["action", "informations"]
