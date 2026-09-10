from decimal import Decimal
from django.db import transaction as db_transaction
from rest_framework import permissions, status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.exams.models import Document
from apps.purchases.models import Achat
from apps.notifications.utils import notify
from apps.audit.utils import log_action
from .models import Transaction, PaymentConfig
from .serializers import (
    PaymentConfigSerializer,
    ManualPaymentSubmitSerializer,
    TransactionSerializer,
    PaymentInitiateSerializer,
    PaymentVerifySerializer,
)
from .email_service import send_admin_payment_notification
from .kkiapay_client import verify_transaction, KkiaPayVerificationError


class PaymentConfigView(APIView):
    """
    Retourne les coordonnées Mobile Money et les instructions actuelles
    configurées par l'administration.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        config = PaymentConfig.get_solo()
        serializer = PaymentConfigSerializer(config)
        return Response(serializer.data)


class SubmitManualPaymentView(APIView):
    """
    Enregistre un paiement manuel par Mobile Money avec preuve (reçu image ou PDF).
    1. Enregistre la transaction avec statut PENDING_VERIFICATION.
    2. Notifie l'étudiant dans l'application.
    3. Envoie une alerte e-mail à l'administrateur.
    4. Journalise l'audit.
    """
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = ManualPaymentSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        doc_id = data.get("document_id") or data.get("epreuve_id")
        document = Document.objects.filter(id=doc_id, statut=Document.Statut.PUBLIE).first()
        if not document:
            return Response({"detail": "Document introuvable ou non disponible."}, status=404)

        # Vérifier si l'étudiant a déjà un achat validé
        achat_existant = Achat.objects.filter(
            etudiant=request.user, document=document, statut=Achat.Statut.VALIDE
        ).first()
        if achat_existant:
            return Response({"detail": "Vous avez déjà acheté et validé ce document."}, status=400)

        montant = data.get("montant") or document.prix

        with db_transaction.atomic():
            txn = Transaction.objects.create(
                etudiant=request.user,
                document=document,
                montant=montant,
                devise=document.devise,
                moyen_paiement=Transaction.MoyenPaiement.MOBILE_MONEY,
                numero_telephone=data["numero_telephone"],
                reference_recu=data.get("reference_recu", ""),
                recu_fichier=data["recu_fichier"],
                commentaire_etudiant=data.get("commentaire_etudiant", ""),
                statut=Transaction.Statut.PENDING_VERIFICATION,
            )

            # Notifier l'étudiant
            notify(
                request.user,
                "Reçu de paiement envoyé",
                f"Votre reçu pour le document « {document.titre} » a été transmis et est en cours de vérification.",
                "PAYMENT"
            )

            # Journaliser dans l'audit
            log_action(
                request.user,
                "PAYMENT_SUBMITTED",
                "Transaction",
                txn.id,
                f"Montant: {txn.montant} {txn.devise} · Numéro: {txn.numero_telephone} · Réf: {txn.reference_recu}"
            )

        # Envoyer l'alerte e-mail à l'admin
        send_admin_payment_notification(txn)

        return Response(TransactionSerializer(txn, context={"request": request}).data, status=status.HTTP_201_CREATED)


class PaymentStatusView(APIView):
    """
    Permet à l'application mobile de vérifier l'état du paiement pour un document spécifique :
    - UNPAID : aucun paiement
    - PENDING_VERIFICATION : reçu soumis, en cours d'analyse
    - PAID : paiement validé et document débloqué
    - REJECTED : paiement refusé avec motif
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        doc_id = request.query_params.get("document_id") or request.query_params.get("epreuve_id")
        if not doc_id:
            return Response({"detail": "Paramètre document_id (ou epreuve_id) requis."}, status=400)

        # 1. Vérifier si un achat valide existe
        achat = Achat.objects.filter(
            etudiant=request.user, document_id=doc_id, statut=Achat.Statut.VALIDE
        ).first()
        if achat:
            return Response({
                "statut": "PAID",
                "has_access": True,
                "achat_id": achat.id,
                "document_id": int(doc_id),
                "epreuve_id": int(doc_id),
            })

        # 2. Chercher la transaction la plus récente
        latest_txn = Transaction.objects.filter(
            etudiant=request.user, document_id=doc_id
        ).order_by("-created_at").first()

        if not latest_txn:
            return Response({
                "statut": "UNPAID",
                "has_access": False,
                "document_id": int(doc_id),
                "epreuve_id": int(doc_id),
            })

        recu_url = None
        if latest_txn.recu_fichier:
            recu_url = request.build_absolute_uri(latest_txn.recu_fichier.url)

        return Response({
            "statut": latest_txn.statut,
            "has_access": latest_txn.is_validated,
            "transaction_id": latest_txn.id,
            "document_id": int(doc_id),
            "epreuve_id": int(doc_id),
            "montant": str(latest_txn.montant),
            "devise": latest_txn.devise,
            "numero_telephone": latest_txn.numero_telephone,
            "reference_recu": latest_txn.reference_recu,
            "motif_refus": latest_txn.motif_refus,
            "recu_fichier_url": recu_url,
            "created_at": latest_txn.created_at,
            "date_traitement": latest_txn.date_traitement,
        })


