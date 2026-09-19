from rest_framework import serializers
from .models import Centre, UserProfile


class CentreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Centre
        fields = "__all__"


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = "__all__"