import 'package:BlueEra/core/constants/app_colors.dart';
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
      backgroundColor: kRentalScreenBg,
      appBar: CommonBackAppBar(title: 'Complete Your Listing'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RentalFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Upload Your Work Photo',
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
                          label: 'Take A Picture',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _UploadTile(
                          icon: Icons.folder_outlined,
                          label: 'Folders',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const RentalFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RentalLabeledField(
                          label: 'Price From',
                          hint: 'E.g. ₹40,660',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: RentalLabeledField(
                          label: 'Price TO',
                          hint: 'E.g. ₹60,660',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  RentalLabeledField(
                    label: 'Location',
                    hint: 'E.g. Lucknow Utter Pradesh noida',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: RentalPrimaryButton(
            label: 'Post Now',
            onTap: () {
              Get.snackbar(
                'Listing Posted',
                'Your project listing has been submitted.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primaryColor,
                colorText: Colors.white,
                margin: const EdgeInsets.all(14),
              );
              Get.close(3);
            },
          ),
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
