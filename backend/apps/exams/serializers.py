import json
from rest_framework import serializers
from apps.matieres.models import Matiere
from .models import Document


class MatiereSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Matiere
        fields = ["id", "nom"]


class DocumentListSerializer(serializers.ModelSerializer):
    matieres = serializers.PrimaryKeyRelatedField(many=True, read_only=True)
    matieres_details = MatiereSimpleSerializer(source="matieres", many=True, read_only=True)
    matieres_noms = serializers.SerializerMethodField()
    matiere_nom = serializers.SerializerMethodField()
    matiere = serializers.SerializerMethodField()
    filiere_nom = serializers.CharField(source="filiere.nom", read_only=True)
    couverture_url = serializers.SerializerMethodField()

    class Meta:
        model = Document
        fields = [
            "id", "titre", "description", "matieres", "matieres_details", "matieres_noms",
            "matiere", "matiere_nom", "filiere", "filiere_nom",
            "annee_academique", "prix", "devise", "nombre_pages", "type_contenu",
            "couverture", "couverture_url", "statut", "date_publication",
        ]

    def get_matieres_noms(self, obj):
        return [m.nom for m in obj.matieres.all()]

    def get_matiere_nom(self, obj):
        noms = [m.nom for m in obj.matieres.all()]
        return ", ".join(noms) if noms else ""

    def get_matiere(self, obj):
        first = obj.matieres.first()
        return first.id if first else None

    def get_couverture_url(self, obj):
        if obj.couverture:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.couverture.url)
            return obj.couverture.url
        return None


class DocumentDetailSerializer(DocumentListSerializer):
    class Meta(DocumentListSerializer.Meta):
        fields = DocumentListSerializer.Meta.fields + ["created_at", "updated_at"]
        # fichier_original / fichier_securise volontairement absents : jamais exposés directement


class DocumentAdminSerializer(serializers.ModelSerializer):
    achats_count = serializers.IntegerField(read_only=True, default=0)
    couverture_url = serializers.SerializerMethodField()
    matieres = serializers.PrimaryKeyRelatedField(
        many=True, queryset=Matiere.objects.all(), required=False
    )
    matieres_details = MatiereSimpleSerializer(source="matieres", many=True, read_only=True)
    matieres_noms = serializers.SerializerMethodField()
    matiere_nom = serializers.SerializerMethodField()
    filiere_nom = serializers.CharField(source="filiere.nom", read_only=True)

    class Meta:
        model = Document
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at", "fichier_securise"]

    def to_internal_value(self, data):
        # Support multipart form data / string encoded list for matieres
        mutable_data = data.copy() if hasattr(data, "copy") else dict(data)
        
        # Handle 'matieres' passed as comma separated or JSON string or single 'matiere'
        if "matieres" in mutable_data:
            val = mutable_data.get("matieres")
            if isinstance(val, str):
                val = val.strip()
                if val.startswith("[") and val.endswith("]"):
                    try:
                        mutable_data.setlist("matieres", json.loads(val)) if hasattr(mutable_data, "setlist") else mutable_data.update({"matieres": json.loads(val)})
                    except Exception:
                        pass
                elif "," in val:
                    parts = [int(p.strip()) for p in val.split(",") if p.strip().isdigit()]
                    mutable_data.setlist("matieres", parts) if hasattr(mutable_data, "setlist") else mutable_data.update({"matieres": parts})
                elif val.isdigit():
                    mutable_data.setlist("matieres", [int(val)]) if hasattr(mutable_data, "setlist") else mutable_data.update({"matieres": [int(val)]})
        elif "matiere" in mutable_data:
            # Rétro-compatibilité si un ancien client envoie un seul ID 'matiere'
            m_val = mutable_data.get("matiere")
            if m_val:
                try:
                    m_id = int(m_val)
                    mutable_data.setlist("matieres", [m_id]) if hasattr(mutable_data, "setlist") else mutable_data.update({"matieres": [m_id]})
                except (ValueError, TypeError):
                    pass

        return super().to_internal_value(mutable_data)

    def get_matieres_noms(self, obj):
        return [m.nom for m in obj.matieres.all()]

    def get_matiere_nom(self, obj):
        noms = [m.nom for m in obj.matieres.all()]
        return ", ".join(noms) if noms else ""

    def get_couverture_url(self, obj):
        if obj.couverture:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.couverture.url)
            return obj.couverture.url
        return None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["achats_count"] = getattr(instance, "achats_count", 0)
        first_m = instance.matieres.first()
        data["matiere"] = first_m.id if first_m else None
        return data


# Alias de rétro-compatibilité
EpreuveListSerializer = DocumentListSerializer
EpreuveDetailSerializer = DocumentDetailSerializer
EpreuveAdminSerializer = DocumentAdminSerializer
