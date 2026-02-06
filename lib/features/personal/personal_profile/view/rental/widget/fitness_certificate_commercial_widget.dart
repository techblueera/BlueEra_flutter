import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/vehicle_rental_service_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FitnessCertificateCommercialWidget extends StatelessWidget {
  FitnessCertificateCommercialWidget({super.key});

  final controller = Get.find<VehicleRentalServiceController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.fitnessCertificateCommercial,
              fontSize: SizeConfig.small,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(height: SizeConfig.size8),
            CommonImageUploadTile(
              title: AppStrings.fitnessCertificateCommercial,
              imageFile: controller.vehicleFitnessCertificateImage,
              context: context,
              onImageSelected: () async {
                final selectedPath = await CommonImageUploadTile.pickImage(context: context);
                if (selectedPath != null) {
                  controller.vehicleFitnessCertificateImage.value = File(selectedPath);
                }
              },
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomBtn(
              title: controller.isUploadImagesLoading.value
                  ? null
                  : AppStrings.upload,
              isLoading: controller.isUploadImagesLoading.value,
              onTap: () {
                if (controller.vehicleFitnessCertificateImage.value == null) {
                  commonSnackBar(message: AppStrings.pleaseSelectFitnessCertImage.tr);
                  return;
                }

                controller.uploadVehicleDocImagesApi(
                    frontImage: controller.vehicleFitnessCertificateImage.value!,
                    sectionId: VehicleRentalServiceController.fitness
                );
              },
              radius: 10.0,
              bgColor: AppColors.primaryColor,
            ),
            // SizedBox(height: SizeConfig.paddingM),
          ],
        ));
  }
}
