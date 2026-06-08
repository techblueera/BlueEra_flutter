import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/rent/complete_your_rent_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShopsOfficesRentScreen extends StatefulWidget {
  const ShopsOfficesRentScreen({super.key});

  @override
  State<ShopsOfficesRentScreen> createState() => _ShopsOfficesRentScreenState();
}

class _ShopsOfficesRentScreenState extends State<ShopsOfficesRentScreen> {
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
                          label: AppStrings.filterLabelFurnishing.tr,
                          options: PropertyController.furnishingOptions,
                          onChanged: (v) => _ctrl.soFurnishing.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelListedBy.tr,
                          options: PropertyController.listedByOptions,
                          onChanged: (v) => _ctrl.soListedBy.value = v,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalAreaField(
                          label: AppStrings.superBuiltUpAreaDetailsLabel.tr,
                          hint: AppStrings.egArea4060.tr,
                          onChanged: (v) => _ctrl.soArea.value = v,
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
                          onChanged: (v) => _ctrl.soMaintenance.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? AppStrings.pleaseEnterMaintenance.tr
                              : null,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelCarParking.tr,
                          options: PropertyController.parkingOptions,
                          onChanged: (v) => _ctrl.soCarParking.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelWashrooms.tr,
                          options: PropertyController.washroomOptions,
                          onChanged: (v) => _ctrl.soWashrooms.value = v,
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
