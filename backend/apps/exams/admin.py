from django.contrib import admin
from .models import Document

@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ("titre", "matieres_noms_str", "filiere", "prix", "statut", "date_publication", "created_at")
    list_filter = ("statut", "filiere", "matieres", "type_contenu")
    search_fields = ("titre", "description")
    readonly_fields = ("created_at", "updated_at")
