from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from django.db.models import Count

from apps.core_utils.permissions import IsAdminRole
from apps.audit.utils import log_action
from .serializers import UserPublicSerializer, UserAdminListSerializer

User = get_user_model()


class AdminUserListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = UserAdminListSerializer
    queryset = (
        User.objects.filter(role=User.Role.STUDENT)
        .select_related("filiere")
        .annotate(achats_count=Count("achats"))
        .order_by("-created_at")
    )
    search_fields = ["first_name", "last_name", "email"]
    filterset_fields = ["is_active", "is_suspended", "filiere"]


class AdminUserDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = UserPublicSerializer
    queryset = User.objects.all()


class AdminUserToggleActiveView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def patch(self, request, pk):
        user = User.objects.get(pk=pk)
        user.is_suspended = not user.is_suspended
        user.save(update_fields=["is_suspended"])
        log_action(
            request.user,
            "USER_SUSPENDED" if user.is_suspended else "USER_REACTIVATED",
            "User",
            user.id,
            f"Statut modifié par {request.user}",
        )
        return Response(UserPublicSerializer(user).data)
