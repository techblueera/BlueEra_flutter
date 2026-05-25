import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 2 — rent variant. 13 fields tuned for rent listings:
/// swaps "Ready To Move" for "Furnishing" and adds "Bachelors
/// Allowed". Tapping "Next" continues to [CompleteYourListingScreen],
/// which is shared between sale + rent flows.
class PropertyRentSpecificationsScreen extends StatelessWidget {
  const PropertyRentSpecificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRentalScreenBg,
      appBar: CommonBackAppBar(title: 'Property Specifications'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: const RentalFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RentalLabeledDropdown(
                label: 'Type',
                hint: 'Duplex',
                items: [
                  'Apartment',
                  'Independent House',
                  'Duplex',
                  'Villa',
                  'Builder Floor',
                  'Studio'
                ],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'BHK',
                hint: 'E.g. 3BHK',
                items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Bathrooms',
                hint: 'E.g. 4+',
                items: ['1', '2', '3', '4', '4+'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Furnishing',
                hint: 'E.g. Semi Furnished',
                items: ['Furnished', 'Semi Furnished', 'Unfurnished'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Listed By',
                hint: 'E.g. Owner',
                items: ['Owner', 'Dealer', 'Builder'],
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Super Builtup Area Sqft',
                hint: 'E.g. 4060',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Carpet Area Sqft',
                hint: 'E.g. 4060',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Bachelors Allowed',
                hint: 'E.g. No',
                items: ['Yes', 'No'],
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Maintenance (Monthly)',
                hint: 'E.g. ₹40,660',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Total Floors',
                hint: 'E.g. 8',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Floor No',
                hint: 'E.g. 8',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Car Parking',
                hint: 'Lorem',
                items: ['None', '1', '2', '3+'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Facing',
                hint: 'Lorem',
                items: [
                  'North',
                  'South',
                  'East',
                  'West',
                  'North-East',
                  'North-West',
                  'South-East',
                  'South-West'
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: RentalPrimaryButton(
            label: 'Next',
            onTap: () => Get.to(() => const CompleteYourListingScreen()),
          ),
        ),
      ),
    );
  }
}
