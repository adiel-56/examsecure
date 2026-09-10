from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path("admin/", admin.site.urls),

    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),

    path("api/auth/", include("apps.accounts.urls")),
    path("api/filieres/", include("apps.filieres.urls")),
    path("api/matieres/", include("apps.matieres.urls")),
    path("api/documents/", include("apps.exams.urls")),
    path("api/exams/", include("apps.exams.urls")),
    path("api/devices/", include("apps.devices.urls")),
    path("api/payments/", include("apps.payments.urls")),
    path("api/purchases/", include("apps.purchases.urls")),
    path("api/downloads/", include("apps.downloads.urls")),
    path("api/unlock-requests/", include("apps.unlock_requests.urls")),
    path("api/notifications/", include("apps.notifications.urls")),

    path("api/admin/", include("apps.accounts.admin_urls")),
    path("api/admin/", include("apps.filieres.admin_urls")),
    path("api/admin/", include("apps.matieres.admin_urls")),
    path("api/admin/", include("apps.exams.admin_urls")),
    path("api/admin/", include("apps.payments.admin_urls")),
    path("api/admin/", include("apps.purchases.admin_urls")),
    path("api/admin/", include("apps.unlock_requests.admin_urls")),
    path("api/admin/", include("apps.statistics.urls")),
    path("api/admin/", include("apps.audit.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
