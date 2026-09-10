from django.urls import path
from .admin_views import AdminDocumentListCreateView, AdminDocumentDetailView

urlpatterns = [
    path("documents/", AdminDocumentListCreateView.as_view(), name="admin-documents"),
    path("documents/<int:pk>/", AdminDocumentDetailView.as_view(), name="admin-document-detail"),
    # Rétro-compatibilité
    path("exams/", AdminDocumentListCreateView.as_view(), name="admin-exams"),
    path("exams/<int:pk>/", AdminDocumentDetailView.as_view(), name="admin-exam-detail"),
]
