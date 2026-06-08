import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PropertySpecificationsScreen extends StatefulWidget {
  const PropertySpecificationsScreen({super.key});

  @override
  State<PropertySpecificationsScreen> createState() =>
      _PropertySpecificationsScreenState();
}

class _PropertySpecificationsScreenState
    extends State<PropertySpecificationsScreen> {
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
        appBar: CommonBackAppBar(title: AppStrings.propertySpecificationsTitle.tr),
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
                          label: AppStrings.houseApartmentTypeLabel.tr,
                          options: PropertyController.haTypeOptions,
                          onChanged: (i) => _ctrl.haType.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelBHK.tr,
                          options: PropertyController.bhkOptions,
                          onChanged: (i) => _ctrl.haBhk.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelBathrooms.tr,
                          options: PropertyController.bathroomOptions,
                          onChanged: (i) => _ctrl.haBathrooms.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.availabilityStatusLabel.tr,
                          options: PropertyController.availabilityOptions,
                          onChanged: (i) =>
                              _ctrl.haAvailabilityStatus.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelListedBy.tr,
                          options: PropertyController.listedByOptions,
                          onChanged: (i) => _ctrl.haListedBy.value = i,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalAreaField(
                          label: AppStrings.addAreaDetails.tr,
                          hint: AppStrings.egArea4060.tr,
                          onChanged: (v) => _ctrl.haArea.value = v,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return AppStrings.pleaseEnterArea.tr;
                            if (num.tryParse(s) == null) {
                              return AppStrings.enterValidNumber.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        RentalLabeledField(
                          label: AppStrings.maintenanceMonthlyLabel.tr,
                          hint: AppStrings.egRupees40660.tr,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _ctrl.haMaintenance.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? AppStrings.pleaseEnterMaintenance.tr
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CustomText(
                          AppStrings.floorDetails.tr,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          AppStrings.totalFloorsAndYourFloorHint.tr,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        RentalLabeledField(
                          label: '',
                          hint: AppStrings.totalFloorsLabel.tr,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _ctrl.haTotalFloors.value = v,
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? AppStrings.pleaseEnterTotalFloors.tr
                                  : null,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelCarParking.tr,
                          options: PropertyController.parkingOptions,
                          onChanged: (i) => _ctrl.haCarParking.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelFacing.tr,
                          options: PropertyController.facingOptions,
                          onChanged: (i) => _ctrl.haFacing.value = i,
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
              Get.to(() => const CompleteYourListingScreen());
            },
          ),
        ),
      ),
    );
  }
}
