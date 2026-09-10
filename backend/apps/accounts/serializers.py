from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserPublicSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "first_name", "last_name", "email", "phone", "role", "filiere", "created_at"]
        read_only_fields = fields


class UserAdminListSerializer(serializers.ModelSerializer):
    """
    Utilisée uniquement par le dashboard admin (section 8 : liste des
    étudiants) — ajoute filiere_nom et achats_count pour l'affichage,
    sans exposer ces champs calculés côté étudiant.
    """

    filiere_nom = serializers.CharField(source="filiere.nom", default="", read_only=True)
    achats_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = User
        fields = [
            "id", "first_name", "last_name", "email", "phone", "filiere", "filiere_nom",
            "achats_count", "is_suspended", "is_active", "created_at",
        ]
        read_only_fields = fields


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = ["id", "first_name", "last_name", "email", "phone", "password", "filiere"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        validated_data["username"] = validated_data["email"]
        validated_data["role"] = User.Role.STUDENT  # un étudiant ne peut jamais s'auto-promouvoir admin
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class ExamSecureTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Ajoute le rôle et le profil dans la réponse de connexion, comme
    spécifié dans le contrat API (section 9 du cahier des charges).
    """

    username_field = User.USERNAME_FIELD

    def validate(self, attrs):
        data = super().validate(attrs)
        if self.user.is_suspended:
            raise serializers.ValidationError("Ce compte a été suspendu. Contactez l'administration.")
        data["user"] = UserPublicSerializer(self.user).data
        return data


class ProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["first_name", "last_name", "phone", "filiere"]


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()

