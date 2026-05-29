import 'package:BlueEra/core/constants/app_colors.dart';
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
        appBar: CommonBackAppBar(title: 'Property Specifications'),
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
                          label: 'House & Apartment Type',
                          options: const [
                            'Flat/Apartments',
                            'Independent / Builder Floor',
                            'Farm House',
                            'House & Villa',
                            'Duplex',
                          ],
                          onChanged: (i) => _ctrl.haType.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'BHK',
                          options: const ['1', '2', '3', '4+'],
                          onChanged: (i) => _ctrl.haBhk.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Bathrooms',
                          options: const ['1', '2', '3', '4+'],
                          onChanged: (i) => _ctrl.haBathrooms.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Availability Status',
                          options: const ['Ready to Move', 'Under Construction'],
                          onChanged: (i) =>
                              _ctrl.haAvailabilityStatus.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Listed By',
                          options: const ['Owner', 'Builder', 'Dealer'],
                          onChanged: (i) => _ctrl.haListedBy.value = i,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalAreaField(
                          label: 'Add Area Details',
                          hint: 'E.g. 4060',
                          onChanged: (v) => _ctrl.haArea.value = v,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Please enter area';
                            if (num.tryParse(s) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        RentalLabeledField(
                          label: 'Maintenance (Monthly)',
                          hint: 'E.g. ₹40,660',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _ctrl.haMaintenance.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter maintenance'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CustomText(
                          'Floor Details',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          'Total No. Of Floors And Your Floor Details',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        RentalLabeledField(
                          label: '',
                          hint: 'Total Floors',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _ctrl.haTotalFloors.value = v,
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Please enter total floors'
                                  : null,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Car Parking',
                          options: const ['1', '2', '3', '4+'],
                          onChanged: (i) => _ctrl.haCarParking.value = i,
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
