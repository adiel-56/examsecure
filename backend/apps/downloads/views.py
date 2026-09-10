from django.http import FileResponse, Http404
from rest_framework.views import APIView
from rest_framework.response import Response

from apps.audit.utils import log_action
from .services import consume_download_token, TokenValidationError


class SecureFileDownloadView(APIView):
    """
    Seul point d'accès réel au fichier PDF privé. Nécessite un
    DownloadToken valide (jamais un accès direct par URL de fichier).
    """

    def post(self, request):
        raw_token = request.data.get("download_token")
        device_id = request.data.get("device_identifier")
        if not raw_token:
            return Response({"detail": "Token manquant."}, status=400)

        try:
            dt = consume_download_token(raw_token, request.user, device_id)
        except TokenValidationError as exc:
            return Response({"detail": str(exc)}, status=403)

        document = dt.achat.document
        fichier = document.fichier_securise or document.fichier_original
        if not fichier:
            raise Http404("Fichier introuvable.")

        log_action(request.user, "FILE_DOWNLOADED", "Document", document.id,
                    f"achat #{dt.achat_id} · token consommé")

        return FileResponse(fichier.open("rb"), as_attachment=True, filename=f"{document.titre}.pdf")
