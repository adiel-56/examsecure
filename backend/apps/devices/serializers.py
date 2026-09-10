from rest_framework import serializers
from .models import Device

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ["id", "device_identifier", "platform", "device_name", "app_version", "is_active", "last_seen", "created_at"]
        read_only_fields = ["id", "last_seen", "created_at"]

class DeviceRegisterSerializer(serializers.ModelSerializer):
    platform = serializers.CharField(required=False, default="ANDROID")

    class Meta:
        model = Device
        fields = ["device_identifier", "platform", "device_name", "app_version"]
        extra_kwargs = {
            "device_identifier": {"validators": []},
        }

    def validate_platform(self, value):
        val = (value or "ANDROID").upper()
        if val in [c[0] for c in Device.Platform.choices]:
            return val
        return Device.Platform.ANDROID
