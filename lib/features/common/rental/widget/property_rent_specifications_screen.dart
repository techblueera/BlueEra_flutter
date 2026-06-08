import 'package:BlueEra/core/constants/app_strings.dart';
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
      appBar: CommonBackAppBar(title: AppStrings.propertySpecificationsTitle.tr),
      body: Column(
        children: [
          const RentalStepProgressBar(progress: 0.66),
          Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: RentalFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RentalLabeledDropdown(
                label: AppStrings.typeLabel.tr,
                hint: AppStrings.egDuplex.tr,
                items: const [
                  'Apartment',
                  'Independent House',
                  'Duplex',
                  'Villa',
                  'Builder Floor',
                  'Studio'
                ],
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelBHK.tr,
                hint: AppStrings.egThreeBhk.tr,
                items: const ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'],
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelBathrooms.tr,
                hint: AppStrings.egFourPlus.tr,
                items: const ['1', '2', '3', '4', '4+'],
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelFurnishing.tr,
                hint: AppStrings.egSemiFurnished.tr,
                items: const ['Furnished', 'Semi Furnished', 'Unfurnished'],
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelListedBy.tr,
                hint: AppStrings.egOwner.tr,
                items: const ['Owner', 'Dealer', 'Builder'],
              ),
              const SizedBox(height: 14),
              RentalLabeledField(
                label: AppStrings.superBuiltupAreaSqftLabel.tr,
                hint: AppStrings.egArea4060.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RentalLabeledField(
                label: AppStrings.carpetAreaSqftLabel.tr,
                hint: AppStrings.egArea4060.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.bachelorsAllowedLabel.tr,
                hint: AppStrings.egNo.tr,
                items: const ['Yes', 'No'],
              ),
              const SizedBox(height: 14),
              RentalLabeledField(
                label: AppStrings.maintenanceMonthlyLabel.tr,
                hint: AppStrings.egRupees40660.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RentalLabeledField(
                label: AppStrings.totalFloorsLabel.tr,
                hint: AppStrings.egEight.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RentalLabeledField(
                label: AppStrings.floorNoLabel.tr,
                hint: AppStrings.egEight.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelCarParking.tr,
                hint: AppStrings.loremPlaceholder.tr,
                items: const ['None', '1', '2', '3+'],
              ),
              const SizedBox(height: 14),
              RentalLabeledDropdown(
                label: AppStrings.filterLabelFacing.tr,
                hint: AppStrings.loremPlaceholder.tr,
                items: const [
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
      )),
        ],
      ),
      bottomNavigationBar: RentalBottomBar(
        child: RentalPrimaryButton(
          label: AppStrings.next.tr,
          onTap: () => Get.to(() => const CompleteYourListingScreen()),
        ),
      ),
    );
  }
}
