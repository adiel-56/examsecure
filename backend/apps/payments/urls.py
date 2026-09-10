from django.urls import path
from .views import (
    PaymentConfigView,
    SubmitManualPaymentView,
    PaymentStatusView,
    MyTransactionsView,
    PaymentInitiateView,
    PaymentVerifyView,
)

urlpatterns = [
    path("config/", PaymentConfigView.as_view(), name="payments-config"),
    path("submit-receipt/", SubmitManualPaymentView.as_view(), name="payments-submit-receipt"),
    path("status/", PaymentStatusView.as_view(), name="payments-status"),
    path("history/", MyTransactionsView.as_view(), name="payments-history"),
    path("initiate/", PaymentInitiateView.as_view(), name="payments-initiate"),
    path("verify/", PaymentVerifyView.as_view(), name="payments-verify"),
]
