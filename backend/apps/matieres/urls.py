from django.urls import path
from .views import MatiereListView, MatiereDetailView

urlpatterns = [
    path("", MatiereListView.as_view(), name="matieres-list"),
    path("<int:pk>/", MatiereDetailView.as_view(), name="matieres-detail"),
]
