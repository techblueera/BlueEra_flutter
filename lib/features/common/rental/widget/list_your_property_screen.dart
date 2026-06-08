import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/land_plots_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/new_project_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/property_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/features/common/rental/widget/shops_offices_specifications_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListYourPropertyScreen extends StatefulWidget {
  const ListYourPropertyScreen({super.key});

  @override
  State<ListYourPropertyScreen> createState() =>
      _ListYourPropertyScreenState();
}

class _ListYourPropertyScreenState extends State<ListYourPropertyScreen> {
  late final PropertyController _ctrl;
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;
  final _projectNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PropertyController());
    _ctrl.listingType.value = 'Sell';
    _ctrl.resetAll();
  }

  @override
  void dispose() {
    _projectNameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(title: AppStrings.listYourProperty.tr),
        body: Column(
          children: [
            const RentalStepProgressBar(progress: 0.33),
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
                        child: RentalChipSelector(
                          label: AppStrings.selectSaleType.tr,
                          options: PropertyController.saleTypes,
                          onChanged: (i) =>
                              _ctrl.selectedPropertyTypeIndex.value = i,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RentalFormCard(
                        child: RentalChipSelector(
                          label: AppStrings.whatKindOfProperty.tr,
                          options: PropertyController.propertyKindOptions,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RentalFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RentalLabeledField(
                              label: AppStrings.projectNameLabel.tr,
                              hint: AppStrings.enterProjectNameHint.tr,
                              maxLength: 70,
                              textInputAction: TextInputAction.next,
                              controller: _projectNameCtrl,
                              onChanged: (v) =>
                                  _ctrl.projectName.value = v,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppStrings.pleaseEnterProjectName.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            RentalLabeledField(
                              label: AppStrings.describeWhatYouAreSelling.tr,
                              hint: AppStrings.textHint.tr,
                              maxLength: 2000,
                              maxLines: 5,
                              textInputAction: TextInputAction.done,
                              controller: _descriptionCtrl,
                              onChanged: (v) =>
                                  _ctrl.description.value = v,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppStrings.pleaseAddDescription.tr;
                                }
                                return null;
                              },
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
            onTap: _onNext,
          ),
        ),
      ),
    );
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    Get.to(() => _step2ForIndex(_ctrl.selectedPropertyTypeIndex.value));
  }

  Widget _step2ForIndex(int index) {
    switch (index) {
      case 1:
        return const NewProjectSpecificationsScreen();
      case 2:
        return const LandPlotsSpecificationsScreen();
      case 3:
        return const ShopsOfficesSpecificationsScreen();
      default:
        return const PropertySpecificationsScreen();
    }
  }
}
