class AuditRequestMiddleware:
    """
    Middleware léger : ne journalise pas chaque requête (trop de bruit),
    mais expose l'IP courante pour que les vues puissent l'utiliser
    explicitement lors d'actions sensibles (paiement, connexion admin...).
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.client_ip = self._get_client_ip(request)
        return self.get_response(request)

    @staticmethod
    def _get_client_ip(request):
        xff = request.META.get("HTTP_X_FORWARDED_FOR")
        if xff:
            return xff.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")
