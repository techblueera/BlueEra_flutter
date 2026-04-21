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
        actionText: AppStrings.hotelStepOneOfTwo.tr,
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
              title: AppStrings.hotelTotalRooms.tr,
              hintText: AppStrings.hotelHintTotalRooms.tr,
              keyBoardType: TextInputType.number,
              regularExpression: r'[0-9]',
              inputLength: 3,
              validationMessage: AppStrings.required.tr,
              onChange: (_) => controller.triggerValidation(),
            ),
            SizedBox(height: 12),
            CustomText(AppStrings.hotelRoomSize.tr,
                fontWeight: FontWeight.w500),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    textEditController: controller.roomLength,
                    hintText: AppStrings.hotelHintLength.tr,
                    keyBoardType: TextInputType.number,
                    regularExpression: r'[0-9]',
                    inputLength: 3,
                    onChange: (_) => controller.triggerValidation(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: CommonTextField(
                    textEditController: controller.roomWidth,
                    hintText: AppStrings.hotelHintWidth.tr,
                    keyBoardType: TextInputType.number,
                    regularExpression: r'[0-9]',
                    inputLength: 3,
                    onChange: (_) => controller.triggerValidation(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Obx(() => CommonDropdownDialog<BedType>(
                  title: AppStrings.hotelSelectBedType.tr,
                  hintText: AppStrings.hotelHintSingleBed.tr,
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
                  title: AppStrings.hotelMaximumOccupancy.tr,
                  hintText: AppStrings.hotelHintFamilyOccupancy.tr,
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
              title: AppStrings.hotelPricePerDay.tr,
              hintText: AppStrings.hotelHintPricePerDay.tr,
              keyBoardType: TextInputType.number,
              regularExpression: r'[0-9]',
              inputLength: 6,
              validationMessage: AppStrings.required.tr,
              onChange: (_) => controller.triggerValidation(),
            ),
            SizedBox(height: 12),
            Obx(() => Column(
                  children: [
                    if (controller.savedCoupons.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.savedCoupons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final coupon = controller.savedCoupons[index];
                          return _buildCouponItem(coupon, index);
                        },
                      ),
                    if (controller.savedCoupons.isEmpty)
                      InkWell(
                        onTap: () => showCouponModal(context),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              CustomText(
                                AppStrings.hotelDiscountCoupon.tr,
                                color: Colors.grey.shade600,
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    if (controller.savedCoupons.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => showCouponModal(context),
                          icon: const Icon(Icons.add),
                          label: CustomText(AppStrings.hotelAddMoreCoupon.tr),
                        ),
                      )
                  ],
                )),
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
                    "${AppStrings.hotelDiscountWorth.tr} ${isPercentage ? '' : '₹'}${data['offValue']}${isPercentage ? '%' : ''} ${AppStrings.hotelTcs.tr}",
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
              CustomText(isPercentage ? "%" : "₹",
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
    return Obx(() {
      bool isValid = controller.isFormValidRx.value;

      return CustomBtn(
        isValidate: isValid,
        title: AppStrings.next.tr,
        onTap: isValid
            ? () {
                Get.to(HotelImageUploadScreen(
                  roomName: roomName,
                  roomType: roomType,
                ));
              }
            : null,
      );
    });
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
                  CustomText(AppStrings.hotelDiscountCoupon.tr,
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
                title: AppStrings.hotelCouponName.tr,
                hintText: AppStrings.hotelHintCouponName.tr,
                textEditController: controller.couponName,
                inputLength: 30,
                onChange: (_) {
                  controller.isCouponValidMethod();
                },
              ),
              const SizedBox(height: 15),
              CommonTextField(
                title: AppStrings.hotelDescriptionTerms.tr,
                hintText: AppStrings.hotelHintLoremIpsum.tr,
                maxLine: 3,
                textEditController: controller.couponDesc,
                inputLength: 100,
                onChange: (_) {
                  controller.isCouponValidMethod();
                },
              ),
              const SizedBox(height: 15),
              CommonTextField(
                title: AppStrings.hotelCodeNameOptional.tr,
                hintText: AppStrings.hotelHintCouponCode.tr,
                textEditController: controller.couponCode,
                regularExpression: r'[a-zA-Z0-9]',
                inputLength: 12,
                onChange: (_) {
                  controller.isCouponValidMethod();
                  // controller.update();
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  CustomText(AppStrings.hotelTotalOff.tr,
                      fontWeight: FontWeight.w500),
                  const Spacer(),
                  Obx(() => _radioOption(controller, "In Rupees")),
                  Obx(() => _radioOption(controller, "In Percentage")),
                ],
              ),
              CommonTextField(
                hintText: AppStrings.hotelHintPercentageOff.tr,
                textEditController: controller.totalOff,
                keyBoardType: TextInputType.number,
                regularExpression: r'[0-9]',
                inputLength: 5,
                onChange: (_) {
                  controller.isCouponValidMethod();
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
                    title: AppStrings.save.tr,
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
  final String displayValue = value == "In Rupees"
      ? AppStrings.hotelInRupees.tr
      : value == "In Percentage"
          ? AppStrings.hotelInPercentage.tr
          : value;
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
      CustomText(displayValue, fontSize: 12),
    ],
  );
}
