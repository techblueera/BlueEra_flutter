import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/rental/view/rental_services_dashboard_screen_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalPropertyCardV2 extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const RentalPropertyCardV2({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size14,
                0,
                SizeConfig.size14,
                SizeConfig.size14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _optionChip(
                      icon: Icons.sell_rounded,
                      label: 'For Sale',
                      accentColor: const Color(0xFF0086FF),
                      bgColor: const Color(0xFFEBF5FF),
                      onTap: () => Get.to(
                          () => const RentalServicesDashboardScreenV2()),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: _optionChip(
                      icon: Icons.vpn_key_rounded,
                      label: 'For Rent',
                      accentColor: const Color(0xFF00B87A),
                      bgColor: const Color(0xFFE6FAF3),
                      onTap: () => Get.to(
                          () => const RentalServicesDashboardScreenV2()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () =>
          Get.to(() => const RentalServicesDashboardScreenV2()),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      splashColor: AppColors.primaryColor.withValues(alpha: 0.08),
      highlightColor: AppColors.primaryColor.withValues(alpha: 0.04),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.80),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.holiday_village_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Property Listing',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    'List your property for sale or rent',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionChip({
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(12);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      splashColor: accentColor.withValues(alpha: 0.12),
      highlightColor: accentColor.withValues(alpha: 0.06),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                label,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
