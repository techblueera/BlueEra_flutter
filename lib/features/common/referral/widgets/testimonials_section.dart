import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/all_testimonials_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonial_video_grid.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';

class TestimonialsSection extends StatelessWidget {
  final ReferralController controller;

  // 2×2 preview grid on the referral home; the rest live behind "View All".
  static const int _kHomeGridCount = 4;

  const TestimonialsSection({
    super.key,
    required this.controller,
  });

  void _openAll() {
    Get.to(() => AllTestimonialsScreen(controller: controller));
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size12),
            child: _body(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size10,
        SizeConfig.size10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: CustomText(
              AppStrings.testimonials.tr,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          InkWell(
            onTap: _openAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: CustomText(
                AppStrings.viewAll.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Obx(() {
      final status = controller.testimonialsResponse.value.status;
      if (status == Status.LOADING || status == Status.INITIAL) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // Only video testimonials, shown as a 2×2 autoplay grid (like the
      // social "bites" grid). Non-video testimonials are surfaced via "View All".
      final videos =
          controller.testimonials.where((t) => t.hasVideo).toList();
      if (videos.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Center(
            child: CustomText(
              'No testimonials yet.',
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
            ),
          ),
        );
      }

      final preview = videos.take(_kHomeGridCount).toList();
      return TestimonialVideoGrid(videos: preview);
    });
  }
}
