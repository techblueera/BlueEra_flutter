import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/complete_your_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rent/complete_your_rent_listing_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LandPlotsSpecificationsScreen extends StatefulWidget {
  final bool isRent;

  const LandPlotsSpecificationsScreen({super.key, this.isRent = false});

  @override
  State<LandPlotsSpecificationsScreen> createState() =>
      _LandPlotsSpecificationsScreenState();
}

class _LandPlotsSpecificationsScreenState
    extends State<LandPlotsSpecificationsScreen> {
  late final PropertyController _ctrl;
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;

  /// Shared required-numeric validator factory used by the three
  /// area fields. Keeps each call site one line and the error copy
  /// identical so the form reads consistently.
  String? Function(String?) _numericRequired(String emptyMessage) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return emptyMessage;
      if (num.tryParse(v) == null) return AppStrings.enterValidNumber.tr;
      return null;
    };
  }

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
          title: RentalCategory.landsPlotsSale.specificationsTitle,
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
                  child: RentalFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RentalLocationField(),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.projectTypeLabel.tr,
                          options: PropertyController.lpProjectTypeOptions,
                          onChanged: (i) => _ctrl.lpProjectType.value = i,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelListedBy.tr,
                          options: PropertyController.listedByOptions,
                          onChanged: (i) => _ctrl.lpListedBy.value = i,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalAreaField(
                          label: AppStrings.addPlotAreaDetails.tr,
                          hint: AppStrings.egArea4060.tr,
                          onChanged: (v) => _ctrl.lpPlotArea.value = v,
                          validator:
                              _numericRequired(AppStrings.pleaseEnterPlotArea.tr),
                        ),
                        const SizedBox(height: 14),
                        RentalAreaField(
                          label: AppStrings.enterLengthFieldLabel.tr,
                          hint: AppStrings.enterLengthFieldLabel.tr,
                          onChanged: (v) => _ctrl.lpLength.value = v,
                          validator: _numericRequired(
                              AppStrings.pleaseEnterLengthValidation.tr),
                        ),
                        const SizedBox(height: 14),
                        RentalAreaField(
                          label: AppStrings.enterBreadthFieldLabel.tr,
                          hint: AppStrings.enterBreadthFieldLabel.tr,
                          onChanged: (v) => _ctrl.lpBreadth.value = v,
                          validator: _numericRequired(
                              AppStrings.pleaseEnterBreadthValidation.tr),
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: AppStrings.filterLabelFacing.tr,
                          options: PropertyController.facingOptions,
                          onChanged: (i) => _ctrl.lpFacing.value = i,
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
              Get.to(() => widget.isRent
                  ? const CompleteYourRentListingScreen()
                  : const CompleteYourListingScreen());
            },
          ),
        ),
      ),
    );
  }
}
