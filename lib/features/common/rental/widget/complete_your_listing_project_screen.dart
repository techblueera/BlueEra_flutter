import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 3 — "new projects" variant. Same photo upload card as the
/// houses step 3, but the single Price field is replaced by a
/// Price From / Price To range row to capture pre-construction
/// pricing bands.
class CompleteYourListingProjectScreen extends StatelessWidget {
  const CompleteYourListingProjectScreen({super.key});

  static const Color _uploadFill = Color(0xFFE9F0FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.completeYourListing.tr),
      body: Column(
        children: [
          const RentalStepProgressBar(progress: 1.0),
          Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RentalFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.uploadYourWorkPhoto.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _UploadTile(
                          icon: Icons.camera_alt_outlined,
                          label: AppStrings.takeAPicture.tr,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _UploadTile(
                          icon: Icons.folder_outlined,
                          label: AppStrings.foldersLabel.tr,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RentalFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RentalLabeledField(
                          label: AppStrings.priceFromLabel.tr,
                          hint: AppStrings.egRupees40660.tr,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RentalLabeledField(
                          label: AppStrings.priceToFieldLabel.tr,
                          hint: AppStrings.egRupees60660.tr,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RentalLabeledField(
                    label: AppStrings.locationFieldLabel.tr,
                    hint: AppStrings.egLucknowUtterPradeshNoida.tr,
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
        ],
      ),
      bottomNavigationBar: RentalBottomBar(
        child: RentalPrimaryButton(
          label: AppStrings.postNow.tr,
          onTap: () {
            Get.snackbar(
              AppStrings.listingPosted.tr,
              AppStrings.yourProjectListingSubmitted.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primaryColor,
              colorText: Colors.white,
              margin: const EdgeInsets.all(14),
            );
            Get.close(3);
          },
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return SizedBox(
      height: 130,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
          highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CompleteYourListingProjectScreen._uploadFill,
                  borderRadius: radius,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: DashedRRectBorder(
                    color: AppColors.primaryColor.withValues(alpha: 0.55),
                    radius: 12,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: AppColors.primaryColor.withValues(alpha: 0.8),
                        size: 30),
                    const SizedBox(height: 8),
                    CustomText(
                      label,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
