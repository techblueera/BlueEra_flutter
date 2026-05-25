import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 2 — shops & offices variant. Seven fields tuned for
/// commercial listings: Furnishing, Listed By, Super Builtup, Carpet
/// Area, Maintenance, Car Parking, Washrooms. Both rent and sale
/// variants share the same fields and both land on
/// [CompleteYourListingScreen] (single-price step 3) per the
/// designs.
class ShopsOfficesSpecificationsScreen extends StatelessWidget {
  final RentalCategory category;

  const ShopsOfficesSpecificationsScreen({
    super.key,
    this.category = RentalCategory.shopsOfficesRent,
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
                label: 'Furnishing',
                hint: 'Semi Furnished',
                items: ['Furnished', 'Semi Furnished', 'Unfurnished'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Listed By',
                hint: 'E.g. Owner',
                items: ['Owner', 'Dealer', 'Broker'],
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
              RentalLabeledDropdown(
                label: 'Car Parking',
                hint: 'Lorem',
                items: ['None', '1', '2', '3+'],
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Washrooms',
                hint: 'E.g. 2',
                keyboardType: TextInputType.number,
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
