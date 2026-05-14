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
import 'package:get/get.dart';

/// Discount-coupon type values. These match the literals
/// [RoomDetailController.isCouponValidMethod] inspects, so changing either
/// side requires changing both.
const String _offTypePercentage = 'In Percentage';
const String _offTypeRupees = 'In Rupees';

/// Step-1-of-2 room creation form: room dimensions, bed/occupancy, price,
/// and an optional coupon list. "Next" advances to the image upload screen.
class RoomDesignScreen extends StatelessWidget {
  final String roomType;
  final String roomName;

  RoomDesignScreen({super.key, required this.roomType, required this.roomName});

  final controller = Get.put(RoomDetailController());

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRoomMetadataCard(),
              const SizedBox(height: 16),
              _buildPriceAndCouponsCard(context),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Card 1: dimensions / bed / occupancy ---------------------------------

  Widget _buildRoomMetadataCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _numericField(
              textEditController: controller.totalRoomsTotal,
              title: AppStrings.hotelTotalRooms.tr,
              hintText: AppStrings.hotelHintTotalRooms.tr,
              inputLength: 3,
              validationMessage: AppStrings.required.tr,
            ),
            const SizedBox(height: 12),
            CustomText(AppStrings.hotelRoomSize.tr,
                fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numericField(
                    textEditController: controller.roomLength,
                    hintText: AppStrings.hotelHintLength.tr,
                    inputLength: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numericField(
                    textEditController: controller.roomWidth,
                    hintText: AppStrings.hotelHintWidth.tr,
                    inputLength: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBedTypeDropdown(),
            const SizedBox(height: 12),
            _buildOccupancyDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildBedTypeDropdown() {
    return Obx(() => CommonDropdownDialog<BedType>(
          title: AppStrings.hotelSelectBedType.tr,
          hintText: AppStrings.hotelHintSingleBed.tr,
          items: controller.bedTypeList,
          selectedValue: controller.selectedBedType.value,
          displayValue: (bed) => bed.name,
          onChanged: (value) {
            controller.onBedTypeChanged(value);
            controller.triggerValidation();
          },
        ));
  }

  Widget _buildOccupancyDropdown() {
    return Obx(() => CommonDropdownDialog<OccupancyType>(
          title: AppStrings.hotelMaximumOccupancy.tr,
          hintText: AppStrings.hotelHintFamilyOccupancy.tr,
          items: controller.occupancyList,
          selectedValue: controller.selectedOccupancy.value,
          displayValue: (occ) => occ.name,
          onChanged: controller.onOccupancyChanged,
        ));
  }

  // ---- Card 2: price + coupons ----------------------------------------------

  Widget _buildPriceAndCouponsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _numericField(
              textEditController: controller.pricePerDay,
              title: AppStrings.hotelPricePerDay.tr,
              hintText: AppStrings.hotelHintPricePerDay.tr,
              inputLength: 6,
              validationMessage: AppStrings.required.tr,
            ),
            const SizedBox(height: 12),
            Obx(() => _buildCouponSection(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context) {
    final coupons = controller.savedCoupons;
    if (coupons.isEmpty) {
      return _buildAddCouponPlaceholder(context);
    }
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coupons.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _buildCouponItem(coupons[index], index),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showCouponModal(context),
            icon: const Icon(Icons.add),
            label: CustomText(AppStrings.hotelAddMoreCoupon.tr),
          ),
        ),
      ],
    );
  }

  Widget _buildAddCouponPlaceholder(BuildContext context) {
    return InkWell(
      onTap: () => _showCouponModal(context),
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
    );
  }

  Widget _buildCouponItem(Map<String, String> data, int index) {
    final isPercentage = data['offType'] == _offTypePercentage;
    final offValue = data['offValue'] ?? '';
    final unit = isPercentage ? '%' : '';
    final pricePrefix = isPercentage ? '' : '₹';

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
                CustomText(
                  '${AppStrings.hotelDiscountWorth.tr} $pricePrefix$offValue$unit ${AppStrings.hotelTcs.tr}',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                const SizedBox(height: 4),
                CustomText(
                  data['desc'] ?? '',
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomText(
                          data['code'] ?? '',
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomText(
                      '$offValue$unit ${AppStrings.off.tr}',
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CouponIconBadge(isPercentage: isPercentage),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => controller.removeCoupon(index),
          ),
        ],
      ),
    );
  }

