import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/regular_expression.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../../auth/model/get_adress_details_model.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen(
      {super.key,
      this.address,
      this.lat,
      this.long,
      required this.message,
      this.addressModel});

  final Messages message;
  final String? address;
  final AddressDetails? addressModel;
  final double? lat;
  final double? long;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final orderController = Get.find<OrderNowController>();

  @override
  void initState() {
    super.initState();

    orderController.fullAddress.value.text = widget.address ?? "";
    orderController.nameController.value.text =
        widget.message.buyer?.name ?? "";
    orderController.phoneController.value.text =
        widget.message.buyer?.contact ?? "";
    if (widget.addressModel != null) {
      // EDIT MODE
      final a = widget.addressModel!;

      orderController.nameController.value.text = a.name ?? "";
      orderController.phoneController.value.text = a.phone ?? "";
      orderController.fullAddress.value.text =
          "${a.houseNo}, ${a.street}, ${a.city}";
      orderController.houseNoController.value.text = a.houseNo ?? "";
      orderController.streetController.value.text = a.street ?? "";
      orderController.landmarkController.value.text = a.landmark ?? "";
      orderController.cityController.value.text = a.city ?? "";
      orderController.stateController.value.text = a.state ?? "";
      orderController.zipController.value.text = a.zipCode ?? "";
      orderController.noteController.value.text = a.note ?? "";

      // Default switch
      orderController.isDefault.value = a.isDefault ?? false;

      // Lat/Lng
      // orderController.editLat.value = a.lat?.toDouble() ?? 0.0;
      // orderController.editLng.value = a.lng?.toDouble() ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(
        title: (widget.addressModel == null)
            ? AppStrings.addAddress.tr
            : AppStrings.updateAddress.tr,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey, // ✅ wrap all fields in Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: orderController.nameController.value,
                keyBoardType: TextInputType.name,
                title: AppStrings.fullName,
                hintText: AppStrings.enterFullName,
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: true,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.phoneController.value,
                keyBoardType: TextInputType.phone,
                title: AppStrings.phoneNumber,
                hintText: AppStrings.enterMobileNumberHint,
                maxLength: 10,
                regularExpression:
                    RegularExpressionUtils.phoneWithPrefixPattern,
                isValidate: true,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.fullAddress.value,
                keyBoardType: TextInputType.name,
                title: AppStrings.fullAddress,
                hintText: AppStrings.addressHint,
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.houseNoController.value,
                keyBoardType: TextInputType.text,
                title: AppStrings.houseFlatNo,
                hintText: "B-Div 101",
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.streetController.value,
                keyBoardType: TextInputType.text,
                title: AppStrings.street,
                hintText: "Shivaji Nagar",
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.landmarkController.value,
                keyBoardType: TextInputType.text,
                title: AppStrings.landMark,
                hintText: AppStrings.landmarkHint,
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.cityController.value,
                keyBoardType: TextInputType.text,
                title: AppStrings.city,
                hintText: "Mumbai",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.stateController.value,
                keyBoardType: TextInputType.text,
                title: AppStrings.state,
                hintText: "Maharashtra",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: false,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.zipController.value,
                keyBoardType: TextInputType.number,
                title: AppStrings.pincodeTitle,
                hintText: AppStrings.pincodeHint,
                isValidate: true,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.noteController.value,
                keyBoardType: TextInputType.multiline,
                title: AppStrings.notesPublicInstruction,
                hintText: AppStrings.deliveryNotes,
                isValidate: false,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.setDefaultAddress,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  Obx(() {
                    return Switch(
                      value: orderController.isDefault.value,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          orderController.isDefault.value = val;
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // 🔹 Bottom button with validation
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (widget.addressModel == null) {
                    // ADD NEW ADDRESS
                    orderController.addAddressApi(widget.lat, widget.long);
                  } else {
                    // UPDATE EXISTING ADDRESS
                    orderController.updateAddressApi(
                        widget.lat, widget.long, widget.addressModel?.id ?? '');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: CustomText(
                widget.addressModel == null
                    ? AppStrings.saveAddress
                    : AppStrings.updateAddress,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
