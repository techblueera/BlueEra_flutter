import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/tiffin_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TiffinBottomSheet extends StatelessWidget {
  final bool isEdit;
  final TiffinController tiffinController = Get.find<TiffinController>();

  TiffinBottomSheet({super.key, required this.isEdit});

  static void show(BuildContext context, bool isEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      //  keyboard pushes sheet up
      useSafeArea: true,
      builder: (_) => TiffinBottomSheet(isEdit: isEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ keyboard height — shifts sheet up when keyboard opens
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return CommonDraggableBottomSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: keyboardHeight > 0 ? keyboardHeight : SizeConfig.size16,
              ),
              child: Column(
                children: [
                  // ─── Drag Handle ───
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                          top: SizeConfig.size10, bottom: SizeConfig.size6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greyE5,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // ─── Header ───
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                    child: Row(
                      children: [
                        // ✅ colored icon badge
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_outlined : Icons.add_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                isEdit ? 'Edit Meal' : 'Add New Meal',
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mainTextColor,
                              ),
                              CustomText(
                                isEdit
                                    ? 'Update your meal details'
                                    : 'Fill in the details to go live',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                        // ✅ close button
                        InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.greyE5.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close,
                                size: 16, color: AppColors.mainTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: AppColors.greyE5, height: 1),
                  SizedBox(height: SizeConfig.size12),

                  // ─── Scrollable Form ───
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: tiffinController.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Image Upload ───
                            _buildSectionLabel(
                                'Meal Photo', Icons.image_outlined),
                            SizedBox(height: SizeConfig.size8),
                            _buildImageUploader(),

                            SizedBox(height: SizeConfig.size20),

                            // ─── Tiffin Name ───
                            _buildSectionLabel(
                                'Meal Name', Icons.restaurant_menu_outlined),
                            SizedBox(height: SizeConfig.size8),
                            CommonTextField(
                              hintText: 'E.g. 2 Idli + Sambar + Chutney',
                              isValidate: true,
                              maxLength: 50,
                              textEditController:
                                  tiffinController.tiffinNameController,
                              isCounterVisible: true,
                              onChange: (text) {},
                            ),

                            SizedBox(height: SizeConfig.size20),

                            // ─── Food Type & Cooking Method ───
                            _buildSectionLabel(
                                'Food Details', Icons.category_outlined),
                            SizedBox(height: SizeConfig.size8),
                            Obx(() => Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            'Food Type',
                                            fontSize: SizeConfig.medium,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.mainTextColor,
                                          ),
                                          SizedBox(height: 8.0),
                                          CommonDropdownDialog<String>(
                                            items: tiffinController.foodTypeList,
                                            selectedValue: tiffinController
                                                    .selectedFoodType.value.isEmpty
                                                ? null
                                                : tiffinController
                                                    .selectedFoodType.value,
                                            title: 'Food Type',
                                            hintText: 'E.g. Veg',
                                            displayValue: (value) => value,
                                            onChanged: (value) {
                                              tiffinController.selectedFoodType
                                                  .value = value ?? '';
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: SizeConfig.size12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            'Cooking Method',
                                            fontSize: SizeConfig.medium,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.mainTextColor,
                                          ),
                                          SizedBox(height: 8.0),
                                          CommonDropdownDialog<String>(
                                            items:
                                                tiffinController.cookingMethodList,
                                            selectedValue: tiffinController
                                                    .selectedCookingMethod
                                                    .value
                                                    .isEmpty
                                                ? null
                                                : tiffinController
                                                    .selectedCookingMethod.value,
                                            title: 'Cooking Method',
                                            hintText: 'E.g. Boiled',
                                            displayValue: (value) => value,
                                            onChanged: (value) {
                                              tiffinController.selectedCookingMethod
                                                  .value = value ?? '';
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),

                            SizedBox(height: SizeConfig.size20),

                            // ─── Price Section ───
                            _buildSectionLabel(
                                'Pricing', Icons.currency_rupee_rounded),
                            SizedBox(height: SizeConfig.size8),
                            Row(
                              children: [
                                Expanded(
                                  child: CommonTextField(
                                    title: 'MRP Price',
                                    hintText: '₹200',
                                    validator: ValidationMethod().validateMRP,
                                    keyBoardType: TextInputType.number,
                                    textEditController:
                                        tiffinController.mrpPriceController,
                                    onChange: (text) {},
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size12),
                                Expanded(
                                  child: CommonTextField(
                                    title: 'Selling Price',
                                    hintText: '₹159',
                                    validator: (value) =>
                                        ValidationMethod().validatePrice(
                                      tiffinController
                                          .sellingPriceController.text,
                                      tiffinController.mrpPriceController.text,
                                    ),
                                    keyBoardType: TextInputType.number,
                                    textEditController:
                                        tiffinController.sellingPriceController,
                                    onChange: (text) {},
                                  ),
                                ),
                              ],
                            ),

                            // discount preview
                            Builder(
                              builder: (context) {
                                final mrp = double.tryParse(tiffinController
                                        .mrpPriceController.text) ??
                                    0;
                                final selling = double.tryParse(tiffinController
                                        .sellingPriceController.text) ??
                                    0;
                                if (mrp <= 0 || selling <= 0 || selling >= mrp)
                                  return const SizedBox.shrink();
                                final discount = ((mrp - selling) / mrp * 100)
                                    .toStringAsFixed(0);
                                return Padding(
                                  padding:
                                      EdgeInsets.only(top: SizeConfig.size8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.size10,
                                        vertical: SizeConfig.size6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_offer_outlined,
                                            size: 14, color: Colors.green),
                                        SizedBox(width: SizeConfig.size4),
                                        CustomText(
                                          '$discount% discount applied',
                                          fontSize: SizeConfig.small,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: SizeConfig.size20),

                            // ─── Serving Time ───
                            _buildSectionLabel(
                                'Serving Time', Icons.access_time_rounded),
                            SizedBox(height: SizeConfig.size8),
                            Obx(() => Row(
                              children: [
                                Expanded(
                                  child: CommonDropdownDialog<String>(
                                    items: tiffinController.startTimeList,
                                    selectedValue: tiffinController
                                        .selectedStartTime
                                        .value
                                        .isEmpty
                                        ? null
                                        : tiffinController
                                        .selectedStartTime.value,
                                    title: 'Start Time',
                                    hintText: '7:00 AM',
                                    displayValue: (value) => value,
                                    onChanged: (value) {
                                      tiffinController.selectedStartTime
                                          .value = value ?? '';
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    'to',
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: CommonDropdownDialog<String>(
                                    items: tiffinController.endTimeList,
                                    selectedValue: tiffinController
                                        .selectedEndTime.value.isEmpty
                                        ? null
                                        : tiffinController
                                        .selectedEndTime.value,
                                    title: 'End Time',
                                    hintText: '2:00 PM',
                                    displayValue: (value) => value,
                                    onChanged: (value) {
                                      tiffinController.selectedEndTime
                                          .value = value ?? '';
                                    },
                                  ),
                                ),
                              ],
                            )),

                            SizedBox(height: SizeConfig.size24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Go Live Button ───
                  Obx(() => CustomBtn(
                        height: SizeConfig.size48,
                        title: tiffinController.isSubmitting.value
                            ? null
                            : (isEdit ? 'Update Meal' : 'Go Live'),
                        onTap: tiffinController.onGoLive,
                        bgColor: AppColors.primaryColor,
                        radius: 12,
                        isLoading: tiffinController.isSubmitting.value,
                      )),

                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Section Label ───
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        SizedBox(width: SizeConfig.size6),
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  // ─── Image Uploader ───
  Widget _buildImageUploader() {
    return Obx(() {
      final file     = tiffinController.tiffinImageFile.value;
      final imageUrl = tiffinController.mealData[tiffinController.currentEditType.value]
          ?.value.imageUrl;

      // ✅ has local file OR network url
      final hasImage = file != null || (imageUrl != null && imageUrl.isNotEmpty);

      return GestureDetector(
        onTap: () {
          if (file != null) {
            // ✅ view local file
            Get.to(() => ImageViewScreen(
              appBarTitle: 'Tiffin Image',
              imageUrls:   [file.path],
              initialIndex: 0,
            ));
          } else if (imageUrl != null && imageUrl.isNotEmpty) {
            // ✅ view network image
            Get.to(() => ImageViewScreen(
              appBarTitle: 'Tiffin Image',
              imageUrls:   [imageUrl],
              initialIndex: 0,
            ));
          } else {
            tiffinController.pickImage();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:        hasImage ? Colors.transparent : AppColors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: hasImage
                  ? AppColors.primaryColor.withValues(alpha: 0.4)
                  : AppColors.greyE5,
              width: hasImage ? 1.5 : 1.0,
            ),
            boxShadow: [AppShadows.textFieldShadow],
          ),
          child: hasImage
          // ─── Image Preview (file or network) ───
              ? SizedBox(
            height: SizeConfig.size150,
            child: Stack(
              children: [
                // ✅ local file takes priority over network url
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: file != null
                      ? Image.file(
                    file,
                    fit:   BoxFit.cover,
                    width: double.infinity,
                    height: SizeConfig.size150,
                  )
                      : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit:      BoxFit.cover,
                    width:    double.infinity,
                    height:   SizeConfig.size150,
                    placeholder: (_, __) => Container(
                      color: AppColors.greyE5,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.greyE5,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.secondaryTextColor,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // ✅ gradient overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end:   Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ "Tap to change" label
                Positioned(
                  bottom: 8, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: tiffinController.pickImage, // ✅ always pick new image
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size10,
                          vertical:   SizeConfig.size4,
                        ),
                        decoration: BoxDecoration(
                          color:        Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, size: 12, color: Colors.white),
                            SizedBox(width: SizeConfig.size4),
                            const CustomText(
                              'Tap to change',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ source badge — shows if image is from network or local
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size6,
                      vertical:   SizeConfig.size2,
                    ),
                    decoration: BoxDecoration(
                      color:        Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          file != null ? Icons.smartphone : Icons.cloud_done_outlined,
                          size: 10, color: Colors.white,
                        ),
                        SizedBox(width: SizeConfig.size2),
                        CustomText(
                          file != null ? 'New' : 'Saved',
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ remove button
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      tiffinController.tiffinImageFile.value = null;
                      // ✅ if it was a local file, revert to network url (don't clear url)
                    },
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                        color:  Colors.black54,
                        shape:  BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )

          // ─── Empty State ───
              : Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.documentUploadIcon,
                  imgColor:  AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size10),
                CustomText(
                  'Upload',
                  fontSize:   SizeConfig.medium,
                  color:      AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
