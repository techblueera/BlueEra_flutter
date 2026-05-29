import 'package:BlueEra/core/constants/app_colors.dart';
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
                              label: 'Project Type',
                              options: const ['Residential', 'Commercial'],
                              onChanged: (i) =>
                                  _ctrl.npProjectType.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'Project Status',
                              options: const [
                                'New Launch',
                                'Under Construction'
                              ],
                              onChanged: (i) =>
                                  _ctrl.npProjectStatus.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'Type Of Property',
                              options: const [
                                '1 RK',
                                '1 BHK',
                                '2 BHK',
                                '3 BHK',
                                '4 BHK',
                                '4 BHK+',
                                'Office',
                              ],
                              onChanged: (i) =>
                                  _ctrl.npTypeOfProperty.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalAreaField(
                              label: 'Add Area Details',
                              hint: 'E.g. 4060',
                              onChanged: (v) => _ctrl.npArea.value = v,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Please enter area';
                                if (num.tryParse(s) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'Listed By',
                              options: const ['Owner', 'Builder', 'Dealer'],
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
                              'Project Launch Information',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                            ),
                            const SizedBox(height: 12),
                            RentalLabeledField(
                              label: 'Developer/Builder Name',
                              hint: 'E.g. Ritesh Kumar Sharma',
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
                                      ? 'Please enter builder name'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            RentalLabeledField(
                              label: 'RERA Registration No.',
                              hint: 'E.g. 456523',
                              onChanged: (v) => _ctrl.npReraNo.value = v,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Please enter RERA number'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: 'Project Launch Month',
                                    hint: 'E.g. December',
                                    items: [
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
                                SizedBox(width: 12),
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: 'Project Launch Year',
                                    hint: 'E.g. 2026',
                                    items: [
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
                            const Row(
                              children: [
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: 'Expected Possession Month',
                                    hint: 'E.g. December',
                                    items: [
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
                                SizedBox(width: 12),
                                Expanded(
                                  child: RentalLabeledDropdown(
                                    label: 'Expected Possession Year',
                                    hint: 'E.g. 2026',
                                    items: [
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
                              label: 'Key Amenities',
                              hint: 'E.g. Lorem Ipsum Dolor',
                              onChanged: (v) =>
                                  _ctrl.npKeyAmenities.value = v,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Please enter key amenities'
                                      : null,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'No. Of Towers',
                              options: const [
                                '1 to 3',
                                '3 to 5',
                                '5 to 10',
                                '10 +'
                              ],
                              onChanged: (i) =>
                                  _ctrl.npNoOfTowers.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'No. Of Floors',
                              options: const [
                                '1 to 5',
                                '6 to 10',
                                '10 to 20',
                                '20+'
                              ],
                              onChanged: (i) =>
                                  _ctrl.npNoOfFloors.value = i,
                            ),
                            const SizedBox(height: 18),
                            RentalChipSelector(
                              label: 'Facing',
                              options: const [
                                'North',
                                'South',
                                'East',
                                'West',
                                'North-East',
                                'North-West',
                                'South-East',
                                'South-West',
                              ],
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
            label: 'Next',
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
