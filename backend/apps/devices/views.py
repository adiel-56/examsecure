from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Device
from .serializers import DeviceSerializer, DeviceRegisterSerializer
from apps.audit.utils import log_action

class DeviceListView(generics.ListAPIView):
    serializer_class = DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user)

class DeviceRegisterView(APIView):
    """
    Enregistre ou met à jour l'appareil courant de l'utilisateur connecté.
    Idempotent sur device_identifier.
    """

    def post(self, request):
        serializer = DeviceRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        device, created = Device.objects.update_or_create(
            device_identifier=serializer.validated_data["device_identifier"],
            defaults={**serializer.validated_data, "user": request.user, "is_active": True},
        )
        if created:
            log_action(request.user, "DEVICE_REGISTERED", "Device", device.id, device.device_name)
        return Response(DeviceSerializer(device).data, status=201 if created else 200)

class DeviceDeleteView(generics.DestroyAPIView):
    serializer_class = DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user)

    def perform_destroy(self, instance):
        log_action(self.request.user, "DEVICE_REMOVED", "Device", instance.id, instance.device_name)
        instance.delete()
