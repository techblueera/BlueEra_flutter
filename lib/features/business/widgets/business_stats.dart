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
import 'package:BlueEra/features/business/widgets/business_common_gallery_card.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/food_service_gallery/food_service_photos_screen.dart';
import 'package:BlueEra/features/me/food/view/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/food_home_profile_header.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class BusinessStats extends StatelessWidget {
  final BusinessProfileDetails? details;

  const BusinessStats({super.key, this.details});

  String _formatCount(dynamic value) {
    if (value == null) return '0';
    final count = (value is String) ? (int.tryParse(value) ?? 0) : (value as num).toInt();
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
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

  Widget _buildStat({required String label, required String value, IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        CustomText('$label: ', fontSize: SizeConfig.small, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? AppColors.mainTextColor),
          SizedBox(width: SizeConfig.size2),
        ],
        CustomText(value, fontSize: SizeConfig.small, fontWeight: FontWeight.w700, color: AppColors.mainTextColor),
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
    return CustomFormCard(
      margin: EdgeInsets.only(top: 10),
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
                  _buildStat(label: 'Views', value: _formatCount(details?.total_views)),
                  SizedBox(height: SizeConfig.size8),
                  _buildStat(label: 'Inquiries', value: _formatCount('25')),
                ],
              ),
            ),

            _verticalDivider(),

            // ─── Inquiries + Followers ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStat(label: 'Followers', value: _formatCount(details?.total_followers)),
                  SizedBox(height: SizeConfig.size8),
                  _buildStat(label: 'Following', value: _formatCount(details?.total_following)),
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
                  CustomText('Joined', fontSize: SizeConfig.small, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(_formatDate(details?.createdAt), fontSize: SizeConfig.small, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}