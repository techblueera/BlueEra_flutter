import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_ratings_bottom_sheet.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable stats card for visiting any business profile.
/// Shows Views, Ratings, Followers, Following, and Joined date.
///
/// Usage:
/// ```dart
/// VisitBusinessStatsCard(details: businessProfileDetails);
/// ```
class VisitBusinessStatsCard extends StatelessWidget {
  final BusinessProfileDetails? details;

  const VisitBusinessStatsCard({super.key, this.details});

  String _formatCount(dynamic value) {
    if (value == null) return '0';
    final count =
        (value is String) ? (int.tryParse(value) ?? 0) : (value as num).toInt();
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '--';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '--';
    }
  }

  Widget _buildStat({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          '$label: ',
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? AppColors.mainTextColor),
          SizedBox(width: SizeConfig.size2),
        ],
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        if (onTap != null) ...[
          SizedBox(width: SizeConfig.size4),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 10, color: AppColors.secondaryTextColor),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _verticalDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: const VerticalDivider(
          color: AppColors.greyE5, thickness: 1, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      border: Border.all(color: AppColors.greyE5),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ─── Views + Ratings ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStat(
                    label: 'Views',
                    value: _formatCount(details?.total_views),
                  ),
                  SizedBox(height: SizeConfig.size8),
                  _buildStat(
                    label: 'Ratings',
                    value: _formatCount(details?.total_ratings),
                    icon: Icons.star_rounded,
                    iconColor: AppColors.orangelite,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BusinessRatingsBottomSheet(
                          businessId: details?.id ?? "",
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            _verticalDivider(),

            // ─── Followers + Following ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStat(
                    label: 'Followers',
                    value: _formatCount(details?.total_followers),
                    onTap: () {
                      Get.to(() => FollowersFollowingPage(
                            tabIndex: 1,
                            userID: details?.userId ?? "",
                          ));
                    },
                  ),
                  SizedBox(height: SizeConfig.size8),
                  _buildStat(
                    label: 'Following',
                    value: _formatCount(details?.total_following),
                    onTap: () {
                      Get.to(() => FollowersFollowingPage(
                            tabIndex: 0,
                            userID: details?.userId ?? "",
                          ));
                    },
                  ),
                ],
              ),
            ),

            _verticalDivider(),

            // ─── Joined ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    'Joined',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    _formatDate(details?.createdAt),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
