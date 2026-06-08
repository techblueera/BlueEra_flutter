import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewProjectSpecificationsScreen extends StatefulWidget {
  const NewProjectSpecificationsScreen({super.key});

  @override
  State<NewProjectSpecificationsScreen> createState() =>
      _NewProjectSpecificationsScreenState();
}

class _NewProjectSpecificationsScreenState
    extends State<NewProjectSpecificationsScreen> {
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
          title: RentalCategory.newProjectsSale.specificationsTitle,
        ),
        body: Column(
          children: [
            const RentalStepProgressBar(progress: 0.66),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RentalFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RentalLocationField(),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.projectTypeLabel.tr,
                              options: PropertyController.propertyKindOptions,
                              onChanged: (i) =>
                                  _ctrl.npProjectType.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.filterLabelProjectStatus.tr,
                              options: PropertyController.availabilityOptions,
                              onChanged: (i) =>
                                  _ctrl.npProjectStatus.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.typeOfPropertyLabel.tr,
                              options:
                                  PropertyController.npPropertyTypeOptions,
                              onChanged: (i) =>
                                  _ctrl.npTypeOfProperty.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalAreaField(
                              label: AppStrings.addAreaDetails.tr,
                              hint: AppStrings.egArea4060.tr,
                              onChanged: (v) => _ctrl.npArea.value = v,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) {
                                  return AppStrings.pleaseEnterArea.tr;
                                }
                                if (num.tryParse(s) == null) {
                                  return AppStrings.enterValidNumber.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.filterLabelListedBy.tr,
                              options: PropertyController.listedByOptions,
                              onChanged: (i) => _ctrl.npListedBy.value = i,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RentalFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomText(
                              AppStrings.projectLaunchInformation.tr,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                            ),
                            const SizedBox(height: 12),
                            RentalLabeledField(
                              label: AppStrings.developerBuilderName.tr,
                              hint: AppStrings.egRiteshKumarSharma.tr,
                              onChanged: (v) {
                                // Single name input for new projects — feeds
                                // both the launch-info builderName and the
                                // shared top-level listedByName so we keep
                                // one field while populating the same keys
                                // the other property types use.
                                _ctrl.npBuilderName.value = v;
                                _ctrl.listedByName.value = v;
                              },
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? AppStrings.pleaseEnterBuilderName.tr
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            RentalLabeledField(
                              label: AppStrings.reraRegistrationNo.tr,
                              hint: AppStrings.egRera456523.tr,
                              onChanged: (v) => _ctrl.npReraNo.value = v,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? AppStrings.pleaseEnterReraNumber.tr
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: AppStrings.projectLaunchMonth.tr,
                                    hint: AppStrings.egDecember.tr,
                                    items: const [
                                      'January',
                                      'February',
                                      'March',
                                      'April',
                                      'May',
                                      'June',
                                      'July',
                                      'August',
                                      'September',
                                      'October',
                                      'November',
                                      'December',
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: AppStrings.projectLaunchYear.tr,
                                    hint: AppStrings.eg2026.tr,
                                    items: const [
                                      '2024',
                                      '2025',
                                      '2026',
                                      '2027',
                                      '2028',
                                      '2029',
                                      '2030',
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label:
                                        AppStrings.expectedPossessionMonth.tr,
                                    hint: AppStrings.egDecember.tr,
                                    items: const [
                                      'January',
                                      'February',
                                      'March',
                                      'April',
                                      'May',
                                      'June',
                                      'July',
                                      'August',
                                      'September',
                                      'October',
                                      'November',
                                      'December',
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: AppStrings.expectedPossessionYear.tr,
                                    hint: AppStrings.eg2026.tr,
                                    items: const [
                                      '2024',
                                      '2025',
                                      '2026',
                                      '2027',
                                      '2028',
                                      '2029',
                                      '2030',
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RentalFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RentalLabeledField(
                              label: AppStrings.keyAmenitiesLabel.tr,
                              hint: AppStrings.egLoremIpsumDolor.tr,
                              onChanged: (v) =>
                                  _ctrl.npKeyAmenities.value = v,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? AppStrings.pleaseEnterKeyAmenities.tr
                                      : null,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.noOfTowersLabel.tr,
                              options: PropertyController.towersOptions,
                              onChanged: (i) =>
                                  _ctrl.npNoOfTowers.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.noOfFloorsLabel.tr,
                              options: PropertyController.floorsOptions,
                              onChanged: (i) =>
                                  _ctrl.npNoOfFloors.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: AppStrings.filterLabelFacing.tr,
                              options: PropertyController.facingOptions,
                              onChanged: (i) => _ctrl.npFacing.value = i,
                            ),
                          ],
                        ),
                      ),
                    ],
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
