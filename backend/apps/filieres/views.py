from rest_framework import generics, permissions
from .models import Filiere
from .serializers import FiliereSerializer

class FiliereListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FiliereSerializer
    queryset = Filiere.objects.all()
    search_fields = ["nom"]

class FiliereDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FiliereSerializer
    queryset = Filiere.objects.all()
