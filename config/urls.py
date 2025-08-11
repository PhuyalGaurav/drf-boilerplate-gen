from django.contrib import admin
from django.urls import path, re_path, include
from django.http import JsonResponse
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi


schema_view = get_schema_view(
    openapi.Info(
        title="Swagger API",
        default_version="v1",
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)


def health(_):
    return JsonResponse(
        {
            "ok": True,
        }
    )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("auth/", include("djoser.urls")),
    path("auth/", include("djoser.urls.jwt")),
    path("health/", health),
    path(
        "swagger/",
        schema_view.with_ui("swagger", cache_timeout=0),
        name="schema-swagger-ui",
    ),
]
