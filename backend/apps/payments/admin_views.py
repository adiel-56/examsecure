from django.db import transaction as db_transaction
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core_utils.permissions import IsAdminRole
from apps.purchases.models import Achat
from apps.notifications.utils import notify
from apps.audit.utils import log_action
from .models import Transaction, PaymentConfig
from .serializers import (
    TransactionSerializer,
    PaymentConfigSerializer,
    PaymentRejectSerializer,
)


class AdminPaymentConfigView(APIView):
    """
    Permet à l'administrateur de consulter et modifier les informations
    Mobile Money (numéro, nom, instructions).
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get(self, request):
        config = PaymentConfig.get_solo()
        return Response(PaymentConfigSerializer(config).data)

    def put(self, request):
        return self._update(request)

    def patch(self, request):
        return self._update(request)

    def _update(self, request):
        config = PaymentConfig.get_solo()
        serializer = PaymentConfigSerializer(config, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        updated_config = serializer.save(updated_by=request.user)
        log_action(
            request.user,
            "PAYMENT_CONFIG_UPDATED",
            "PaymentConfig",
            updated_config.id,
            f"Nouveau numéro MoMo: {updated_config.momo_number} · Bénéficiaire: {updated_config.beneficiary_name}"
        )
        return Response(PaymentConfigSerializer(updated_config).data)


class AdminTransactionListView(generics.ListAPIView):
    """
    Liste toutes les transactions avec filtres par statut et recherche.
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = TransactionSerializer
    search_fields = [
        "reference_kkiapay",
        "reference_recu",
        "numero_telephone",
        "etudiant__email",
        "etudiant__username",
        "etudiant__first_name",
        "etudiant__last_name",
        "document__titre",
        "epreuve__titre",
    ]

    def get_queryset(self):
        qs = Transaction.objects.select_related("etudiant", "document", "administrateur").all()
        statut = self.request.query_params.get("statut")
        if statut:
            if statut.upper() in ("PENDING", "PENDING_VERIFICATION", "SUBMITTED"):
                qs = qs.filter(statut__in=[
                    Transaction.Statut.PENDING_VERIFICATION,
                    Transaction.Statut.PAYMENT_SUBMITTED,
                    Transaction.Statut.PENDING,
                ])
            elif statut.upper() in ("PAID", "SUCCESS", "VALIDATED"):
                qs = qs.filter(statut__in=[Transaction.Statut.PAID, Transaction.Statut.SUCCESS])
            elif statut.upper() in ("REJECTED", "FAILED"):
                qs = qs.filter(statut__in=[Transaction.Statut.REJECTED, Transaction.Statut.FAILED])
            else:
                qs = qs.filter(statut=statut)
        return qs.order_by("-created_at")


class AdminTransactionDetailView(generics.RetrieveAPIView):
    """
    Détail complet d'une demande de paiement pour analyse par l'admin.
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    serializer_class = TransactionSerializer
    queryset = Transaction.objects.select_related("etudiant", "document", "administrateur").all()


class AdminValidatePaymentView(APIView):
    """
    Validation d'un paiement manuel par l'administrateur :
    1. Modifie le statut en PAID
    2. Crée ou active l'Achat (statut=VALIDE)
    3. Enregistre l'admin validateur et la date
    4. Journalise dans l'audit
    5. Notifie l'étudiant
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def post(self, request, pk):
        txn = Transaction.objects.filter(pk=pk).select_related("etudiant", "document").first()
        if not txn:
            return Response({"detail": "Demande de paiement introuvable."}, status=404)

        with db_transaction.atomic():
            txn.statut = Transaction.Statut.PAID
            txn.administrateur = request.user
            txn.date_traitement = timezone.now()
            txn.motif_refus = ""
            txn.save(update_fields=["statut", "administrateur", "date_traitement", "motif_refus", "updated_at"])

            achat, created = Achat.objects.get_or_create(
                transaction=txn,
                defaults={
                    "etudiant": txn.etudiant,
                    "document": txn.document,
                    "statut": Achat.Statut.VALIDE,
                },
            )
            if not created and achat.statut != Achat.Statut.VALIDE:
                achat.statut = Achat.Statut.VALIDE
                achat.save(update_fields=["statut", "updated_at"])

            # Journalisation audit
            log_action(
                request.user,
                "PAYMENT_VALIDATED",
                "Transaction",
                txn.id,
                f"Validation de {txn.montant} {txn.devise} pour « {txn.document.titre} » (Étudiant: {txn.etudiant.email})"
            )

            # Notification étudiant
            notify(
                txn.etudiant,
                "Paiement validé",
                f"Votre paiement pour « {txn.document.titre} » a été validé. Vous pouvez maintenant accéder à ce document.",
                "PURCHASE"
            )

        return Response({
            "detail": "Paiement validé avec succès. L'accès au document a été débloqué.",
            "transaction": TransactionSerializer(txn, context={"request": request}).data,
            "achat_id": achat.id,
        }, status=200)


class AdminRejectPaymentView(APIView):
    """
    Refus d'un paiement manuel par l'administrateur :
    1. Motif obligatoire
    2. Modifie le statut en REJECTED
    3. Enregistre l'admin et la date
    4. Journalise dans l'audit
    5. Notifie l'étudiant avec le motif
    6. Permet à l'étudiant de soumettre un nouveau reçu
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def post(self, request, pk):
        txn = Transaction.objects.filter(pk=pk).select_related("etudiant", "document").first()
        if not txn:
            return Response({"detail": "Demande de paiement introuvable."}, status=404)

        serializer = PaymentRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        motif = serializer.validated_data["motif_refus"]

        with db_transaction.atomic():
            txn.statut = Transaction.Statut.REJECTED
            txn.motif_refus = motif
            txn.administrateur = request.user
            txn.date_traitement = timezone.now()
            txn.save(update_fields=["statut", "motif_refus", "administrateur", "date_traitement", "updated_at"])

            # Si un achat était lié, le révoquer
            Achat.objects.filter(transaction=txn).update(statut=Achat.Statut.REVOQUE)

            # Journalisation audit
            log_action(
                request.user,
                "PAYMENT_REJECTED",
                "Transaction",
                txn.id,
                f"Refus du paiement pour « {txn.document.titre} » - Motif: {motif}"
            )

            # Notification étudiant
            notify(
                txn.etudiant,
                "Paiement refusé",
                f"Votre paiement pour « {txn.document.titre} » a été refusé. Motif : {motif}. Vous pouvez soumettre un nouveau reçu.",
                "PAYMENT"
            )

        return Response({
            "detail": "Paiement refusé.",
            "transaction": TransactionSerializer(txn, context={"request": request}).data,
        }, status=200)
