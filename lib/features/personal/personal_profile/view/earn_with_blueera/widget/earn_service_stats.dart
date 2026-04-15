import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Common stats card driven by [EarnProfileController].
///
/// Reads views / inquiries / followers / following / createdAt from the
/// controller's observable `earnProfile`.
class EarnServiceStats extends StatelessWidget {
  final EarnProfileController controller;

  const EarnServiceStats({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.earnProfile.value;
      return CustomFormCard(
        margin: const EdgeInsets.only(top: 10),
        padding: EdgeInsets.all(SizeConfig.size12),
        border: Border.all(color: AppColors.greyE5),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStat(
                        label: 'Views',
                        value: _formatCount(profile?.totalViews)),
                    SizedBox(height: SizeConfig.size8),
                    _buildStat(
                        label: 'Inquiries',
                        value: _formatCount(profile?.totalInquiries)),
                  ],
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStat(
                        label: 'Followers',
                        value: _formatCount(profile?.totalFollowers)),
                    SizedBox(height: SizeConfig.size8),
                    _buildStat(
                        label: 'Following',
                        value: _formatCount(profile?.totalFollowing)),
                  ],
                ),
              ),
              _verticalDivider(),
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
                      _formatDate(profile?.createdAt),
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
    });
  }

  String _formatCount(int? value) {
    final count = value ?? 0;
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
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

  Widget _buildStat({required String label, required String value}) {
    return Row(
      children: [
        CustomText(
          '$label: ',
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: VerticalDivider(
          color: AppColors.greyE5, thickness: 1, width: 1),
    );
  }
}
