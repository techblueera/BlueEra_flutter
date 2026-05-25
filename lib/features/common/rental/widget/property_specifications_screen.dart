import 'package:BlueEra/features/common/rental/widget/complete_your_listing_project_screen.dart';
import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 2 — 12 specification fields. Mixes dropdowns (Type, BHK,
/// Bathrooms, Ready To Move, Listed By, Car Parking, Facing) with
/// numeric text fields (areas, maintenance, floors).
///
/// Routing on "Next" depends on [category]:
///   • [RentalCategory.newProjectsSale] → [CompleteYourListingProjectScreen]
///     (price-range step 3)
///   • everything else → [CompleteYourListingScreen] (single price)
class PropertySpecificationsScreen extends StatelessWidget {
  final RentalCategory category;

  const PropertySpecificationsScreen({
    super.key,
    this.category = RentalCategory.housesSale,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRentalScreenBg,
      appBar: CommonBackAppBar(title: category.specificationsTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: const RentalFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RentalLabeledDropdown(
                label: 'Type',
                hint: 'Lorem',
                items: [
                  'Apartment',
                  'Independent House',
                  'Villa',
                  'Builder Floor'
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
                hint: 'E.g. 2',
                items: ['1', '2', '3', '4', '5+'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Ready To Move',
                hint: 'Yes',
                items: ['Yes', 'No'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Listed By',
                hint: 'Lorem',
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
            onTap: () => Get.to(() => _step3For(category)),
          ),
        ),
      ),
    );
  }

  Widget _step3For(RentalCategory cat) {
    if (cat == RentalCategory.newProjectsSale) {
      return const CompleteYourListingProjectScreen();
    }
    return const CompleteYourListingScreen();
  }
}