class MyTransactionsView(APIView):
    """
    Liste toutes les transactions de l'étudiant connecté avec détails et reçus.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Transaction.objects.filter(etudiant=request.user).select_related("document", "administrateur").order_by("-created_at")
        return Response(TransactionSerializer(qs, many=True, context={"request": request}).data)


# Vues KkiaPay conservées pour rétro-compatibilité
class PaymentInitiateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentInitiateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        doc_id = serializer.validated_data.get("document_id") or serializer.validated_data.get("epreuve_id")
        document = Document.objects.filter(id=doc_id, statut=Document.Statut.PUBLIE).first()
        if not document:
            return Response({"detail": "Document introuvable ou non publié."}, status=404)

        from django.conf import settings
        return Response({
            "public_key": getattr(settings, "KKIAPAY_PUBLIC_KEY", ""),
            "sandbox": getattr(settings, "KKIAPAY_SANDBOX", True),
            "amount": str(document.prix),
            "currency": document.devise,
            "document_id": document.id,
            "epreuve_id": document.id,
        })


class PaymentVerifyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        doc_id = data.get("document_id") or data.get("epreuve_id")
        document = Document.objects.filter(id=doc_id, statut=Document.Statut.PUBLIE).first()
        if not document:
            return Response({"detail": "Document introuvable ou non publié."}, status=404)

        existing = Transaction.objects.filter(reference_kkiapay=data["reference_kkiapay"]).first()
        if existing and existing.statut in (Transaction.Statut.PAID, Transaction.Statut.SUCCESS):
            achat = Achat.objects.filter(transaction=existing).first()
            return Response(
                {"detail": "Transaction déjà traitée.", "transaction": TransactionSerializer(existing, context={"request": request}).data,
                 "achat_id": achat.id if achat else None},
                status=200,
            )

        try:
            kkiapay_result = verify_transaction(data["reference_kkiapay"])
        except KkiaPayVerificationError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)

        provider_status = str(kkiapay_result.get("status", "")).upper()
        provider_amount = Decimal(str(kkiapay_result.get("amount", "0")))

        with db_transaction.atomic():
            txn, _ = Transaction.objects.get_or_create(
                reference_kkiapay=data["reference_kkiapay"],
                defaults={
                    "etudiant": request.user,
                    "document": document,
                    "montant": document.prix,
                    "devise": document.devise,
                    "moyen_paiement": data.get("moyen_paiement", Transaction.MoyenPaiement.MOBILE_MONEY),
                    "identifiant_externe": str(kkiapay_result.get("transactionId", "")),
                },
            )

            amount_matches = provider_amount == document.prix
            success = provider_status == "SUCCESS" and amount_matches

            txn.statut = Transaction.Statut.PAID if success else Transaction.Statut.REJECTED
            txn.save(update_fields=["statut", "updated_at"])

            if not success:
                log_action(request.user, "PAYMENT_FAILED", "Transaction", txn.id,
                            f"statut={provider_status} montant_attendu={document.prix} montant_recu={provider_amount}")
                return Response({"detail": "Paiement non confirmé par KkiaPay.",
                                  "transaction": TransactionSerializer(txn, context={"request": request}).data}, status=402)

            achat, created = Achat.objects.get_or_create(
                transaction=txn,
                defaults={"etudiant": request.user, "document": document, "statut": Achat.Statut.VALIDE},
            )

            log_action(request.user, "PAYMENT_VERIFIED", "Transaction", txn.id,
                        f"{txn.reference_kkiapay} · {txn.montant} {txn.devise}")
            if created:
                notify(request.user, "Paiement confirmé", f"Votre achat de « {document.titre} » est disponible.", "PURCHASE")

        from apps.purchases.serializers import AchatSerializer
        return Response(
            {"transaction": TransactionSerializer(txn, context={"request": request}).data, "achat": AchatSerializer(achat).data},
            status=201,
        )
