import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_history_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/balance_total_earn_row.dart';
import 'package:BlueEra/features/common/referral/widgets/media_autoplay_list.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OverviewTab extends StatefulWidget {
  final ReferralController controller;
  const OverviewTab({super.key, required this.controller});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller.overviews.isEmpty) {
      widget.controller.fetchOverview();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size10,
        SizeConfig.paddingXSL,
        SizeConfig.size10,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statsAndActionsCard(),
          SizedBox(height: SizeConfig.paddingM),
          _overviewPostsList(),
        ],
      ),
    );
  }

  /// Balance row + subscription pill + History / Withdraw buttons all
  /// live inside a single white card, matching the mockup grouping.
  Widget _statsAndActionsCard() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        children: [
          Obx(
            () => BalanceTotalEarnRow(
              wrapInCard: false,
              balance: widget.controller.stats.value?.balance ?? 0,
              totalEarn: widget.controller.stats.value?.totalIncome ?? 0,
              estimatedEarning:
                  widget.controller.stats.value?.estimatedEarning ?? 0,
            ),
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          _subscriptionSummaryPill(),
          SizedBox(height: SizeConfig.paddingXSL),
          _actionsRow(),
        ],
      ),
    );
  }

  /// Light gray pill that reads "N Subscription Out of M Referral" — a
  /// thinner strip than the existing primary-tinted summary card, to
  /// match the mockup.
  Widget _subscriptionSummaryPill() {
    return Obx(() {
      final breakdown = widget.controller.stats.value?.breakdown;
      final subscribed = breakdown?.subscribed ?? 0;
      final total = widget.controller.stats.value?.totalReferralCount ?? 0;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          border: Border.all(
            color: Color(0xFFDDE2EE),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: CustomText(
          '${subscribed.toString().padLeft(2, '0')} Subscription Out of '
          '${total.toString().padLeft(2, '0')} Referral',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
        ),
      );
    });
  }

  Widget _actionsRow() {
    return Row(
      children: [
        Expanded(
          child: CustomBtn(
            height: 32,
            radius: 10,
            bgColor: AppColors.white,
            textColor: AppColors.primaryColor,
            borderColor: AppColors.primaryColor,
            onTap: () => Get.to(() => const ReferralHistoryScreenNew()),
            title: 'History',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomBtn(
            height: 32,
            radius: 10,
            isValidate: true,
            bgColor: AppColors.primaryColor,
            textColor: AppColors.white,
            onTap: () {},
            title: 'Withdraw',
          ),
        ),
      ],
    );
  }

  Widget _overviewPostsList() {
    return Obx(() {
      final status = widget.controller.overviewResponse.value.status;
      if (status == Status.INITIAL || status == Status.LOADING) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (status == Status.ERROR) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CustomText(
              'Oops, something went wrong',
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
            ),
          ),
        );
      }
      final items = widget.controller.overviews;
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CustomText(
              'No overview posts yet.',
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
            ),
          ),
        );
      }
      return MediaAutoplayList(items: items.toList());
    });
  }
}
