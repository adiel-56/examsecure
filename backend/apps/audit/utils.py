def log_action(user, action, objet_type="", objet_id=None, informations="", ip=None):
    """
    Enregistre une action sensible. Import différé pour éviter les imports
    circulaires entre apps au démarrage de Django.
    """
    from .models import AuditLog

    AuditLog.objects.create(
        utilisateur=user if user and getattr(user, "is_authenticated", False) else None,
        action=action,
        objet_type=objet_type,
        objet_id=str(objet_id) if objet_id is not None else None,
        informations=informations[:2000],
        ip=ip,
    )
