import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/regular_expression.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key, this.address, this.lat, this.long, required this.message});
  final Messages message;
  final String? address;
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
    debugPrint("Longitude: ${widget.long}");
    orderController.fullAddress.value.text=widget.address??"";
    orderController.nameController.value.text=widget.message.buyer?.name??"";
    orderController.phoneController.value.text=widget.message.buyer?.contact??"";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Add Address",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
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
                title: "Full Name",
                hintText: "Enter your full name",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: true,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.phoneController.value,
                keyBoardType: TextInputType.phone,
                title: "Phone Number",
                hintText: "Enter phone number",
                maxLength: 10,
                regularExpression: RegularExpressionUtils
                    .phoneWithPrefixPattern,
                isValidate: true,
              ),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: orderController.fullAddress.value,
                keyBoardType: TextInputType.name,
                title: "Full Address",
                hintText: "Enter your full Address",
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.houseNoController.value,
                keyBoardType: TextInputType.text,
                title: "House / Flat No",
                hintText: "Enter house number",
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.streetController.value,
                keyBoardType: TextInputType.text,
                title: "Street",
                hintText: "Enter street name",
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.landmarkController.value,
                keyBoardType: TextInputType.text,
                title: "Landmark",
                hintText: "Near City Mall, etc.",
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.cityController.value,
                keyBoardType: TextInputType.text,
                title: "City",
                hintText: "Enter city",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.stateController.value,
                keyBoardType: TextInputType.text,
                title: "State",
                hintText: "Enter state",
                regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                isValidate: false,
              ),
              const SizedBox(height: 12),

              CommonTextField(
                textEditController: orderController.zipController.value,
                keyBoardType: TextInputType.number,
                title: "Zip Code",
                hintText: "Enter postal code",
                isValidate: true,
              ),
              const SizedBox(height: 12),
              
              CommonTextField(
                textEditController: orderController.noteController.value,
                keyBoardType: TextInputType.multiline,
                title: "Notes public instruction to delivery pilot",
                hintText: "Any delivery notes (optional)",
                isValidate: false,
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Set as default address",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                  // ✅ If all fields valid
                  print("dlaskcmlksdcm ${widget.lat} ,, ${widget.long}");
                  orderController.addAddressApi(widget.lat, widget.long);
                } else {
                  debugPrint("⚠️ Validation failed!");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Save Address",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
