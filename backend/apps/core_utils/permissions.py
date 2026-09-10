from rest_framework.permissions import BasePermission


class IsAdminRole(BasePermission):
    """
    L'appartenance au rôle ADMIN est TOUJOURS revérifiée côté serveur.
    Le rôle stocké côté Flutter ne sert qu'à l'affichage, jamais à la
    sécurité réelle.
    """

    message = "Accès réservé aux administrateurs."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == "ADMIN"
        )


class IsStudentRole(BasePermission):
    message = "Accès réservé aux étudiants."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == "STUDENT"
        )


class IsOwner(BasePermission):
    """Vérifie que l'objet appartient bien à l'utilisateur authentifié."""

    owner_field = "user"

    def has_object_permission(self, request, view, obj):
        owner = getattr(obj, self.owner_field, None)
        return owner_id_matches(owner, request.user)


def owner_id_matches(owner, user):
    return owner is not None and owner.id == user.id
