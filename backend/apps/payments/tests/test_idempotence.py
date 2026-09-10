from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.filieres.models import Filiere
from apps.matieres.models import Matiere
from apps.exams.models import Document
from apps.payments.models import Transaction

User = get_user_model()


class PaymentIdempotenceTestCase(TestCase):
    def test_meme_reference_ne_cree_pas_deux_transactions_success(self):
        filiere = Filiere.objects.create(nom="Informatique")
        matiere = Matiere.objects.create(nom="Algorithmique", filiere=filiere)
        student = User.objects.create_user(username="a@a.com", email="a@a.com", password="Test1234!")

        document = Document.objects.create(
            titre="Examen 2025",
            matiere=matiere,
            filiere=filiere,
            annee_academique="2025",
            prix=1500,
            fichier_original="dummy.pdf",
            statut=Document.Statut.PUBLIE,
        )

        txn, created1 = Transaction.objects.get_or_create(
            reference_kkiapay="REF-123",
            defaults={"etudiant": student, "document": document, "montant": 1500, "statut": Transaction.Statut.SUCCESS},
        )
        txn2, created2 = Transaction.objects.get_or_create(
            reference_kkiapay="REF-123",
            defaults={"etudiant": student, "document": document, "montant": 1500, "statut": Transaction.Statut.SUCCESS},
        )

        self.assertTrue(created1)
        self.assertFalse(created2)
        self.assertEqual(txn.id, txn2.id)
        self.assertEqual(Transaction.objects.filter(reference_kkiapay="REF-123").count(), 1)
