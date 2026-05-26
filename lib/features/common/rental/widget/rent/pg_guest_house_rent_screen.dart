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
                          label: 'Subtype',
                          options: const ['Guest House', 'PG', 'Roommate'],
                          onChanged: (v) => _ctrl.pgSubtype.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Room Type',
                          options: const [
                            'Single Sharing',
                            'Double Sharing',
                            'Triple Sharing',
                            'Dormitory',
                          ],
                          onChanged: (v) => _ctrl.pgRoomType.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Attached Bathroom',
                          options: const ['Yes Attached', 'Not Attached'],
                          onChanged: (v) =>
                              _ctrl.pgAttachedBathroom.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Furnishing',
                          options: const [
                            'Furnished',
                            'Semi-Furnished',
                            'Unfurnished'
                          ],
                          onChanged: (v) => _ctrl.pgFurnishing.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Listed By',
                          options: const ['Owner', 'Builder', 'Dealer'],
                          onChanged: (v) => _ctrl.pgListedBy.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Car Parking',
                          options: const ['1', '2', '3', '4+'],
                          onChanged: (v) => _ctrl.pgCarParking.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalChipSelector(
                          label: 'Meals Included',
                          options: const ['Yes Included', 'Not Included'],
                          onChanged: (v) => _ctrl.pgMealsIncluded.value = v,
                        ),
                        const SizedBox(height: 18),
                        RentalLabeledField(
                          label: 'Key Amenities',
                          hint: 'E.g. Lorem Ipsum Dolor',
                          onChanged: (v) => _ctrl.pgKeyAmenities.value = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter key amenities'
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
