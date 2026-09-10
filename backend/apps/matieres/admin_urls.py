from django.urls import path
from .admin_views import AdminMatiereListCreateView, AdminMatiereDetailView

urlpatterns = [
    path("matieres/", AdminMatiereListCreateView.as_view(), name="admin-matieres"),
    path("matieres/<int:pk>/", AdminMatiereDetailView.as_view(), name="admin-matiere-detail"),
]
