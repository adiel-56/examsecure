from django.contrib.auth.models import AbstractUser
from django.db import models


class UserManager(models.Manager):
    pass


class User(AbstractUser):
    """
    Utilisateur unique de l'application (STUDENT ou ADMIN).
    Le rôle est TOUJOURS revérifié côté API (voir core_utils.permissions).
    """

    class Role(models.TextChoices):
        STUDENT = "STUDENT", "Étudiant"
        ADMIN = "ADMIN", "Administrateur"

    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=30, blank=True)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.STUDENT)
    filiere = models.ForeignKey(
        "filieres.Filiere", null=True, blank=True, on_delete=models.SET_NULL, related_name="etudiants"
    )
    is_suspended = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.role})"
