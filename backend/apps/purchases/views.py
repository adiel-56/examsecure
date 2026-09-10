from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Achat
from .serializers import AchatSerializer
from apps.downloads.services import issue_download_token

class MyPurchasesListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AchatSerializer

    def get_queryset(self):
        return Achat.objects.filter(etudiant=self.request.user).select_related("document")

class MyPurchaseDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AchatSerializer

    def get_queryset(self):
        return Achat.objects.filter(etudiant=self.request.user)

class RequestDownloadView(APIView):
    """
    Émet un DownloadToken temporaire pour un achat, seulement si :
    - l'achat appartient à l'utilisateur connecté
    - l'achat est VALID
    - la limite de téléchargement n'est pas dépassée
    (voir apps.downloads pour la génération et l'usage du token)
    """

    def post(self, request, pk):
        device_identifier = request.data.get("device_identifier")
        if not device_identifier:
            return Response({"detail": "Identifiant appareil manquant."}, status=400)
        achat = Achat.objects.filter(pk=pk, etudiant=request.user).first()
        if not achat:
            return Response({"detail": "Achat introuvable."}, status=404)
        if not achat.peut_telecharger():
            return Response(
                {"detail": "Limite de téléchargement atteinte. Faites une demande de déblocage."},
                status=409,
            )
        token_value, download_token = issue_download_token(achat, device_id=device_identifier)
        return Response({
            "download_token": token_value,
            "expires_at": download_token.expiration,
        })