  // ---- Submit button --------------------------------------------------------

  Widget _buildSubmitButton() {
    return Obx(() {
      final isValid = controller.isFormValidRx.value;
      return CustomBtn(
        isValidate: isValid,
        title: AppStrings.next.tr,
        onTap: isValid
            ? () => Get.to(HotelImageUploadScreen(
                  roomName: roomName,
                  roomType: roomType,
                ))
            : null,
      );
    });
  }

  // ---- Coupon modal ---------------------------------------------------------

  void _showCouponModal(BuildContext context) {
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
                    CustomText(
                      AppStrings.hotelDiscountCoupon.tr,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    InkWell(
                      onTap: Get.back,
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CommonTextField(
                  title: AppStrings.hotelCouponName.tr,
                  hintText: AppStrings.hotelHintCouponName.tr,
                  textEditController: controller.couponName,
                  inputLength: 30,
                  onChange: (_) => controller.isCouponValidMethod(),
                ),
                const SizedBox(height: 15),
                CommonTextField(
                  title: AppStrings.hotelDescriptionTerms.tr,
                  hintText: AppStrings.hotelHintLoremIpsum.tr,
                  maxLine: 3,
                  textEditController: controller.couponDesc,
                  inputLength: 100,
                  onChange: (_) => controller.isCouponValidMethod(),
                ),
                const SizedBox(height: 15),
                CommonTextField(
                  title: AppStrings.hotelCodeNameOptional.tr,
                  hintText: AppStrings.hotelHintCouponCode.tr,
                  textEditController: controller.couponCode,
                  regularExpression: r'[a-zA-Z0-9]',
                  inputLength: 12,
                  onChange: (_) => controller.isCouponValidMethod(),
                ),
                const SizedBox(height: 15),
                _buildOffTypeRadioGroup(),
                CommonTextField(
                  hintText: AppStrings.hotelHintPercentageOff.tr,
                  textEditController: controller.totalOff,
                  keyBoardType: TextInputType.number,
                  regularExpression: r'[0-9]',
                  inputLength: 5,
                  onChange: (_) => controller.isCouponValidMethod(),
                ),
                const SizedBox(height: 20),
                _buildModalSaveButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOffTypeRadioGroup() {
    return Obx(() => RadioGroup<String>(
          groupValue: controller.offType.value,
          onChanged: (val) {
            if (val != null) {
              controller.offType.value = val;
              controller.isCouponValidMethod();
            }
          },
          child: Row(
            children: [
              CustomText(AppStrings.hotelTotalOff.tr,
                  fontWeight: FontWeight.w500),
              const Spacer(),
              _radioOption(_offTypeRupees, AppStrings.hotelInRupees.tr),
              _radioOption(_offTypePercentage, AppStrings.hotelInPercentage.tr),
            ],
          ),
        ));
  }

  Widget _buildModalSaveButton() {
    return Obx(() => CustomBtn(
          onTap: controller.isCouponValid.value
              ? () {
                  controller.addCoupon();
                  Get.back();
                }
              : null,
          title: AppStrings.save.tr,
          isValidate: controller.isCouponValid.value,
        ));
  }

  // ---- Tiny shared helpers --------------------------------------------------

  Widget _numericField({
    required TextEditingController textEditController,
    required String hintText,
    String? title,
    int? inputLength,
    String? validationMessage,
  }) {
    return CommonTextField(
      textEditController: textEditController,
      title: title,
      hintText: hintText,
      keyBoardType: TextInputType.number,
      regularExpression: r'[0-9]',
      inputLength: inputLength,
      validationMessage: validationMessage,
      onChange: (_) => controller.triggerValidation(),
    );
  }

  Widget _radioOption(String value, String label) {
    return Row(
      children: [
        Radio<String>(value: value),
        CustomText(label, fontSize: 12),
      ],
    );
  }
}

/// The circular "%" or "₹" badge shown to the right of a coupon row.
class _CouponIconBadge extends StatelessWidget {
  final bool isPercentage;
  const _CouponIconBadge({required this.isPercentage});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
          isPercentage ? '%' : '₹',
          color: Colors.brown.shade700,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}
