from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Notification
from .serializers import NotificationSerializer

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(utilisateur=self.request.user)

class NotificationMarkReadView(APIView):
    def patch(self, request, pk):
        notif = Notification.objects.filter(pk=pk, utilisateur=request.user).first()
        if not notif:
            return Response({"detail": "Notification introuvable."}, status=404)
        notif.lu = True
        notif.save(update_fields=["lu"])
        return Response(NotificationSerializer(notif).data)
