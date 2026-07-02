import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonial_video_grid.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// All testimonials — a scrollable 2-column grid of testimonial videos
/// (testimonials are video-only). Tapping a tile opens the full-screen
/// shorts-style player.
class AllTestimonialsScreen extends StatefulWidget {
  final ReferralController controller;
  const AllTestimonialsScreen({super.key, required this.controller});

  @override
  State<AllTestimonialsScreen> createState() => _AllTestimonialsScreenState();
}

class _AllTestimonialsScreenState extends State<AllTestimonialsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.testimonials.isEmpty) {
      widget.controller.fetchTestimonials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        title: 'All Testimonials',
        isShadowShow: false,
      ),
      body: Obx(() {
        final status = widget.controller.testimonialsResponse.value.status;
        final videos =
            widget.controller.testimonials.where((t) => t.hasVideo).toList();

        if ((status == Status.LOADING || status == Status.INITIAL) &&
            videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (videos.isEmpty) return _empty();

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
          child: TestimonialVideoGrid(videos: videos),
        );
      }),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_collection_outlined,
                size: 56, color: AppColors.primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            CustomText(
              'No testimonials yet',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 4),
            CustomText(
              'Check back later — new stories from BlueEra land here.',
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
