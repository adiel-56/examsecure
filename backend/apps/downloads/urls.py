from django.urls import path
from .views import SecureFileDownloadView

urlpatterns = [
    path("file/", SecureFileDownloadView.as_view(), name="downloads-file"),
]
