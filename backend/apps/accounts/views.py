from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from django.contrib.auth import get_user_model
from .serializers import (
    RegisterSerializer,
    ExamSecureTokenObtainPairSerializer,
    UserPublicSerializer,
    ProfileUpdateSerializer,
    PasswordResetSerializer,
)
from apps.audit.utils import log_action

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        user = serializer.save()
        log_action(user, "REGISTER", "User", user.id, "Inscription étudiant")


class LoginView(TokenObtainPairView):
    serializer_class = ExamSecureTokenObtainPairSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            email = request.data.get("email") or request.data.get("username")
            log_action(None, "LOGIN", "User", None, f"Connexion: {email}")
        return response


class RefreshView(TokenRefreshView):
    permission_classes = [permissions.AllowAny]


class LogoutView(APIView):
    """
    Blackliste le refresh token (nécessite rest_framework_simplejwt.token_blacklist
    activé côté INSTALLED_APPS pour une révocation persistante en base).
    """

    def post(self, request):
        from rest_framework_simplejwt.tokens import RefreshToken

        refresh = request.data.get("refresh")
        try:
            if refresh:
                RefreshToken(refresh).blacklist()
        except Exception:
            return Response({"detail": "Session invalide."}, status=400)
        log_action(request.user, "LOGOUT", "User", request.user.id, "Déconnexion")
        return Response({"success": True})


class ProfileView(generics.RetrieveUpdateAPIView):
    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ("PATCH", "PUT"):
            return ProfileUpdateSerializer
        return UserPublicSerializer


class PasswordResetView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"]

        user = User.objects.filter(email=email).first()
        if user:
            log_action(user, "PASSWORD_RESET_REQUEST", "User", user.id, "Demande de réinitialisation")

        return Response({"success": True, "message": "Si cet e-mail correspond à un compte, les instructions ont été envoyées."})

