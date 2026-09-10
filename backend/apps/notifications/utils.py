def notify(user, titre, message, type_="INFO"):
    from .models import Notification
    return Notification.objects.create(utilisateur=user, titre=titre, message=message, type=type_)
