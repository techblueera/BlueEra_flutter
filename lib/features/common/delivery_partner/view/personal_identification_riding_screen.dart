import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalIdentificationRidingScreen extends StatefulWidget {
  const PersonalIdentificationRidingScreen({super.key});

  @override
  State<PersonalIdentificationRidingScreen> createState() => _PersonalIdentificationRidingScreenState();
}

class _PersonalIdentificationRidingScreenState extends State<PersonalIdentificationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());
  final multipleImageSectionController = Get.put(CommonMultipleImageSectionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.personalIdentification,
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "${AppStrings.stepLabel.tr}3/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Form(
          key: controller.formKeyStep3,
          child: Obx(()=> AbsorbPointer(
            absorbing: controller.isRiderPersonalIdentificationLoading.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GetBuilder<DeliveryPartnerController>(
                  id: DeliveryPartnerController.livePhotoImageId,
                  builder: (ctrl) => CustomFormCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                AppStrings.uploadYourLivePhoto,
                                fontSize: SizeConfig.small,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: SizeConfig.size8),
                              child: CustomText(
                                  '${AppStrings.minLabel.tr}${controller.maxLiveUploadImages} ${AppStrings.images.tr}',
                                  // "Min-$minImages Images/Max-${maxImages}Images",
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w400
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final spacing = SizeConfig.size6;

                            // 4 items with equal width and gaps
                            final itemWidth = (availableWidth - (spacing * 5)) / 4;

                            return SizedBox(
                              height: itemWidth, // square images
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: controller.maxLiveUploadImages,
                                separatorBuilder: (_, __) => SizedBox(width: spacing),
                                itemBuilder: (context, index) {
                                  RxList<File> liveImages = controller.livePhoto;
                                  final hasImage = index < controller.livePhoto.length;

                                  return GestureDetector(
                                    onTap: () async {
                                      if (!hasImage) {
                                        controller.addLivePhoto();
                                      }
                                    },
                                    child: Container(
                                      width: itemWidth,
                                      height: itemWidth,
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteFE,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.greyE5),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (hasImage)
                                            Image.file(liveImages[index], fit: BoxFit.cover)
                                          else
                                            const Center(
                                              child: Icon(Icons.photo_outlined,
                                                  color: Colors.grey, size: 28),
                                            ),
                                          if (hasImage)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => controller.removeLivePhoto(index),
                                                child: Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close,
                                                      size: 14, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Aadhar
                        CommonTextField(
                          textEditController: controller.aadharController,
                          title: AppStrings.aadharNumber,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          titleColor: AppColors.mainTextColor,
                          hintText: AppStrings.eg23333,
                          keyBoardType: TextInputType.number,
                          validator: ValidationMethod.validateAadhaar,
                          maxLength: 12,
                        ),
                        SizedBox(height: SizeConfig.paddingM),
                        CustomText(
                          AppStrings.uploadAadharBothSide,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Row(
                          children: [
                            Expanded(
                              child: CommonImageUploadTile(
                                title: AppStrings.aadharFront,
                                imageFile: controller.aadharFrontImage,
                                context: context,
                                onImageSelected: () async {
                                  final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                                  if (selectedPath != null) {
                                    controller.aadharFrontImage.value = File(selectedPath);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child:
                              CommonImageUploadTile(
                                title: AppStrings.aadharBack,
                                imageFile: controller.aadharBackImage,
                                context: context,
                                onImageSelected: () async {
                                  final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                                  if (selectedPath != null) {
                                    controller.aadharBackImage.value = File(selectedPath);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                ),
                SizedBox(height: SizeConfig.paddingM),

                CustomFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Pan Number
                        CommonTextField(
                          textEditController: controller.panNumberController,
                          title: AppStrings.panNumber,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          titleColor: AppColors.mainTextColor,
                          hintText: AppStrings.egABCDE12,
                          keyBoardType: TextInputType.text,
                          validator: ValidationMethod.validatePAN,
                          isCapitalize: true,
                          maxLength: 10,
                        ),
                        SizedBox(height: SizeConfig.paddingM),
                        CustomText(
                          AppStrings.uploadPan,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CommonImageUploadTile(
                          title: AppStrings.uploadPan,
                          imageFile: controller.panCardImage,
                          context: context,
                          onImageSelected: () async {
                            final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                            if (selectedPath != null) {
                              controller.panCardImage.value = File(selectedPath);
                            }
                          },
                        ),
                      ],
                    )),

                SizedBox(height: SizeConfig.paddingL),
                CustomBtn(
                  title: controller.isRiderPersonalIdentificationLoading.value
                      ? null
                      : AppStrings.nextButton,
                  onTap: ()=> controller.ridersOnboardingPersonalIdentificationApi(),
                  radius: 10.0,
                  bgColor: AppColors.primaryColor,
                  isLoading: controller.isRiderPersonalIdentificationLoading.value,
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }



}
