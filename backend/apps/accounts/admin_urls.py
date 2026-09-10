from django.urls import path
from .admin_views import AdminUserListView, AdminUserDetailView, AdminUserToggleActiveView

urlpatterns = [
    path("users/", AdminUserListView.as_view(), name="admin-users"),
    path("users/<int:pk>/", AdminUserDetailView.as_view(), name="admin-user-detail"),
    path("users/<int:pk>/toggle-active/", AdminUserToggleActiveView.as_view(), name="admin-user-toggle"),
]
