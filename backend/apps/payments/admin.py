from django.contrib import admin
from .models import Transaction, PaymentConfig


@admin.register(PaymentConfig)
class PaymentConfigAdmin(admin.ModelAdmin):
    list_display = ("momo_number", "beneficiary_name", "is_active", "updated_at")


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "etudiant",
        "document",
        "montant",
        "devise",
        "numero_telephone",
        "reference_recu",
        "statut",
        "created_at",
    )
    list_filter = ("statut", "moyen_paiement", "created_at")
    search_fields = (
        "etudiant__email",
        "etudiant__username",
        "document__titre",
        "epreuve__titre",
        "numero_telephone",
        "reference_recu",
        "reference_kkiapay",
    )
    readonly_fields = ("created_at", "updated_at")
