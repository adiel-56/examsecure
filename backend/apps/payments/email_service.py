import logging
from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


def send_admin_payment_notification(transaction):
    """
    Envoie un e-mail à l'administrateur lorsqu'un étudiant soumet un reçu de paiement.
    Si l'envoi échoue (pas de serveur SMTP configuré, erreur réseau), l'exception est
    capturée et journalisée : la transaction reste 100% enregistrée en base.
    """
    try:
        etudiant = transaction.etudiant
        document = transaction.document
        admin_email = getattr(settings, "ADMIN_NOTIFICATION_EMAIL", "lawalradji6@gmail.com")
        dashboard_url = getattr(settings, "DASHBOARD_URL", "http://127.0.0.1:8000/admin/")

        subject = f"[ExamSecure] Nouveau reçu de paiement — {document.titre} ({etudiant.get_full_name() or etudiant.email})"
        
        message = f"""Bonjour Administrateur,

Un étudiant vient de soumettre un reçu de paiement Mobile Money pour le document suivant :

--------------------------------------------------
DÉTAILS DU PAIEMENT SOUMIS :
--------------------------------------------------
• Étudiant : {etudiant.get_full_name() or etudiant.username}
• E-mail : {etudiant.email}
• Document demandé : {document.titre}
• Montant déclaré : {transaction.montant} {transaction.devise} (Prix officiel : {document.prix} {document.devise})
• Numéro Mobile Money utilisé : {transaction.numero_telephone or 'Non renseigné'}
• Référence de transaction : {transaction.reference_recu or 'Non renseignée'}
• Commentaire : {transaction.commentaire_etudiant or 'Aucun'}
• Date de soumission : {transaction.created_at.strftime('%d/%m/%Y à %H:%M')}
--------------------------------------------------

Veuillez vérifier et valider ou refuser cette demande depuis le tableau de bord administrateur :
{dashboard_url}

Cordialement,
Le système automatisé ExamSecure
"""

        send_mail(
            subject=subject,
            message=message,
            from_email=getattr(settings, "DEFAULT_FROM_EMAIL", "noreply@examsecure.com"),
            recipient_list=[admin_email],
            fail_silently=False,
        )
        logger.info(f"Notification e-mail de paiement #{transaction.id} envoyée avec succès à {admin_email}")
        return True
    except Exception as exc:
        logger.warning(
            f"Échec de l'envoi de l'e-mail de notification pour la transaction #{transaction.id} : {exc}"
        )
        return False
