import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from django.apps import apps
from django.contrib.auth import get_user_model

User = get_user_model()

print("=== DEBUT DU NETTOYAGE ===")
print("Conservation des comptes Admin...")
admins = User.objects.filter(is_superuser=True)
print(f"Admins conservés: {admins.count()}")

print("Suppression des utilisateurs normaux...")
count, _ = User.objects.filter(is_superuser=False).delete()
print(f"Utilisateurs supprimés: {count}")

# Liste des applications à vider (dans l'ordre pour éviter les soucis de contraintes)
apps_to_clear = [
    'audit',
    'notifications',
    'unlock_requests',
    'downloads',
    'purchases',
    'payments',
    'devices',
    'exams',
    'matieres',
    'filieres',
]

for app_name in apps_to_clear:
    try:
        app_config = apps.get_app_config(app_name)
        for model in app_config.get_models():
            count, _ = model.objects.all().delete()
            print(f"Suppression de {count} entrées dans {model.__name__} (app: {app_name})")
    except Exception as e:
        print(f"Erreur sur {app_name}: {e}")

print("=== NETTOYAGE TERMINE ===")
