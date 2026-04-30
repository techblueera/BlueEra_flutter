import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AddMedicalProductsScreen extends StatefulWidget {
  const AddMedicalProductsScreen({super.key});

  @override
  State<AddMedicalProductsScreen> createState() =>
      _AddMedicalProductsScreenState();
}

class _AddMedicalProductsScreenState extends State<AddMedicalProductsScreen> {
  final _medicalController = getOrPut(() => MedicalController());

  Future<void> _pickAndSnapSearch() async {
    try {
      final paths = await SelectProductImageDialog.showLogoDialog(
        context,
        AppStrings.medicalUploadProductPhotos.tr,
        isOnlyCamera: true,
        isGallery: true,
        maxImages: 5,
      );
      if (paths == null || paths.isEmpty) return;
      await _medicalController.snapSearch(imagePaths: paths);
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.medicalAddProductsTitle.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bulk Upload Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(SizeConfig.size15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyE5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.medicalUploadProductPhotos,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: 4),
                  CustomText(
                    AppStrings.medicalUploadProductPhotosHelper,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  Obx(() => _medicalController.isSnapSearchLoading.value
                      ? SizedBox(
                          height: 120,
                          child:
                              Center(child: CircularProgressIndicator()),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _uploadOptionCard(
                                icon: Icons.camera_alt_outlined,
                                title: AppStrings.medicalTakePhoto.tr,
                                subtitle: AppStrings.medicalTakePhotoSubtitle.tr,
                                color: AppColors.primaryColor,
                                onTap: _pickAndSnapSearch,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Expanded(
                              child: _uploadOptionCard(
                                icon: Icons.photo_library_outlined,
                                title: AppStrings.medicalUploadList.tr,
                                subtitle: AppStrings.medicalUploadListSubtitle.tr,
                                color: AppColors.green00,
                                onTap: _pickAndSnapSearch,
                              ),
                            ),
                          ],
                        )),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.size15),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.greyE5)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomText(AppStrings.medicalOr,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600),
                ),
                Expanded(child: Divider(color: AppColors.greyE5)),
              ],
            ),

            SizedBox(height: SizeConfig.size15),

            // Browse Categories
            InkWell(
              onTap: () =>
                  Get.toNamed(RouteHelper.getMedicalCategoryScreenRoute()),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.size15),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.category_outlined,
                          color: AppColors.primaryColor, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.medicalBrowseCategories,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: 2),
                          CustomText(
                            AppStrings.medicalBrowseCategoriesSubtitle,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.secondaryTextColor, size: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 10),
            CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: 2),
            CustomText(
              subtitle,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
