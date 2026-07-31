import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_dashboard_page.dart';
import 'package:BlueEra/features/common/referral/widgets/my_code_header.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Referral entry screen. Every user is issued a referral code at
/// sign-up, so this no longer gates on a "generate/register" step — it
/// loads the code + editability from the signed-in profile and shows the
/// [ReferralDashboardPage] straight away. When the profile's
/// `referralCodeEditable` flag is true, the dashboard surfaces an
/// "Update Referral Code" action.
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
    controller.loadProfileReferralInfo();
    controller.fetchStats();
    if (controller.testimonials.isEmpty) {
      controller.fetchTestimonials();
    }
    if (controller.overviews.isEmpty) {
      controller.fetchOverview();
    }
    // Profile controllers may finish loading after this screen mounts;
    // re-read the referral code / editability once the first frame is in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProfileReferralInfo();
    });
  }

  Future<void> _refresh() async {
    controller.loadProfileReferralInfo();
    await controller.fetchStats();
  }

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
        final status = controller.statsResponse.value.status;
        return Scaffold(
          appBar: CommonBackAppBar(
            title: AppStrings.myCode,
            isShadowShow: false,
            buildCustomActionWidget: () => Padding(
              padding: EdgeInsets.only(right: SizeConfig.size10),
              child: Center(
                child: Obx(
                  () => MyCodeHeader(code: controller.myReferralCode),
                ),
              ),
            ),
          ),
          body: _buildBody(status),
        );
      }),
    );
  }

  // DecorationImage.onError signature is (exception, stackTrace).
  static void _onPatternError(Object exception, StackTrace? stackTrace) {}

  Widget _buildBody(Status? status) {
    // Hold the spinner only for the very first status resolve so the
    // dashboard doesn't flash empty; afterwards each tab drives its own
    // loaders.
    if (status == Status.INITIAL) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ReferralDashboardPage(controller: controller),
    );
  }
}
