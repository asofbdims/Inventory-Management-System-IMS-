from rest_framework import viewsets, status, permissions, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.hashers import make_password
from django.shortcuts import get_object_or_404
from .models import Centre, UserProfile, StockItem, Item, SCIForm, Destination, GRN, Transfer, Document, Log
from .serializers import CentreSerializer, UserProfileSerializer


class AuthViewSet(viewsets.ViewSet):
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['post'])
    def login(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user:
            login(request, user)
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'token': token.key,
                'user': UserProfileSerializer(user.profile).data,
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def credentials(self, request):
        user = request.user
        password = request.data.get('password')
        if password:
            user.password = make_password(password)
            user.save()
            return Response({'status': 'password_updated'})
        return Response({'error': 'password required'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def reset_password(self, request):
        username = request.data.get('username')
        user = get_object_or_404(User, username=username)
        new_password = request.data.get('new_password')
        if new_password:
            user.password = make_password(new_password)
            user.save()
            return Response({'status': 'password_reset'})
        return Response({'error': 'new_password required'}, status=status.HTTP_400_BAD_REQUEST)


class CentreViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def tree(self, request):
        centres = Centre.objects.filter(parent__isnull=True)
        serializer = CentreSerializer(centres, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def flat(self, request):
        centres = Centre.objects.all()
        serializer = CentreSerializer(centres, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        serializer = CentreSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['put'])
    def update(self, request, pk=None):
        centre = get_object_or_404(Centre, pk=pk)
        serializer = CentreSerializer(centre, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['delete'])
    def destroy(self, request, pk=None):
        centre = get_object_or_404(Centre, pk=pk)
        centre.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class StockRegisterViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import StockSerializer
        items = StockItem.objects.all()
        serializer = StockSerializer(items, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import StockSerializer
        serializer = StockSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['put'])
    def update(self, request, pk=None):
        from .models import StockItem
        from .serializers import StockSerializer
        item = get_object_or_404(StockItem, pk=pk)
        serializer = StockSerializer(item, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['delete'])
    def destroy(self, request, pk=None):
        from .models import StockItem
        item = get_object_or_404(StockItem, pk=pk)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'])
    def import_data(self, request):
        import csv
        import io
        file = request.FILES.get('file')
        if file:
            data = file.read().decode('utf-8')
            reader = csv.DictReader(io.StringIO(data))
            created = 0
            for row in reader:
                StockItem.objects.get_or_create(
                    code=row['code'],
                    defaults={
                        'name': row['name'],
                        'quantity': row['quantity'],
                        'unit': row.get('unit', 'pcs'),
                    }
                )
                created += 1
            return Response({'created': created})
        return Response({'error': 'no file'}, status=status.HTTP_400_BAD_REQUEST)


class ItemMasterViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import ItemSerializer
        items = Item.objects.all()
        serializer = ItemSerializer(items, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import ItemSerializer
        serializer = ItemSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['put'])
    def update(self, request, pk=None):
        from .models import Item
        from .serializers import ItemSerializer
        item = get_object_or_404(Item, pk=pk)
        serializer = ItemSerializer(item, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['delete'])
    def destroy(self, request, pk=None):
        from .models import Item
        item = get_object_or_404(Item, pk=pk)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class SCIFormViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['post'])
    def submit(self, request):
        from .serializers import SCIFormSerializer
        serializer = SCIFormSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import SCIFormSerializer
        from .models import SCIForm
        forms = SCIForm.objects.all()
        serializer = SCIFormSerializer(forms, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def export(self, request):
        import csv
        import io
        from .models import SCIForm
        forms = SCIForm.objects.all()
        writer = csv.writer(io.StringIO())
        writer.writerow(['ID', 'Title', 'Status', 'Created At'])
        for form in forms:
            writer.writerow([form.id, form.title, form.status, form.created_at])
        csv_data = io.StringIO.getvalue()
        return Response({'csv': csv_data})

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        from .models import SCIForm
        form = get_object_or_404(SCIForm, pk=pk)
        form.status = 'approved'
        form.save()
        return Response({'status': 'approved'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        from .models import SCIForm
        form = get_object_or_404(SCIForm, pk=pk)
        form.status = 'rejected'
        form.save()
        return Response({'status': 'rejected'})


class DestinationViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import DestinationSerializer
        from .models import Destination
        destinations = Destination.objects.all()
        serializer = DestinationSerializer(destinations, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import DestinationSerializer
        serializer = DestinationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GRNRegisterViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import GRNSerializer
        from .models import GRN
        grns = GRN.objects.all()
        serializer = GRNSerializer(grns, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import GRNSerializer
        serializer = GRNSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TransferViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import TransferSerializer
        from .models import Transfer
        transfers = Transfer.objects.all()
        serializer = TransferSerializer(transfers, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import TransferSerializer
        serializer = TransferSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DocumentMasterViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import DocumentSerializer
        from .models import Document
        documents = Document.objects.all()
        serializer = DocumentSerializer(documents, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create(self, request):
        from .serializers import DocumentSerializer
        serializer = DocumentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def list(self, request):
        from .serializers import LogSerializer
        from .models import Log
        logs = Log.objects.all()[:100]
        serializer = LogSerializer(logs, many=True)
        return Response(serializer.data)