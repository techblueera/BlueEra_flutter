import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_store_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_discover_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChooseHomeMadeFoodOptionDialog extends StatelessWidget {
  const ChooseHomeMadeFoodOptionDialog({super.key});

  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _primaryDeep = AppColors.blue5CAF; // 0xFF005CAF
  static const Color _warm = Color(0xFFFB8C00); // amber 600
  static const Color _warmDeep = Color(0xFFEF6C00); // amber 800

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Explore Home Made Food',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(height: 3),
                      CustomText(
                        'Choose how you want to browse',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                _closeButton(),
              ],
            ),
            const SizedBox(height: 18),
            _buildOption(
              icon: Icons.storefront_rounded,
              gradient: const [_primary, _primaryDeep],
              title: 'Search Via Store',
              subtitle: 'Browse nearby home made food kitchens',
              onTap: () {
                Get.back();
                Get.to(() => const HomeMadeFoodStoreDiscoverScreen());
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.grid_view_rounded,
              gradient: const [_warm, _warmDeep],
              title: 'Search Via Category',
              subtitle: 'Explore tiffin & food items by category',
              onTap: () {
                Get.back();
                Get.to(() => const HomeMadeFoodDiscoverScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeButton() {
    return InkWell(
      onTap: () => Get.back(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.greyE5.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded,
            size: 16, color: AppColors.secondaryTextColor),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greyE5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 3),
                    CustomText(
                      subtitle,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
