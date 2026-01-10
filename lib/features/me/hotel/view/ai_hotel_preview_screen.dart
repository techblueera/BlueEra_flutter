import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

class HotelPreviewScreen extends StatefulWidget {
  @override
  State<HotelPreviewScreen> createState() => _HotelPreviewScreenState();
}

class _HotelPreviewScreenState extends State<HotelPreviewScreen> {
  // Use the existing controller
  final controller = Get.find<HotelServiceController>();

  @override
  void initState() {
    final emergency =
        controller.aiHotelResModel?.value.data?.screens?.contactUs?.emergency;
    controller.isFormValid.value=false;
    // TODO: implement initState
    controller.policeStationName.value = emergency?.policeStation ?? "";
    controller.hospitalName.value = emergency?.hospital ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screens = controller.aiHotelResModel?.value.data?.screens;
    final policies = screens?.hotelPolicies;
    final rules = policies?.rules;
    final restaurant = screens?.restaurantMenu;

    return Scaffold(
      appBar: CommonBackAppBar(
        title:
            "${controller.aiHotelResModel?.value.data?.appMetadata?.appName}",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Timing Section
            _buildSectionHeader("Check-in / Check-out"),
            _buildInfoCard([
              _buildRowCheckIn("Check-in Time", policies?.checkInTime ?? "12:00 PM"),
              _buildRowCheckIn("Check-out Time", policies?.checkOutTime ?? "11:00 AM"),
            ]),

            // 2. Rules Section (The data usually hidden)
            _buildSectionHeader("Hotel Rules"),
            _buildInfoCard([
              _buildRuleStatus("Aadhar Mandatory", rules?.aadharMandatory),
              _buildRuleStatus("Allow Bachelors", rules?.allowBachelors),
              _buildRuleStatus(
                  "Allow Unmarried Couples", rules?.allowUnmarriedCouples),
              _buildRuleStatus("Local ID Allowed", rules?.localIDAllowed),
              _buildRuleStatus(
                  "Smoking/Drinking", rules?.smokingDrinkingAllowed),
            ]),

            // 3. Food & Restaurant Details
            _buildSectionHeader("Dining & Restrictions"),
            _buildInfoCard([
              CustomText("Cuisines Served:", fontWeight: FontWeight.bold),
              const SizedBox(height: 4),
              CustomText(restaurant?.cuisines?.join(", ") ?? "Not specified"),
              const Divider(),
              ...policies!.foodRestrictions!
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: CustomText("• $item", color: Colors.red[700]),
                      ))
                  .toList(),
            ]),

            // 4. Contact Details
            _buildEmergencySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    final emergency =
        controller.aiHotelResModel?.value.data?.screens?.contactUs?.emergency;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader("Emergency Contacts"),
            TextButton.icon(
              onPressed: () async {
                showEditBottomSheet();
              },
              icon: Icon(Icons.edit, size: 16),
              label: Text("Edit"),
            )
          ],
        ),
        Obx(() {
          return _buildInfoCard([
            _buildRow("Police", controller.policeStationName.value),
            _buildRow("Hospital", controller.hospitalName.value),
            _buildRow("Phone", controller.phoneNumber.value),
            _buildRow("City", controller.cityName.value),
            _buildRow("State", controller.stateName.value),
            _buildRow("Pincode", controller.pinCodeName.value),
          ]);
        }),
        const SizedBox(height: 20),

        PositiveCustomBtn(
          onTap: () async {
            if (controller.phoneNumber.value.isEmpty) {
              commonSnackBar(message: "Phone number is required");
              return;
            } else if (controller.pinCodeName.value.isEmpty) {
              commonSnackBar(message: "Pincode is required");
              return;
            } else if (controller.cityName.value.isEmpty) {
              commonSnackBar(message: "City name is required");
              return;
            } else if (controller.stateName.value.isEmpty) {
              commonSnackBar(message: "State name is required");
              return;
            }
            await controller.createHotelServiceController();
          },
          title: "Create Hotel",
        ),
        const SizedBox(height: 50),

      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomText(
        title,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _buildRowCheckIn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText("${label} : ", color: Colors.grey[700]),
          SizedBox(
            width: SizeConfig.size20,
          ),
          CustomText(value, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: CustomText("${label} : ", color: Colors.grey[700])),
          SizedBox(
            width: SizeConfig.size20,
          ),
          Expanded(
              flex: 3, child: CustomText(value, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRuleStatus(String label, bool? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(label),
          Icon(
            status == true ? Icons.check_circle : Icons.cancel,
            color: status == true ? Colors.green : Colors.red,
            size: 20,
          )
        ],
      ),
    );
  }

  showEditBottomSheet() {
    controller.prepareEditFields();
    final _formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText("Edit Contact Info",
                    fontSize: 18, fontWeight: FontWeight.bold),
                SizedBox(height: 20),

                // Search Field for Hospital/Police Location
                CommonLocationSearchField(
                  title: "Search Nearby Hospital",
                  hintText: "Search on via address...",
                  onSelected: (placeId, lat, lng, address) {
                    // Logic to decide if this is hospital or police
                    controller.hospitalController.text = address;
                    controller.hospitalName.value = address;
                  },
                  controller: controller.hospitalController,
                  isShowLeading: false,
                ),

                const SizedBox(height: 15),

                CommonLocationSearchField(
                  title: "Search Nearby Police Station",
                  hintText: "Search on via address...",
                  onSelected: (placeId, lat, lng, address) {
                    // Logic to decide if this is hospital or police
                    controller.policeController.text = address;
                    controller.policeStationName.value = address;
                  },
                  controller: controller.policeController,
                  isShowLeading: false,
                ),
                const SizedBox(height: 15),

                CommonTextField(
                  title: "Mobile Number",
                  textEditController: controller.phoneController,
                  keyBoardType: TextInputType.phone,

                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  validator: (value) {
                    if (value!.length < 10)
                      return "Enter valid 10-digit number";
                    return null;
                  },
                  onChange: (val) {
                    controller.phoneNumber.value = val;
                    controller.validateFields();
                  }, // Add this
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        title: "City",
                        textEditController: controller.cityController,
                        onChange: (val) {
                          controller.cityName.value = val;
                          controller.validateFields();
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CommonTextField(
                        title: "Pincode",
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        textEditController: controller.pincodeController,
                        keyBoardType: TextInputType.number,
                        validator: (value) =>
                            value!.length != 6 ? "Invalid" : null,
                        onChange: (val) {
                          controller.pinCodeName.value = val;
                          controller.validateFields();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                CommonTextField(
                  title: "State",
                  textEditController: controller.stateController,
                  onChange: (val) {
                    controller.stateName.value = val;
                    controller.validateFields();
                  },
                ),
                SizedBox(height: 30),
                // Wrap the button in Obx to make it reactive
                Obx(() => CustomBtn(
                      onTap: controller.isFormValid.value
                          ? () {
                              if (_formKey.currentState!.validate()) {
                                controller.updateEmergencyDetails();
                              }
                            }
                          : null,

                      isValidate: controller.isFormValid.value,
                      // Setting onTap to null disables the button
                      title: "Save Changes",
                      // You can also change the button color based on state
                    )),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
