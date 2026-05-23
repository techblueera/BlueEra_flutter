import 'package:BlueEra/features/common/rental/widget/land_plots_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/property_rent_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/property_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/features/common/rental/widget/shops_offices_specifications_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 1 of the "List Your Property" flow. Category-aware: the
/// header card swaps illustration + subtitle to match the chosen
/// [RentalCategory], and "Next" pushes the step-2 screen wired for
/// that category (sale → [PropertySpecificationsScreen], rent →
/// [PropertyRentSpecificationsScreen]). Other categories fall back
/// to the sale step 2 until their step-2 designs land.
class ListYourPropertyScreen extends StatelessWidget {
  final RentalCategory category;

  const ListYourPropertyScreen({
    super.key,
    this.category = RentalCategory.housesSale,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRentalScreenBg,
      appBar: CommonBackAppBar(title: category.listYourTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RentalCategoryHeader.forCategory(category),
            const SizedBox(height: 12),
            const RentalFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RentalLabeledField(
                    label: 'Project Name',
                    hint: 'Lorem',
                    maxLength: 70,
                  ),
                  SizedBox(height: 14),
                  RentalLabeledField(
                    label: 'Add Title',
                    hint: 'Lorem',
                    maxLength: 70,
                  ),
                  SizedBox(height: 14),
                  RentalLabeledField(
                    label: 'Describe What You Are Selling',
                    hint: 'Text',
                    maxLength: 2000,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: RentalPrimaryButton(
            label: 'Next',
            onTap: () => Get.to(() => _step2For(category)),
          ),
        ),
      ),
    );
  }

  Widget _step2For(RentalCategory cat) {
    switch (cat) {
      case RentalCategory.housesRent:
        return const PropertyRentSpecificationsScreen();
      case RentalCategory.landsPlotsSale:
        return const LandPlotsSpecificationsScreen();
      case RentalCategory.shopsOfficesRent:
      case RentalCategory.shopsOfficesSale:
        return ShopsOfficesSpecificationsScreen(category: cat);
      case RentalCategory.housesSale:
      case RentalCategory.newProjectsSale:
        return PropertySpecificationsScreen(category: cat);
    }
  }
}
