import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/balance_total_earn_row.dart';
import 'package:BlueEra/features/common/referral/widgets/generate_referral_section.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonials_section.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

/// "Update Referral Code" screen — the referral card, the balance row and
/// testimonials. The referral card runs in `isUpdate` mode, so its submit
/// button calls `PUT wallet/referral` instead of BDM registration. Reached
/// from the referral dashboard only while the profile's `referralCodeEditable`
/// flag is true.
///
/// The intro video (and its `fetchOverview()` call) used to head this page and
/// has been removed — editing a code doesn't need a pitch.
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
    // No `fetchOverview()` here — the overview API only fed the intro video,
    // which this page no longer shows. The endpoint itself is still used by the
    // referral dashboard / overview tab, so it stays; this screen just doesn't
    // pay for it any more.
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
