import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_image_upload_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RoomDesignScreen extends StatelessWidget {
  final controller = Get.put(RoomDetailController());
  final String roomType;
  final String roomName;

  RoomDesignScreen({super.key, required this.roomType, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CommonBackAppBar(
        title: roomName,
        actionText: "Step: 1/2",
        actionTextColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFirstSection(),
              SizedBox(height: 16),
              _buildSecondSection(context),
              SizedBox(height: 24),
              _buildSubmitButton(),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonTextField(
              textEditController: controller.totalRoomsTotal,
              title: "Total Rooms",
              hintText: "E.g. 3 Rooms",
              keyBoardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChange: (_) => controller.triggerValidation(),
            ),
            SizedBox(height: 12),
            CustomText("Room Size", fontWeight: FontWeight.w500),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    textEditController: controller.roomLength,
                    hintText: "Length - 20ft",
                    onChange: (_) => controller.triggerValidation(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: CommonTextField(
                    textEditController: controller.roomWidth,
                    hintText: "Width - 30ft",
                    onChange: (_) => controller.triggerValidation(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Obx(() => CommonDropdownDialog<BedType>(
                  title: "Select Bed Type",
                  hintText: "E.g. Single Bed",
                  items: controller.bedTypeList,
                  selectedValue: controller.selectedBedType.value,
                  // displayValue takes the enum and returns the string name defined in the enum
                  displayValue: (bed) => bed.name,
                  onChanged: (value) {
                    controller.onBedTypeChanged(value);
                    controller
                        .triggerValidation(); // Enable/Disable Next button
                  },
                )),
            SizedBox(height: 12),
            Obx(() => CommonDropdownDialog<OccupancyType>(
                  title: "Maximum Occupancy",
                  hintText: "E.g. Family Occupancy",
                  items: controller.occupancyList,
                  selectedValue: controller.selectedOccupancy.value,
                  displayValue: (occ) => occ.name,
                  // Returns the string from the enum
                  onChanged: (value) => controller.onOccupancyChanged(value),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CommonTextField(
              textEditController: controller.pricePerDay,
              title: "Price Per Day",
              hintText: "E.g. ₹300",
              onChange: (_) => controller.triggerValidation(),
            ),
            SizedBox(height: 12),
            Obx(() => ListView.separated(
                  shrinkWrap: true,
                  // Important for use inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.savedCoupons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = controller.savedCoupons[index];
                    return _buildCouponItem(coupon, index);
                  },
                )),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Obx(() => CustomText(
                        controller.savedCoupons.isEmpty
                            ? "Discount Coupon"
                            : "${controller.savedCoupons.length} Coupon Added",
                        color: Colors.grey.shade600,
                      )),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showCouponModal(context),
                icon: Icon(Icons.add),
                label: CustomText("Add More Coupon"),
              ),
            )
          ],
        ),
      ),
    );
  }

  // var savedCoupons = <Map<String, String>>[].obs;

  Widget _buildCouponItem(Map<String, String> data, int index) {
    bool isPercentage = data['offType'] == "In Percentage";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with bold amount
                CustomText(
                    "Discount worth ${isPercentage ? '' : '₹'}${data['offValue']}${isPercentage ? '%' : ''} T&Cs",
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                const SizedBox(height: 4),
                // Description
                CustomText(data['desc'] ?? "",
                    color: Colors.grey.shade600, fontSize: 13),

                const SizedBox(height: 12),
                // Code and Off Label
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.green.shade300,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(6),
                          // To simulate dashed border, you would use a custom painter or package like 'dotted_border'
                        ),
                        child: CustomText(data['code'] ?? "",
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomText(
                        "${data['offValue']}${isPercentage ? '%' : ''} Off",
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ],
                ),
              ],
            ),
          ),
          // The Circular Icon on the right
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade400, width: 1.5),
                ),
              ),
              CustomText(
                isPercentage ? "%" : "₹",
                    color: Colors.brown.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
            ],
          ),
          // Optional: Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => controller.removeCoupon(index),
          )
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GetBuilder<RoomDetailController>(
      builder: (_) {
        bool isValid = controller.isFormValid;

        return CustomBtn(
          isValidate: isValid,
          title: "Next",
          onTap: isValid
              ? () {
                  Get.to(HotelImageUploadScreen(
                    roomName: roomName,
                    roomType: roomType,
                  ));
                }
              : null,
        );

      },
    );
  }
}

void showCouponModal(BuildContext context) {
  final controller = Get.find<RoomDetailController>();

  Get.bottomSheet(
    SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CustomText("Discount Coupon",
                      fontSize: 18, fontWeight: FontWeight.bold),
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              CommonTextField(
                title: "Coupon Name",
                hintText: "e.g. Size",
                textEditController: controller.couponName,
                // onChange: (_) => controller.update(),
                onChange: (_) {
                  controller.isCouponValidMethod();
                  // controller.update();
                },
              ),
              const SizedBox(height: 15),
              CommonTextField(
                title: "Description / Terms And Condition",
                hintText: "Lorem ipsum dolor...",
                maxLine: 3,
                textEditController: controller.couponDesc,
                // onChange: (_) => controller.update(),
                onChange: (_) {
                  controller.isCouponValidMethod();
                  // controller.update();
                },
              ),
              const SizedBox(height: 15),
              CommonTextField(
                title: "Code Name (Optional)",
                hintText: "e.g. 4526525",
                textEditController: controller.couponCode,
                onChange: (_) {
                  controller.isCouponValidMethod();
                  // controller.update();
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const CustomText("Total Off", fontWeight: FontWeight.w500),
                  const Spacer(),
                  Obx(() => _radioOption(controller, "In Rupees")),
                  Obx(() => _radioOption(controller, "In Percentage")),
                ],
              ),
              CommonTextField(
                hintText: "e.g. 10% Off",
                textEditController: controller.totalOff,
                onChange: (_) {

                  controller.isCouponValidMethod();
                  // controller.update();
                },
              ),
              const SizedBox(height: 20),
              Obx(() => CustomBtn(
                    onTap: controller.isCouponValid.value
                        ? () {
                            controller.addCoupon();
                            Get.back();
                          }
                        : null,
                    title: AppStrings.save,
                    isValidate: controller.isCouponValid.value,
                  )),
              const SizedBox(height: 50),

              /*  Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isCouponValid.value
                            ? Colors.blue
                            : Colors.grey[300],
                      ),
                      onPressed: controller.isCouponValid.value
                          ? () {
                              controller.addCoupon();
                              Get.back();
                            }
                          : null,
                      child: const CustomText("Save",
                         color: Colors.white),
                    ),
                  )),*/
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _radioOption(RoomDetailController controller, String value) {
  return Row(
    children: [
      Radio<String>(
        value: value,
        groupValue: controller.offType.value,
        // onChanged: (val) => controller.offType.value = val!,
        onChanged: (val) {
          controller.offType.value = val!;
          controller.isCouponValidMethod();
          // controller.update();
        },
      ),
      CustomText(value, fontSize: 12),
    ],
  );
}
