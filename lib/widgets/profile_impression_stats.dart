import 'dart:math';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ProfileImpressionStats extends StatefulWidget {
final double? cardMargin;
  ProfileImpressionStats({super.key, this.cardMargin, });

  @override
  State<ProfileImpressionStats> createState() => _ProfileImpressionStatsState();
}

class _ProfileImpressionStatsState extends State<ProfileImpressionStats> {
  final viewBusinessDetailsController = Get.find<
      ViewBusinessDetailsController>();

  BusinessProfileDetails? data;

  String _formatCount(dynamic value) {
    if (value == null) return '0';
    final count = (value is String)
        ? (int.tryParse(value) ?? 0)
        : (value as num).toInt();
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000)
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
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

  Widget _buildStat(
      {required String label, required String value, IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        CustomText('${label.tr}: ', fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor),
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? AppColors.mainTextColor),
          SizedBox(width: SizeConfig.size2),
        ],
        CustomText(value, fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      ],
    );
  }

  Widget _verticalDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: VerticalDivider(color: AppColors.greyE5, thickness: 1, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      data = viewBusinessDetailsController.businessProfileDetails.value?.data;

      return CustomFormCard(
        margin: EdgeInsets.symmetric(horizontal: widget.cardMargin??SizeConfig.size8),
        padding: EdgeInsets.all(SizeConfig.size12),
        border: Border.all(color: AppColors.greyE5),
        child: IntrinsicHeight(
          child: Row(
            children: [

              // ─── Rating + Views ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStat(
                        label: AppStrings.viewsLabel, value: _formatCount(data?.total_views)),
                    SizedBox(height: SizeConfig.size8),
                    _buildStat(label: AppStrings.inquiries, value: _formatCount('25')),
                  ],
                ),
              ),

              _verticalDivider(),

              // ─── Inquiries + Followers ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStat(label: AppStrings.followers,
                        value: _formatCount(data?.total_followers)),
                    SizedBox(height: SizeConfig.size8),
                    _buildStat(label: AppStrings.followingLabel,
                        value: _formatCount(data?.total_following)),
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
                    CustomText(AppStrings.joined, fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    SizedBox(height: SizeConfig.size4),
                    CustomText(_formatDate(data?.createdAt),
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor),
                  ],
                ),
              ),

            ],
          ),
        ),
      );
    });
  }
}