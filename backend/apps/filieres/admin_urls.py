from django.urls import path
from .admin_views import AdminFiliereListCreateView, AdminFiliereDetailView

urlpatterns = [
    path("filieres/", AdminFiliereListCreateView.as_view(), name="admin-filieres"),
    path("filieres/<int:pk>/", AdminFiliereDetailView.as_view(), name="admin-filiere-detail"),
]
