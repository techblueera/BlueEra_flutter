import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 3 — photo uploads (camera / folder picker — both no-ops in
/// this static demo) plus price + location. Tapping "Post Now" pops
/// back to wherever the flow was launched from (the v2 dashboard).
class CompleteYourListingScreen extends StatelessWidget {
  const CompleteYourListingScreen({super.key});

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
                  RentalLabeledField(
                    label: 'Price',
                    hint: 'E.g. ₹40,660',
                    keyboardType: TextInputType.number,
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
              // Static demo: confirm + drop the user back at the
              // dashboard (pops all three steps off the navigator).
              Get.snackbar(
                'Listing Posted',
                'Your property listing has been submitted.',
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

/// Dashed-border square tile used for the two photo upload entry
/// points. The fill is a pale primary tint; the dashes are drawn by
/// [DashedRRectBorder] sitting in a Stack above the fill.
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
                  color: CompleteYourListingScreen._uploadFill,
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
