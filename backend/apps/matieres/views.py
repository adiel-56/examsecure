from rest_framework import generics, permissions
from .models import Matiere
from .serializers import MatiereSerializer

class MatiereListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MatiereSerializer
    queryset = Matiere.objects.all()
    filterset_fields = ["filiere"]
    search_fields = ["nom"]

class MatiereDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MatiereSerializer
    queryset = Matiere.objects.all()
