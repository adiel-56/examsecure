from django.urls import path
from .views import UnlockRequestListCreateView, UnlockRequestDetailView

urlpatterns = [
    path("", UnlockRequestListCreateView.as_view(), name="unlock-requests-list"),
    path("<int:pk>/", UnlockRequestDetailView.as_view(), name="unlock-requests-detail"),
]
