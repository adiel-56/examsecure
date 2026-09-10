from decimal import Decimal
from rest_framework import serializers
from .models import Transaction, PaymentConfig


class PaymentConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentConfig
        fields = ["id", "momo_number", "beneficiary_name", "instructions", "is_active", "updated_at"]
        read_only_fields = ["id", "updated_at"]


class TransactionSerializer(serializers.ModelSerializer):
    document_titre = serializers.CharField(source="document.titre", read_only=True)
    document_prix = serializers.DecimalField(source="document.prix", max_digits=10, decimal_places=2, read_only=True)
    
    # Rétro-compatibilité
    epreuve_titre = serializers.CharField(source="document.titre", read_only=True)
    epreuve_prix = serializers.DecimalField(source="document.prix", max_digits=10, decimal_places=2, read_only=True)
    epreuve = serializers.PrimaryKeyRelatedField(source="document", read_only=True)

    etudiant_nom = serializers.CharField(source="etudiant.get_full_name", read_only=True)
    etudiant_email = serializers.EmailField(source="etudiant.email", read_only=True)
    etudiant_phone = serializers.CharField(source="etudiant.phone", read_only=True)
    administrateur_nom = serializers.SerializerMethodField()
    recu_fichier_url = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            "id",
            "etudiant",
            "etudiant_nom",
            "etudiant_email",
            "etudiant_phone",
            "document",
            "document_titre",
            "document_prix",
            "epreuve",
            "epreuve_titre",
            "epreuve_prix",
            "montant",
            "devise",
            "moyen_paiement",
            "reference_kkiapay",
            "identifiant_externe",
            "numero_telephone",
            "reference_recu",
            "recu_fichier",
            "recu_fichier_url",
            "commentaire_etudiant",
            "statut",
            "motif_refus",
            "administrateur",
            "administrateur_nom",
            "date_traitement",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "etudiant",
            "statut",
            "motif_refus",
            "administrateur",
            "date_traitement",
            "created_at",
            "updated_at",
        ]

    def get_administrateur_nom(self, obj):
        if obj.administrateur:
            return obj.administrateur.get_full_name() or obj.administrateur.username
        return None

    def get_recu_fichier_url(self, obj):
        if obj.recu_fichier:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.recu_fichier.url)
            return obj.recu_fichier.url
        return None


class ManualPaymentSubmitSerializer(serializers.Serializer):
    document_id = serializers.IntegerField(required=False)
    epreuve_id = serializers.IntegerField(required=False)
    montant = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    numero_telephone = serializers.CharField(max_length=30)
    reference_recu = serializers.CharField(max_length=150, required=False, allow_blank=True)
    commentaire_etudiant = serializers.CharField(required=False, allow_blank=True)
    recu_fichier = serializers.FileField(required=True)

    def validate(self, attrs):
        doc_id = attrs.get("document_id") or attrs.get("epreuve_id")
        if not doc_id:
            raise serializers.ValidationError({"document_id": "L'identifiant du document est requis."})
        attrs["document_id"] = doc_id
        attrs["epreuve_id"] = doc_id
        return attrs

    def validate_recu_fichier(self, value):
        # Vérification taille max (ex: 20 Mo pour le reçu)
        if value.size > 20 * 1024 * 1024:
            raise serializers.ValidationError("La taille du fichier de reçu ne doit pas dépasser 20 Mo.")
        return value


class PaymentInitiateSerializer(serializers.Serializer):
    document_id = serializers.IntegerField(required=False)
    epreuve_id = serializers.IntegerField(required=False)

    def validate(self, attrs):
        doc_id = attrs.get("document_id") or attrs.get("epreuve_id")
        if not doc_id:
            raise serializers.ValidationError({"document_id": "L'identifiant du document est requis."})
        attrs["document_id"] = doc_id
        attrs["epreuve_id"] = doc_id
        return attrs


class PaymentVerifySerializer(serializers.Serializer):
    document_id = serializers.IntegerField(required=False)
    epreuve_id = serializers.IntegerField(required=False)
    reference_kkiapay = serializers.CharField()
    moyen_paiement = serializers.ChoiceField(choices=Transaction.MoyenPaiement.choices, required=False)

    def validate(self, attrs):
        doc_id = attrs.get("document_id") or attrs.get("epreuve_id")
        if not doc_id:
            raise serializers.ValidationError({"document_id": "L'identifiant du document est requis."})
        attrs["document_id"] = doc_id
        attrs["epreuve_id"] = doc_id
        return attrs


class PaymentRejectSerializer(serializers.Serializer):
    motif_refus = serializers.CharField(
        required=True,
        allow_blank=False,
        error_messages={"required": "Le motif de refus est obligatoire.", "blank": "Le motif de refus ne peut pas être vide."}
    )
