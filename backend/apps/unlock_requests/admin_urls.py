from django.urls import path
from .admin_views import AdminUnlockRequestListView, AdminUnlockRequestUpdateView

urlpatterns = [
    path("unlock-requests/", AdminUnlockRequestListView.as_view(), name="admin-unlock-requests"),
    path("unlock-requests/<int:pk>/", AdminUnlockRequestUpdateView.as_view(), name="admin-unlock-request-detail"),
]
