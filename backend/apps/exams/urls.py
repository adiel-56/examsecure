from django.urls import path
from .views import DocumentListView, DocumentDetailView

urlpatterns = [
    path("", DocumentListView.as_view(), name="documents-list"),
    path("<int:pk>/", DocumentDetailView.as_view(), name="documents-detail"),
]
