import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarnServiceCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const EarnServiceCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  EarnServiceController get _controller =>
      getOrPut(() => EarnServiceController());

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
              child: Column(
                children: [
                  _optionChip(
                    context: context,
                    icon: Icons.restaurant_rounded,
                    label: 'Home Made Food',
                    slugId: HOME_MADE_FOOD,
                    profileType: 'homeMadeFood',
                    accentColor: const Color(0xFFE8590C),
                    bgColor: const Color(0xFFFFF1E9),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _optionChip(
                    context: context,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Home Made Product',
                    slugId: HOME_MADE_PRODUCTS,
                    profileType: 'homeMadeProduct',
                    accentColor: const Color(0xFF0086FF),
                    bgColor: const Color(0xFFEBF5FF),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _optionChip(
                    context: context,
                    icon: Icons.home_repair_service_rounded,
                    label: 'Home Service',
                    slugId: HOME_SERVICES,
                    profileType: 'homeService',
                    accentColor: const Color(0xFF00B87A),
                    bgColor: const Color(0xFFE6FAF3),
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
    return Padding(
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
              Icons.work_outline_rounded,
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
                  AppStrings.earnWithBlueEra.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  'Start earning from home',
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
    );
  }

  Widget _optionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String slugId,
    required String profileType,
    required Color accentColor,
    required Color bgColor,
  }) {
    final radius = BorderRadius.circular(12);
    return InkWell(
      onTap: () {
        final viewProfileController = Get.find<ViewPersonalDetailsController>();
        final earnType =
            (viewProfileController.earnProfileType.value ?? '').trim();
        debugPrint('earn profile type -- $earnType');
        // Open the dashboard only when the user's existing earn profile is of
        // the SAME type as the tapped option; otherwise route to that option's
        // create flow.
        if (earnType == profileType) {
          Get.toNamed(RouteHelper.getEarnServiceDashboardViewRoute());
        } else {
          _controller.handleServiceTap(
            context,
            CollapsibleGridModel(name: label, slugId: slugId, icon: ''),
          );
        }
      },
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
