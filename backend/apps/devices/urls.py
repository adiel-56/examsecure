from django.urls import path
from .views import DeviceListView, DeviceRegisterView, DeviceDeleteView

urlpatterns = [
    path("", DeviceListView.as_view(), name="devices-list"),
    path("register/", DeviceRegisterView.as_view(), name="devices-register"),
    path("<int:pk>/", DeviceDeleteView.as_view(), name="devices-delete"),
]
