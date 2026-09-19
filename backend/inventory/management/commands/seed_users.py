from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from inventory.models import Centre, UserProfile

import os


class Command(BaseCommand):
    help = "Create IMS users and Centre accounts"

    def required(self, name):
        value = os.environ.get(name, '').strip()
        if not value:
            raise SystemExit(f"{name} environment variable is required (no credentials are hardcoded).")
        return value

    def create_user(self, username, password, role, centre=None):
        user, created = User.objects.get_or_create(
            username=username
        )

        if created:
            user.set_password(password)
            user.save()

            self.stdout.write(
                self.style.SUCCESS(
                    f"Created user: {username}"
                )
            )
        else:
            self.stdout.write(
                f"User already exists: {username}"
            )

        profile, profile_created = UserProfile.objects.get_or_create(
            user=user,
            defaults={
                "role": role,
                "centre": centre,
            }
        )

        if not profile_created:
            profile.role = role
            profile.centre = centre
            profile.save()

        return user

    def handle(self, *args, **options):

        superadmin_pass = self.required("SUPERADMIN_PASS")
        viewer_pass = self.required("ASO_VIEWER_PASS")
        centre_pass = self.required("CENTRE_PASS")

        # ---------------------------------
        # SUPERADMIN
        # ---------------------------------
        self.create_user(
            username="superadmin",
            password=superadmin_pass,
            role="SUPERADMIN",
            centre=None,
        )

        # ---------------------------------
        # ASO VIEWER
        # ---------------------------------
        self.create_user(
            username="aso_viewer",
            password=viewer_pass,
            role="ASO_VIEWER",
            centre=None,
        )

        # ---------------------------------
        # CENTRE USERS
        # ---------------------------------
        centres = Centre.objects.filter(type="C")

        for centre in centres:

            username = centre.name.lower().replace(" ", "_")

            self.create_user(
                username=username,
                password=centre_pass,
                role="CENTRE",
                centre=centre,
            )

        self.stdout.write(
            self.style.SUCCESS(
                "\nAll IMS users created successfully."
            )
        )