import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/balance_total_earn_row.dart';
import 'package:BlueEra/features/common/referral/widgets/generate_referral_section.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonials_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Update Referral Code" screen — the same layout the old create/generate
/// page used (`_buildRegisterContent`): intro video, the referral card,
/// the balance row and testimonials. The only difference is the referral
/// card runs in `isUpdate` mode, so its submit button calls
/// `PUT wallet/referral` instead of BDM registration. Reached from the
/// referral dashboard only while the profile's `referralCodeEditable`
/// flag is true.
class UpdateReferralPage extends StatefulWidget {
  final ReferralController controller;

  const UpdateReferralPage({super.key, required this.controller});

  @override
  State<UpdateReferralPage> createState() => _UpdateReferralPageState();
}

class _UpdateReferralPageState extends State<UpdateReferralPage> {
  @override
  void initState() {
    super.initState();
    // Prefill with the current code so the user edits rather than
    // retypes from scratch.
    widget.controller.referralCodeController.text =
        widget.controller.myReferralCode;
    if (widget.controller.overviews.isEmpty) {
      widget.controller.fetchOverview();
    }
    if (widget.controller.testimonials.isEmpty) {
      widget.controller.fetchTestimonials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Update Referral Code',
        isShadowShow: false,
      ),
      body: Column(
        children: [
          // The app bar has no shadow, so a thin pinned divider acts as
          // the separator between the chrome and the scrolling content.
          const Divider(height: 1, thickness: 1, color: AppColors.whiteE0),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildUpdateContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateContent() {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(
            top: SizeConfig.size15,
            bottom: SizeConfig.size15,
            left: SizeConfig.size15,
            right: SizeConfig.size15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
                blurStyle: BlurStyle.outer,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Obx(() {
              // Pull network video URLs from the overview API response.
              final videoUrls = controller.overviews
                  .where((o) => o.hasVideo)
                  .map((o) => o.video!)
                  .toList();

              if (videoUrls.isNotEmpty) {
                return HorizontalVideoPlayer(
                  // Re-init the player when the URL set changes.
                  key: ValueKey(videoUrls.join(',')),
                  isAutoPlay: false,
                  videoUrls: videoUrls,
                  isNetworkUrl: true,
                );
              }

              // Still fetching → keep the 16:9 slot with a loader.
              final s = controller.overviewResponse.value.status;
              if (s == Status.LOADING || s == Status.INITIAL) {
                return const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Loaded but no overview video → bundled intro video fallback.
              return const HorizontalVideoPlayer(isAutoPlay: false);
            }),
          ),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: GenerateReferralSection(
            controller: controller,
            isEditable: true,
            isUpdate: true,
          ),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: const BalanceTotalEarnRow(balance: 0, totalEarn: 0),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: TestimonialsSection(controller: controller),
        ),
        SizedBox(height: SizeConfig.size20),
      ],
    );
  }
}
