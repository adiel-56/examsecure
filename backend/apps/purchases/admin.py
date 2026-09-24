from django.contrib import admin
from .models import Achat, UnlockRequest

admin.site.register(Achat)

@admin.register(UnlockRequest)
class UnlockRequestAdmin(admin.ModelAdmin):
    list_display = ["achat", "statut", "created_at"]
    list_filter = ["statut"]
    actions = ["approuver_demandes"]

    @admin.action(description="Approuver les demandes sélectionnées")
    def approuver_demandes(self, request, queryset):
        for demande in queryset:
            if demande.statut != UnlockRequest.Statut.ACCEPTEE:
                demande.statut = UnlockRequest.Statut.ACCEPTEE
                demande.save()
                
                # Réinitialiser la limite et valider l'achat
                achat = demande.achat
                achat.nombre_telechargements = 0
                achat.statut = Achat.Statut.VALIDE
                achat.save()
                
        self.message_user(request, f"{queryset.count()} demande(s) approuvée(s) avec succès.")
