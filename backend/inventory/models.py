from django.contrib.auth.models import User
from django.db import models


class Centre(models.Model):
    TYPE_CHOICES = [
        ("C", "Centre"),
        ("SC", "Sub Centre"),
        ("SP", "Satsang Point"),
    ]

    name = models.CharField(max_length=200)

    type = models.CharField(
        max_length=2,
        choices=TYPE_CHOICES
    )

    parent = models.ForeignKey(
        "self",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="children"
    )

    def __str__(self):
        return f"{self.name} ({self.type})"


class UserProfile(models.Model):
    ROLE_CHOICES = [
        ("SUPERADMIN", "Superadmin"),
        ("ASO_VIEWER", "ASO Viewer"),
        ("CENTRE", "Centre"),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="profile"
    )

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES
    )

    centre = models.ForeignKey(
        Centre,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="users"
    )

    def __str__(self):
        return f"{self.user.username} - {self.role}"


class StockItem(models.Model):
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=100, unique=True)
    quantity = models.IntegerField(default=0)
    unit = models.CharField(max_length=50, default='pcs')
    centre = models.ForeignKey(Centre, on_delete=models.CASCADE, null=True, blank=True)


class Item(models.Model):
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=100, blank=True)


class SCIForm(models.Model):
    title = models.CharField(max_length=200)
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)


class Destination(models.Model):
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=100, unique=True)


class GRN(models.Model):
    item = models.CharField(max_length=200)
    quantity = models.IntegerField()
    supplier = models.CharField(max_length=200)
    date = models.DateField()
    status = models.CharField(max_length=20, default='received')


class Transfer(models.Model):
    from_centre = models.ForeignKey(Centre, on_delete=models.CASCADE, related_name='outgoing_transfers')
    to_centre = models.ForeignKey(Centre, on_delete=models.CASCADE, related_name='incoming_transfers')
    item = models.CharField(max_length=200)
    quantity = models.IntegerField()
    date = models.DateField()


class Document(models.Model):
    name = models.CharField(max_length=200)
    file = models.FileField(upload_to='documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)


class Log(models.Model):
    message = models.TextField()
    level = models.CharField(max_length=20, default='info')
    created_at = models.DateTimeField(auto_now_add=True)