from django.urls import path
from .admin_views import (
    AdminTransactionListView,
    AdminTransactionDetailView,
    AdminValidatePaymentView,
    AdminRejectPaymentView,
    AdminPaymentConfigView,
)

urlpatterns = [
    path("transactions/", AdminTransactionListView.as_view(), name="admin-transactions"),
    path("transactions/<int:pk>/", AdminTransactionDetailView.as_view(), name="admin-transaction-detail"),
    path("transactions/<int:pk>/validate/", AdminValidatePaymentView.as_view(), name="admin-transaction-validate"),
    path("transactions/<int:pk>/reject/", AdminRejectPaymentView.as_view(), name="admin-transaction-reject"),
    path("payments/config/", AdminPaymentConfigView.as_view(), name="admin-payment-config"),
]
