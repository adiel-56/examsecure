from django.contrib.auth import get_user_model
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core_utils.permissions import IsAdminRole
from apps.exams.models import Document
from apps.payments.models import Transaction
from apps.purchases.models import Achat

User = get_user_model()


class AdminStatisticsView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get(self, request):
        since = timezone.now() - timedelta(days=30)

        # Chiffre d'affaires (Paiements validés)
        valides_qs = Transaction.objects.filter(statut__in=[Transaction.Statut.PAID, Transaction.Statut.SUCCESS])
        chiffre_affaires = valides_qs.aggregate(total=Sum("montant"))["total"] or 0

        # Montant total déclaré (toutes demandes reçues)
        montant_total_declare = Transaction.objects.aggregate(total=Sum("montant"))["total"] or 0

        # Compteurs de paiement
        paiements_en_attente = Transaction.objects.filter(
            statut__in=[
                Transaction.Statut.PENDING_VERIFICATION,
                Transaction.Statut.PAYMENT_SUBMITTED,
                Transaction.Statut.PENDING,
            ]
        ).count()
        paiements_valides = valides_qs.count()
        paiements_refuses = Transaction.objects.filter(
            statut__in=[Transaction.Statut.REJECTED, Transaction.Statut.FAILED]
        ).count()

        documents_plus_vendus = (
            Achat.objects.values("document__id", "document__titre")
            .annotate(total=Count("id"))
            .order_by("-total")[:5]
        )

        filieres_plus_actives = (
            Achat.objects.values("document__filiere__id", "document__filiere__nom")
            .annotate(total=Count("id"))
            .order_by("-total")[:5]
        )

        activite_recente = (
            Transaction.objects.select_related("etudiant", "document")
            .order_by("-created_at")[:10]
        )

        nb_docs = Document.objects.count()
        docs_top = [
            {
                "document__id": d["document__id"],
                "document__titre": d["document__titre"],
                "epreuve__id": d["document__id"],
                "epreuve__titre": d["document__titre"],
                "total": d["total"],
            }
            for d in documents_plus_vendus
        ]
        filieres_top = [
            {
                "document__filiere__id": f["document__filiere__id"],
                "document__filiere__nom": f["document__filiere__nom"],
                "epreuve__filiere__id": f["document__filiere__id"],
                "epreuve__filiere__nom": f["document__filiere__nom"],
                "total": f["total"],
            }
            for f in filieres_plus_actives
        ]

        data = {
            "chiffre_affaires": chiffre_affaires,
            "montant_total_declare": montant_total_declare,
            "nombre_etudiants": User.objects.filter(role=User.Role.STUDENT).count(),
            "nombre_documents": nb_docs,
            "nombre_epreuves": nb_docs,  # Rétro-compatibilité
            "nombre_achats": Achat.objects.filter(statut=Achat.Statut.VALIDE).count(),
            "paiements_en_attente": paiements_en_attente,
            "paiements_valides": paiements_valides,
            "paiements_refuses": paiements_refuses,
            "transactions_reussies": paiements_valides,
            "transactions_echouees": paiements_refuses,
            "documents_plus_vendus": docs_top,
            "epreuves_plus_vendues": docs_top,  # Rétro-compatibilité
            "filieres_plus_actives": filieres_top,
            "activite_recente": [
                {
                    "id": t.id,
                    "etudiant": t.etudiant.get_full_name() or t.etudiant.username,
                    "etudiant_email": t.etudiant.email,
                    "document": t.document.titre,
                    "epreuve": t.document.titre,
                    "montant": str(t.montant),
                    "devise": t.devise,
                    "numero_telephone": t.numero_telephone,
                    "statut": t.statut,
                    "date": t.created_at,
                }
                for t in activite_recente
            ],
            "revenus_30_jours": Transaction.objects.filter(
                statut__in=[Transaction.Statut.PAID, Transaction.Statut.SUCCESS],
                created_at__gte=since
            ).aggregate(total=Sum("montant"))["total"] or 0,
        }
        return Response(data)
