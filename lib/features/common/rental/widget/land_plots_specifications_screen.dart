import 'package:BlueEra/features/common/rental/widget/complete_your_listing_project_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 2 — lands & plots variant. Six fields tuned for plot
/// listings: Type (sale / rent of plot), Listed By, Plot Area,
/// Length, Breadth, Facing. "Next" pushes
/// [CompleteYourListingProjectScreen] because plot pricing is
/// generally quoted as a range.
class LandPlotsSpecificationsScreen extends StatelessWidget {
  const LandPlotsSpecificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRentalScreenBg,
      appBar: CommonBackAppBar(
        title: RentalCategory.landsPlotsSale.specificationsTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: const RentalFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RentalLabeledDropdown(
                label: 'Type',
                hint: 'For rent',
                items: ['For Sale', 'For Rent'],
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Listed By',
                hint: 'E.g. Owner',
                items: ['Owner', 'Dealer', 'Broker'],
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Plot Area',
                hint: 'E.g. Lorem Ipsum',
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Length',
                hint: 'E.g. 1200 Square Feet.',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledField(
                label: 'Breadth',
                hint: 'E.g. 1000 Square Feet.',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14),
              RentalLabeledDropdown(
                label: 'Facing',
                hint: 'E.g. North East',
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
            onTap: () =>
                Get.to(() => const CompleteYourListingProjectScreen()),
          ),
        ),
      ),
    );
  }
}
