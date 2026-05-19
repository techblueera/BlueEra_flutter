import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral_new/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral_new/view/all_testimonials_screen.dart';
import 'package:BlueEra/features/common/referral_new/widgets/testimonial_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Testimonials  •  View All" section.
///
/// The whole block — header, divider, horizontal carousel — sits inside
/// a single [CustomFormCard] so it reads as one self-contained card on
/// the page. The carousel renders the first [_kHomeLimit] entries and
/// hands the rest off to a dedicated paginated page via "View All".
class TestimonialsSection extends StatelessWidget {
  final ReferralControllerNew controller;

  static const int _kHomeLimit = 10;

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
          Container(height: 1, color: const Color(0xFFEEF1F8)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.format_quote_rounded,
                size: 16, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 10),
          CustomText(
            'Testimonials',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(width: 6),
          Obx(() {
            final n = controller.testimonials.length;
            if (n == 0) return const SizedBox.shrink();
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(
                '$n',
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            );
          }),
          const Spacer(),
          InkWell(
            onTap: _openAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'View All',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.primaryColor),
                ],
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
      if (controller.testimonials.isEmpty) {
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

      final visible = controller.testimonials.take(_kHomeLimit).toList();
      return SizedBox(
        height: 218,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => TestimonialCard(
            width: 290,
            testimonial: visible[i],
          ),
        ),
      );
    });
  }
}
