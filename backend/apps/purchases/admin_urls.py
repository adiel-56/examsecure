from django.urls import path
from .admin_views import AdminAchatListView

urlpatterns = [
    path("purchases/", AdminAchatListView.as_view(), name="admin-purchases"),
]
