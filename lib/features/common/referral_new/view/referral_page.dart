import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral_new/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral_new/view/referral_dashboard_page.dart';
import 'package:BlueEra/features/common/referral_new/widgets/balance_total_earn_row.dart';
import 'package:BlueEra/features/common/referral_new/widgets/generate_referral_section.dart';
import 'package:BlueEra/features/common/referral_new/widgets/my_code_header.dart';
import 'package:BlueEra/features/common/referral_new/widgets/testimonials_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Entry point for the BDM / Refer-&-Earn feature (new flow).
///
/// Single-step registration:
///   • NOT_STARTED / PENDING → welcome video + "Generate Your Referral
///     Code" form + Balance/Total Earn + Testimonials. Submitting the
///     form hits step-2 with just the code and re-reads /bdm/status,
///     which flips to COMPLETED on success.
///   • COMPLETED → AppBar title swaps to "My code" with the code pill
///     in the action slot; body is the 4-tab dashboard
///     (Overview / Tutorial / Post / Statics).
///
/// A soft chat-background texture fills the entire screen (behind the
/// AppBar too) so the surface matches the wider Me-section visual
/// language used by `product_screen` and `food_main_screen`.
class ReferralPageNew extends StatefulWidget {
  const ReferralPageNew({super.key});

  @override
  State<ReferralPageNew> createState() => _ReferralPageNewState();
}

class _ReferralPageNewState extends State<ReferralPageNew> {
  final controller = getOrPut(() => ReferralControllerNew());

  @override
  void initState() {
    super.initState();
    controller.fetchBdmDetails();
    if (controller.testimonials.isEmpty) {
      controller.fetchTestimonials();
    }
  }

  Future<void> _refresh() => controller.fetchBdmDetails();

  @override
  Widget build(BuildContext context) {
    // Root container paints the pattern texture across the entire
    // screen (status bar, AppBar and body). The Scaffold sits on top
    // with transparent chrome so the pattern shows through.
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImageAssets.chatDefaultBg),
          fit: BoxFit.cover,
          // If the asset is ever missing the DecorationImage simply
          // shows the underlying container color — give it the same
          // light-blue fallback used elsewhere in the app.
          onError: _onPatternError,
        ),
        color: Color(0xFFEAF2FB),
      ),
      child: Obx(() {
        final status = controller.bdmDetailsResponse.value.status;
        final isCompleted = controller.isCompleted;
        return Scaffold(
          backgroundColor: Colors.transparent,
          // Title is static — the code pill in the action slot reacts
          // to the live referral code (placeholder until /bdm/status
          // + /wallet-stats land).
          appBar: CommonBackAppBar(
            title: 'My code',
            isShadowShow: false,
            // The action pill is wrapped in its own Obx so it tracks
            // `stats.referralCode` independently of the outer Obx,
            // which only watches the BDM-status response. Without this
            // inner subscription the pill renders once with an empty
            // code (because /wallet-stats hasn't returned yet) and
            // never refreshes.
            buildCustomActionWidget: () => Padding(
              padding: EdgeInsets.only(right: SizeConfig.size10),
              child: Center(
                child: Obx(
                  () => MyCodeHeader(code: controller.myReferralCode),
                ),
              ),
            ),
          ),
          body: _buildBody(status, isCompleted),
        );
      }),
    );
  }

  // DecorationImage.onError signature is (exception, stackTrace).
  static void _onPatternError(Object exception, StackTrace? stackTrace) {}

  Widget _buildBody(Status? status, bool isCompleted) {
    if (status == Status.LOADING || status == Status.INITIAL) {
      return const Center(child: CircularProgressIndicator());
    }
    if (isCompleted) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ReferralDashboardPage(controller: controller),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildRegisterContent(),
      ),
    );
  }

  Widget _buildRegisterContent() {
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
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
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
            child: const HorizontalVideoPlayer(isAutoPlay: false),
          ),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: GenerateReferralSection(
            controller: controller,
            isEditable: true,
          ),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: const BalanceTotalEarnRow(balance: 0, totalEarn: 0),
        ),
        SizedBox(height: SizeConfig.paddingM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: TestimonialsSection(controller: controller),
        ),
        SizedBox(height: SizeConfig.size20),
      ],
    );
  }
}
