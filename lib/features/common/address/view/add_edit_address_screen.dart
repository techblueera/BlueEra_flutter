import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/controller/address_form_controller.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/widget/address_type_selector.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Add / edit one address.
///
/// The Google Places field at the top is the fast path — picking a suggestion
/// fills line 1, line 2, city, state and pincode from the place's
/// `address_components`; every field stays editable afterwards.
///
/// Pops with the saved [UserAddress] on success.
class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.address});

  /// Null → create, non-null → edit that address.
  final UserAddress? address;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AddressFormController controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    // Tag per screen instance: an edit opened over a create must not share
    // (or dispose) the other's text controllers.
    _tag = 'address_form_${DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(
      AddressFormController(editingAddress: widget.address),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<AddressFormController>(tag: _tag, force: true);
    super.dispose();
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await controller.save();
    if (saved != null && mounted) Get.back(result: saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: CommonBackAppBar(
        title: controller.isEditMode
            ? AppStrings.updateAddress
            : AppStrings.addAddress,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingM,
            vertical: SizeConfig.paddingS,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(
                  children: [
                    CommonLocationSearchField(
                      controller: controller.searchController,
                      title: 'Search your location',
                      hintText: 'E.g. Gomti Nagar, Lucknow…',
                      // `onPlaceDetails` (not `onSelected`) so we reuse the
                      // place-details body the field already fetched.
                      onPlaceDetails: (placeId, description, details) {
                        controller.applyPlaceSelection(
                          placeId: placeId,
                          description: description,
                          details: details,
                        );
                      },
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Obx(
                      () => controller.isFetchingPlace.value
                          ? Row(
                              children: [
                                SizedBox(
                                  height: SizeConfig.size12,
                                  width: SizeConfig.size12,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: SizeConfig.size8),
                                CustomText(
                                  'Fetching address details…',
                                  fontSize: SizeConfig.extraSmall,
                                  color: AppColors.grey7E,
                                ),
                              ],
                            )
                          : CustomText(
                              'Pick a suggestion to auto-fill the fields below',
                              fontSize: SizeConfig.extraSmall,
                              color: AppColors.grey7E,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size12),
                _card(
                  children: [
                    CommonTextField(
                      textEditController: controller.line1Controller,
                      title: 'Address Line 1',
                      hintText: 'House / flat no., building, street',
                      keyBoardType: TextInputType.streetAddress,
                      isValidate: true,
                      maxLine: 2,
                      autoFillType: AutoFillType.address,
                      validationMessage: 'Please enter address line 1',
                    ),
                    SizedBox(height: SizeConfig.size12),
                    CommonTextField(
                      textEditController: controller.line2Controller,
                      title: 'Address Line 2',
                      hintText: 'Area, colony, landmark (optional)',
                      keyBoardType: TextInputType.streetAddress,
                      isValidate: false,
                      isOptionalFiled: true,
                    ),
                    SizedBox(height: SizeConfig.size12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.cityController,
                            title: AppStrings.city,
                            hintText: 'Lucknow',
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            isValidate: false,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.stateController,
                            title: AppStrings.state,
                            hintText: 'Uttar Pradesh',
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            isValidate: false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size12),
                    CommonTextField(
                      textEditController: controller.pinCodeController,
                      title: AppStrings.pincodeTitle,
                      hintText: '226010',
                      keyBoardType: TextInputType.number,
                      maxLength: 6,
                      isValidate: false,
                      autoFillType: AutoFillType.postalCode,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: SizeConfig.size12),
                    CustomText(
                      'Floor Number',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black28,
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Obx(
                      () => CommonDropdown<String>(
                        items: FloorNumberOption.selectable,
                        selectedValue: controller.selectedFloor.value,
                        hintText: 'Select your floor',
                        displayValue: FloorNumberOption.labelFor,
                        onChanged: (value) =>
                            controller.selectedFloor.value = value,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size8),
                    _floorDeliveryNote(),
                  ],
                ),
                SizedBox(height: SizeConfig.size12),
                _card(
                  children: [
                    CustomText(
                      'Save address as',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black28,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Obx(
                      () => AddressTypeSelector(
                        selectedType: controller.selectedType.value,
                        onTypeSelected: (type) =>
                            controller.selectedType.value = type,
                      ),
                    ),
                    Obx(
                      () => controller.selectedType.value ==
                              AddressTypeOption.other
                          ? Padding(
                              padding: EdgeInsets.only(top: SizeConfig.size12),
                              child: CommonTextField(
                                textEditController:
                                    controller.otherTypeController,
                                title: 'Address type name',
                                hintText: 'E.g. Gym, Parents’ home',
                                isValidate: true,
                                validationMessage:
                                    'Please name this address type',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Obx(
            () => CustomBtn(
              onTap: controller.isSaving.value ? null : _onSave,
              isLoading: controller.isSaving.value,
              title: controller.isEditMode
                  ? AppStrings.updateAddress
                  : AppStrings.saveAddress,
              bgColor: AppColors.primaryColor,
              textColor: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Sits under the floor dropdown: deliveries stop at the ground floor, so
  /// the user knows before saving that the floor is for reference only.
  Widget _floorDeliveryNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: SizeConfig.size14,
          color: AppColors.red00,
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            'Note: We do not deliver at your floor. Please collect your order from the ground floor.',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.red00,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.paddingS),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
