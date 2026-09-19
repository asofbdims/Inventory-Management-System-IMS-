from django.core.management.base import BaseCommand
from inventory.models import Centre


class Command(BaseCommand):
    help = "Create the IMS Centre / Sub Centre / Satsang Point hierarchy"

    def handle(self, *args, **options):

        # -------------------------
        # Centres
        # -------------------------
        centres = [
            "ANKHEER",
            "BALLABGARH",
            "DLF CITY GURGAON",
            "TAORU",
            "FIROZPUR JHIRKA",
            "GURGAON",
            "MOHANA",
            "ZAIBABAD KHERLI",
            "NANGLA GUJRAN",
            "N.I.T. NO. 2",
            "BAROLI",
            "HODAL",
            "PALWAL",
        ]

        centre_objects = {}

        for name in centres:
            centre, created = Centre.objects.get_or_create(
                name=name,
                type="C",
                parent=None,
            )

            centre_objects[name] = centre

            if created:
                self.stdout.write(
                    self.style.SUCCESS(f"Created C: {name}")
                )
            else:
                self.stdout.write(f"Already exists: C: {name}")

        # -------------------------
        # Sub Centres
        # -------------------------
        sub_centres = {
            "DLF CITY GURGAON": [
                "PUNAHANA",
                "SOHNA",
            ],
            "GURGAON": [
                "PATAUDI",
                "FARUKH NAGAR",
            ],
            "PALWAL": [
                "SIHA",
            ],
        }

        for parent_name, children in sub_centres.items():

            parent = centre_objects[parent_name]

            for name in children:
                obj, created = Centre.objects.get_or_create(
                    name=name,
                    type="SC",
                    parent=parent,
                )

                if created:
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"Created SC: {name} → {parent_name}"
                        )
                    )
                else:
                    self.stdout.write(
                        f"Already exists: SC: {name}"
                    )

        # -------------------------
        # Satsang Points
        # -------------------------
        satsang_points = {
            "BALLABGARH": [
                "MACHHGAR",
            ],

            "DLF CITY GURGAON": [
                "ABHEYPUR",
                "NUH",
            ],

            "GURGAON": [
                "BADHA SIKENDERPUR",
                "BILASPUR (FARIDABAD)",
                "BUDHERA",
                "DUNDAHERA",
                "JATAULA",
                "KASAN",
            ],

            "MOHANA": [
                "FATEHPUR BILLOCH",
            ],

            "PALWAL": [
                "BAHIN",
                "HASANPUR (FARIDABAD)",
                "HATHIN",
                "MANDKOLA",
                "NAYAGAON",
            ],
        }

        for parent_name, points in satsang_points.items():

            parent = centre_objects[parent_name]

            for name in points:
                obj, created = Centre.objects.get_or_create(
                    name=name,
                    type="SP",
                    parent=parent,
                )

                if created:
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"Created SP: {name} → {parent_name}"
                        )
                    )
                else:
                    self.stdout.write(
                        f"Already exists: SP: {name}"
                    )

        self.stdout.write(
            self.style.SUCCESS(
                "\nCentre hierarchy seeded successfully."
            )
        )