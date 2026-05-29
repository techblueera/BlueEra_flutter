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
                          label: 'Furnishing',
                          options: const [
                            'Furnished',
                            'Semi-Furnished',
                            'Unfurnished'
                          ],
                          onChanged: (v) => _ctrl.soFurnishing.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Listed By',
                          options: const ['Owner', 'Builder', 'Dealer'],
                          onChanged: (v) => _ctrl.soListedBy.value = v,
                        ),
                        const SizedBox(height: 14),
                        const RentalListedByNameField(),
                        const SizedBox(height: 18),
                        RentalAreaField(
                          label: 'Super Built-Up Area Details',
                          hint: 'E.g. 4060',
                          onChanged: (v) => _ctrl.soArea.value = v,
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
                          onChanged: (v) => _ctrl.soMaintenance.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter maintenance'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Car Parking',
                          options: const ['1', '2', '3', '4+'],
                          onChanged: (v) => _ctrl.soCarParking.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Washrooms',
                          options: const ['1', '2', '3', '4+'],
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
            label: 'Next',
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
