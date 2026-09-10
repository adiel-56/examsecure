from django.urls import path
from .views import FiliereListView, FiliereDetailView

urlpatterns = [
    path("", FiliereListView.as_view(), name="filieres-list"),
    path("<int:pk>/", FiliereDetailView.as_view(), name="filieres-detail"),
]
