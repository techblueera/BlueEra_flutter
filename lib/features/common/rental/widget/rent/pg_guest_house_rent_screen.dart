import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/rent/complete_your_rent_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PgGuestHouseRentScreen extends StatefulWidget {
  const PgGuestHouseRentScreen({super.key});

  @override
  State<PgGuestHouseRentScreen> createState() =>
      _PgGuestHouseRentScreenState();
}

class _PgGuestHouseRentScreenState extends State<PgGuestHouseRentScreen> {
  late final PropertyController _ctrl;
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PropertyController>();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(
            title: AppStrings.propertySpecificationsTitle.tr),
        body: Column(
          children: [
            const RentalStepProgressBar(progress: 0.66),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate,
                  child: RentalFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RentalLocationField(),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.subtypeLabel.tr,
                          options: PropertyController.pgSubtypeOptions,
                          onChanged: (v) => _ctrl.pgSubtype.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelRoomType.tr,
                          options: PropertyController.pgRoomTypeOptions,
                          onChanged: (v) => _ctrl.pgRoomType.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelAttachedBathroom.tr,
                          options:
                              PropertyController.attachedBathroomOptions,
                          onChanged: (v) =>
                              _ctrl.pgAttachedBathroom.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelFurnishing.tr,
                          options: PropertyController.furnishingOptions,
                          onChanged: (v) => _ctrl.pgFurnishing.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelListedBy.tr,
                          options: PropertyController.listedByOptions,
                          onChanged: (v) => _ctrl.pgListedBy.value = v,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelCarParking.tr,
                          options: PropertyController.parkingOptions,
                          onChanged: (v) => _ctrl.pgCarParking.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.mealsIncludedLabel.tr,
                          options: PropertyController.mealsOptions,
                          onChanged: (v) => _ctrl.pgMealsIncluded.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalLabeledField(
                          label: AppStrings.keyAmenitiesLabel.tr,
                          hint: AppStrings.egLoremIpsumDolor.tr,
                          onChanged: (v) => _ctrl.pgKeyAmenities.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? AppStrings.pleaseEnterKeyAmenities.tr
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: RentalBottomBar(
          child: RentalPrimaryButton(
            label: AppStrings.next.tr,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
              if (!_formKey.currentState!.validate()) return;
              Get.to(() => const CompleteYourRentListingScreen());
            },
          ),
        ),
      ),
    );
  }
}
