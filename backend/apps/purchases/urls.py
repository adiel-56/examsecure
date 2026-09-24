from django.urls import path
from .views import MyPurchasesListView, MyPurchaseDetailView, RequestDownloadView, RequestUnlockView

urlpatterns = [
    path("", MyPurchasesListView.as_view(), name="purchases-list"),
    path("<int:pk>/", MyPurchaseDetailView.as_view(), name="purchases-detail"),
    path("<int:pk>/download/", RequestDownloadView.as_view(), name="purchases-download"),
    path("<int:pk>/unlock-request/", RequestUnlockView.as_view(), name="purchases-unlock-request"),
]
