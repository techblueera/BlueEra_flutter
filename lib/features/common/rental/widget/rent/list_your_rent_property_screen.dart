import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/widget/land_plots_specifications_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rent/houses_apartments_rent_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rent/pg_guest_house_rent_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rent/shops_offices_rent_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListYourRentPropertyScreen extends StatefulWidget {
  const ListYourRentPropertyScreen({super.key});

  @override
  State<ListYourRentPropertyScreen> createState() =>
      _ListYourRentPropertyScreenState();
}

class _ListYourRentPropertyScreenState
    extends State<ListYourRentPropertyScreen> {
  late final PropertyController _ctrl;
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;
  final _projectNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PropertyController());
    _ctrl.listingType.value = 'Rent';
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
                          label: AppStrings.selectRentType.tr,
                          options: PropertyController.rentTypes,
                          onChanged: (i) =>
                              _ctrl.selectedPropertyTypeIndex.value = i,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mirrors the "What Kind Of Property" chip strip
                      // on `list_your_property_screen.dart` so the rent
                      // flow asks the residential / commercial question
                      // up-front too. Binds to the same
                      // `selectedPropertyKind` flag on PropertyController
                      // (0 = Residential, 1 = Commercial) so the wire
                      // format stays identical between sell and rent.
                      RentalFormCard(
                        child: RentalChipSelector(
                          label: AppStrings.whatKindOfProperty.tr,
                          options: PropertyController.propertyKindOptions,
                          onChanged: (i) =>
                              _ctrl.selectedPropertyKind.value = i,
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
                              label: AppStrings.describeWhatYouAreRenting.tr,
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
        return const LandPlotsSpecificationsScreen(isRent: true);
      case 2:
        return const ShopsOfficesRentScreen();
      case 3:
        return const PgGuestHouseRentScreen();
      default:
        return const HousesApartmentsRentScreen();
    }
  }
}
