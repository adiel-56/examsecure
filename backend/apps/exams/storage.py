from django.conf import settings
from django.core.files.storage import FileSystemStorage

# Stockage strictement privé : jamais servi par une URL statique publique.
# L'accès passe toujours par une vue Django contrôlée (voir apps.downloads).
private_storage = FileSystemStorage(location=str(settings.PRIVATE_MEDIA_ROOT))
