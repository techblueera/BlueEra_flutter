import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/features/subscription/widget/subscription_live_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single-plan subscription UI. Renders one plan card per state with the
/// [AppImageAssets.subscriptionBgCard] background. Used both inside the
/// peek bottom sheet (no app bar) and as a standalone page from the
/// drawer / account settings (with [isShowAppBar] = true).
class SinglePlanSubscriptionView extends StatefulWidget {
  /// When true, renders inside a [Scaffold] with a [CommonBackAppBar] so
  /// the widget can be pushed as a full page. When false (default), renders
  /// just the body — suitable for embedding inside a bottom sheet.
  final bool isShowAppBar;

  const SinglePlanSubscriptionView({
    super.key,
    this.isShowAppBar = false,
  });

  @override
  State<SinglePlanSubscriptionView> createState() =>
      _SinglePlanSubscriptionViewState();
}

class _SinglePlanSubscriptionViewState
    extends State<SinglePlanSubscriptionView> {
  final controller = getOrPut(() => SubscriptionController());

  @override
  void initState() {
    super.initState();
    // Only fire each request if no prior caller has already kicked it off.
    // This widget is embedded inside SubscriptionBottomSheet, which fetches
    // both endpoints in its own initState — calling them again here would
    // double the network hits and flip the response back to LOADING mid-
    // frame. When mounted standalone (drawer / account settings), the
    // status is still INITIAL so the calls go through normally.
    if (controller.userSubscriptionResponse.value == Status.INITIAL) {
      controller.userCurrentPlanApi();
    }
    if (controller.getSubscriptionPlanResponse.value.status ==
        Status.INITIAL) {
      controller.subscriptionPlansGetApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildContent();
    if (!widget.isShowAppBar) return body;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: "Contribution",
      ),
      body: SingleChildScrollView(
          child: body),
    );
  }

  Widget _buildContent() {
    // No fixed height — the parent (bottom sheet or scrollview) measures
    // the natural height of this widget.
    return Material(
      color: AppColors.white,
      child: Obx(() {
        if (controller.userSubscriptionResponse.value == Status.INITIAL ||
            controller.getSubscriptionPlanResponse.value.status ==
                Status.LOADING) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.userSubscriptionResponse.value == Status.ERROR) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.warningRedIcon),
                  SizedBox(height: SizeConfig.paddingXSL),
                  CustomText(
                    "oops.. something went wrong.",
                    fontSize: SizeConfig.extraLarge22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          );
        }

        return _buildBody();
      }),
    );
  }

  Widget _buildBody() {
    // Single source of truth for all subscription states. Renders one
    // card per state instead of swapping in entirely different screens.
    if (controller.currentPlansList.isEmpty) {
      return _offerContent(isTrial: true);
    }

    final userSub = controller.currentPlansList.first;
    switch (userSub.status) {
      case 'authenticated':
        // Trial purchased and active — show congrats + trial dates.
        return _trialActiveContent(userSub);
      case 'active':
        // Paid plan currently running — show valid-until + Active badge.
        return _activeSubscriptionContent(userSub);
      case 'paused':
      case 'halted':
        // Plan paused/halted — prompt to recharge.
        return _pausedContent(userSub);
      case 'cancelled':
        // Cancelled (whether trial or paid) → always show the paid
        // recharge offer; we no longer re-pitch the free trial.
        return _offerContent(isTrial: false);
      default:
        return _offerContent(isTrial: true);
    }
  }

  /// Picks the single plan to display. The API returns one plan list per
  /// entity_type and the trial-vs-paid distinction lives on the user's
  /// subscription status, not on the plan itself — so we just take the
  /// first plan regardless of [isTrial].
  SubscriptionPlanData? _pickPlan() {
    final list = controller.subscriptionPlanDetailsNewModel.value.data;
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  // ───────────────────────────── State 1: offer ─────────────────────────────
  // Trial offer or recharge offer (depending on [isTrial]). User has either
  // never subscribed or just had a trial/paid plan cancelled.
  Widget _offerContent({required bool isTrial}) {
    final plan = _pickPlan();
    if (plan == null) {
      return const Center(child: CustomText("No plans available."));
    }

    final priceText = isTrial
        ? '${AppConstants.rupeeSymbol}5'
        : '${AppConstants.rupeeSymbol}${plan.amount != null ? (plan.amount! / 100).toStringAsFixed(0) : '0'}';
    final periodText = isTrial
        ? '3 Days'
        : '${plan.interval ?? ''} ${(plan.period ?? '').capitalizeFirst ?? ''}'.trim();
    final fullPriceText = isTrial
        ? '${AppConstants.rupeeSymbol}${plan.amount != null ? (plan.amount! / 100).toStringAsFixed(0) : '0'}'
        : (plan.amountBeforeDiscount != null
            ? '${AppConstants.rupeeSymbol}${(plan.amountBeforeDiscount! / 100).toStringAsFixed(0)}'
            : null);

    return _screen(
      card: _planCard(
        plan: plan,
        tagText: isTrial ? 'Trial Plan' : 'Premium Plan',
        priceText: priceText,
        periodText: periodText,
        subtitle: (isTrial && fullPriceText != null)
            ? _autoPayLine(fullPriceText)
            : null,
        bodyText: (plan.description == null || plan.description!.isEmpty)
            ? 'Upload and showcase your products, increase visibility to local clients and expand your business with us. Get found, get noticed and get more orders here.'
            : plan.description!,
        // Razorpay's trial flow requires a real ₹5 charge to authenticate
        // the auto-pay mandate — that ₹5 is refunded automatically once
        // the trial finishes successfully. We surface this up-front so the
        // user doesn't think they were billed for the trial.
        extraBlocks: isTrial
            ? [
                SizedBox(height: SizeConfig.paddingS),
                _trialRefundNote(),
              ]
            : const [],
        perks: plan.perks ?? const [],
      ),
      cta: _primaryButton(
        title: isTrial ? 'Go Live Now @ Rs 5' : 'Go Live Now',
        onTap: _handlePay,
      ),
    );
  }

  /// Inline info banner explaining the ₹5 trial-charge refund. Shown only
  /// inside the trial offer card so users understand why Razorpay is asking
  /// for ₹5 upfront on what's labelled as a "free" trial.
  Widget _trialRefundNote() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              'Razorpay charges ${AppConstants.rupeeSymbol}5 to start your free trial — '
              'this amount is refunded automatically once the trial begins.',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── State 2: trial in progress ───────────────────────
  // Status == 'authenticated' — user activated the trial. Delegated to the
  // shared [SubscriptionLivePlanCard] so the chrome stays identical to the
  // statistics-tab surface. Edge-to-edge wrapper here mirrors the previous
  // standalone-page padding behaviour.
  Widget _trialActiveContent(UserSubscription userSub) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size12,
          horizontal: SizeConfig.size8,
      ),
      child: SubscriptionLivePlanCard(userSub: userSub),
    );
  }

  // ───────────────────── State 3: paid subscription active ─────────────────
  // Status == 'active' — paid plan currently running. Same shared widget,
  // which renders the cancel-subscription CTA itself, so this surface only
  // has to provide the outer padding.
  Widget _activeSubscriptionContent(UserSubscription userSub) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size12,
      ),
      child: SubscriptionLivePlanCard(userSub: userSub),
    );
  }

  // ─────────────────── State 4: paused / halted (recharge) ─────────────────
  Widget _pausedContent(UserSubscription userSub) {
    final plan = userSub.subscriptionPlanData;
    final priceText =
        '${AppConstants.rupeeSymbol}${plan.amount != null ? (plan.amount! / 100).toStringAsFixed(0) : '0'}';
    final periodText = (plan.period ?? '').capitalizeFirst ?? '';

    return _screen(
      card: _planCard(
        plan: plan,
        tagText: userSub.status == 'paused' ? 'Paused' : 'Plan Expired',
        priceText: priceText,
        periodText: periodText,
        subtitle: null,
        bodyText:
            'Your plan has been ${userSub.status}. Recharge now to resume premium features.',
        perks: plan.perks ?? const [],
      ),
      cta: _primaryButton(
        title: 'Recharge Now',
        onTap: _handlePay,
      ),
    );
  }

  // ───────────────────────────── Shared chrome ─────────────────────────────
  /// Outer column wrapper used by every state. Keeps padding consistent.
  ///
  /// [edgeToEdge] drops the horizontal gutters so the card stretches to
  /// the full width of its parent — used by the trial-active state where
  /// the card is purely informational (no CTA) and reads better as a
  /// full-bleed celebratory surface than as a padded pill.
  Widget _screen({
    required Widget card,
    Widget? cta,
    bool edgeToEdge = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: edgeToEdge ? 0 : SizeConfig.size12,
        vertical: SizeConfig.size12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          if (cta != null) ...[
            SizedBox(height: SizeConfig.paddingL),
            cta,
          ],
          SizedBox(height: SizeConfig.paddingS),
        ],
      ),
    );
  }

  /// "Then ₹X/year with Auto Pay" subtitle used in the trial offer.
  Widget _autoPayLine(String fullPriceText) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        children: [
          const TextSpan(text: 'Then '),
          TextSpan(
            text: '$fullPriceText/year ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          const TextSpan(text: 'with '),
          TextSpan(
            text: 'Auto Pay',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({required String title, required VoidCallback onTap}) {
    return CustomBtn(
      width: double.infinity,
      title: title,
      bgColor: AppColors.primaryColor,
      borderColor: AppColors.primaryColor,
      textColor: AppColors.white,
      radius: 10.0,
      onTap: onTap,
    );
  }

  void _handlePay() {
    // Single-plan view: there's only one plan, so we hand index 0 to the
    // shared payment handler at tap time instead of tracking a selection
    // in controller state.
    controller.selectedSubscriptionIndex
      ..clear()
      ..add(0);
    SubscriptionPaymentHandler(controller).showReferralCodeDialog();
  }

  /// Generic card chrome used by every state. The state-specific widgets
  /// pass in their own `tagText`, price/period, subtitle, body text, and
  /// any extra inline widgets — the layout, background image, and perks
  /// list stay identical across states for visual consistency.
  Widget _planCard({
    required SubscriptionPlanData plan,
    required String tagText,
    Widget? tagLeading,
    required String priceText,
    required String periodText,
    Widget? subtitle,
    required String bodyText,
    List<Widget> extraBlocks = const [],
    required List<String> perks,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              AppImageAssets.subscriptionBgCard,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: premium icon + (optional) TEST badge + state tag pill.
                // The TEST badge surfaces backend `mode == 'test'` plans so QA
                // can tell at a glance whether they're looking at a test plan
                // versus a live one. Hidden entirely in production / live mode.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPremiumIcon(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (plan.mode?.toLowerCase() == 'test') ...[
                          _testBadge(),
                          SizedBox(width: SizeConfig.size8),
                        ],
                        _tagPill(tagText, leading: tagLeading),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),

                // Price + period (or status word + label for non-offer states)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$priceText / ',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      TextSpan(
                        text: periodText,
                        style: TextStyle(
                          fontSize: SizeConfig.extraLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                if (subtitle != null) ...[
                  SizedBox(height: SizeConfig.size4),
                  subtitle,
                ],

                SizedBox(height: SizeConfig.size12),

                CustomText(
                  bodyText,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  maxLines: 4,
                ),

                ...extraBlocks,

                SizedBox(height: SizeConfig.paddingM),

                DashedBorderContainer(
                  borderColor: AppColors.greyE5,
                  strokeWidth: 1,
                  dashLength: 4,
                  child: SizedBox(
                    height: 1,
                    width: double.maxFinite,
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                // Perks
                ...perks.map(_perkItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white),
          ),
          child: LocalAssets(
            imagePath: AppImageAssets.planTagIcon,
            height: 22,
            width: 22,
            boxFix: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Solid orange "TEST" badge shown next to [_tagPill] when the plan is
  /// in test mode (Razorpay sandbox / non-production keys). Deliberately
  /// loud — it's a debug aid, not a marketing pill.
  Widget _testBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: CustomText(
        'TEST',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }

  Widget _tagPill(String text, {Widget? leading}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size15,
            vertical: SizeConfig.size5,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                SizedBox(width: SizeConfig.size6),
              ],
              CustomText(
                text,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _perkItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }



}
