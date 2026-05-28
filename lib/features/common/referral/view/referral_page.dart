import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_dashboard_page.dart';
import 'package:BlueEra/features/common/referral/widgets/balance_total_earn_row.dart';
import 'package:BlueEra/features/common/referral/widgets/generate_referral_section.dart';
import 'package:BlueEra/features/common/referral/widgets/my_code_header.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonials_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final controller = getOrPut(() => ReferralController());

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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImageAssets.chatDefaultBg),
          fit: BoxFit.cover,
          onError: _onPatternError,
        ),
        color: Color(0xFFEAF2FB),
      ),
      child: Obx(() {
        final status = controller.bdmDetailsResponse.value.status;
        final isCompleted = controller.isCompleted;
        return Scaffold(
          appBar: CommonBackAppBar(
            title: isCompleted ? 'My code' : AppStrings.referAndEarn.tr,
            isShadowShow: false,
            buildCustomActionWidget: isCompleted
                ? () => Padding(
                      padding: EdgeInsets.only(right: SizeConfig.size10),
                      child: Center(
                        child: Obx(
                          () => MyCodeHeader(code: controller.myReferralCode),
                        ),
                      ),
                    )
                : null,
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
