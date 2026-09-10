from rest_framework import generics, permissions
from rest_framework.response import Response
from apps.core_utils.permissions import IsAdminRole
from apps.audit.utils import log_action
from apps.notifications.utils import notify
from .models import UnlockRequest
from .serializers import UnlockRequestSerializer, UnlockRequestAdminUpdateSerializer

class AdminUnlockRequestListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = UnlockRequestSerializer
    queryset = UnlockRequest.objects.select_related("etudiant", "achat", "achat__document").all()
    filterset_fields = ["statut"]

class AdminUnlockRequestUpdateView(generics.UpdateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = UnlockRequestAdminUpdateSerializer
    queryset = UnlockRequest.objects.all()

    def perform_update(self, serializer):
        obj = serializer.save(administrateur=self.request.user)

        if obj.statut == UnlockRequest.Statut.APPROVED:
            achat = obj.achat
            achat.nombre_telechargements = 0
            achat.statut = achat.Statut.VALIDE
            achat.appareil_associe = obj.appareil_actuel
            achat.save(update_fields=["nombre_telechargements", "statut", "appareil_associe"])
            notify(obj.etudiant, "Demande approuvée",
                   f"Votre demande de déblocage pour « {achat.document.titre} » a été approuvée.", "UNLOCK")
        elif obj.statut == UnlockRequest.Statut.REJECTED:
            notify(obj.etudiant, "Demande refusée",
                   f"Votre demande de déblocage a été refusée. {obj.reponse_admin}", "UNLOCK")

        log_action(self.request.user, f"UNLOCK_REQUEST_{obj.statut}", "UnlockRequest", obj.id, obj.reponse_admin[:200])
