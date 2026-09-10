"""
Gestionnaire d'exception centralisé : ne jamais exposer d'informations
techniques sensibles (stack trace, requête SQL...) au client mobile.
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        response.data = {
            "success": False,
            "code": response.status_code,
            "message": _public_message(response),
            "details": response.data,
        }
        return response

    # Erreur non gérée par DRF -> 500 générique, sans détails techniques
    return Response(
        {"success": False, "code": 500, "message": "Erreur serveur. Merci de réessayer plus tard."},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


def _public_message(response):
    mapping = {
        400: "Requête invalide.",
        401: "Session expirée, veuillez vous reconnecter.",
        403: "Vous n'avez pas la permission d'effectuer cette action.",
        404: "Ressource introuvable.",
        409: "Conflit détecté sur cette ressource.",
        422: "Données invalides.",
        429: "Trop de requêtes, veuillez patienter.",
    }
    return mapping.get(response.status_code, "Une erreur est survenue.")
