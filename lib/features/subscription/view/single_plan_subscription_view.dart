import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/features/subscription/widget/subscription_live_plan_card.dart';
import 'package:BlueEra/features/subscription/widget/subscription_payment_handler.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
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

  /// When true, the primary CTA is pinned to the bottom of the available
  /// area and the card content scrolls independently above it. Used when
  /// this view is embedded inside a bounded surface (e.g. the persistent
  /// peek bottom sheet) so the action button stays visible without scroll.
  final bool pinCta;

  const SinglePlanSubscriptionView({
    super.key,
    this.isShowAppBar = false,
    this.pinCta = false,
  });

  @override
  State<SinglePlanSubscriptionView> createState() =>
      _SinglePlanSubscriptionViewState();
}

class _SinglePlanSubscriptionViewState
    extends State<SinglePlanSubscriptionView> {
  final controller = getOrPut(() => SubscriptionController());

  /// Scales a base font / icon size proportionally to the current phone
  /// width so this view reads the same on a 320px iPhone SE and a 430px
  /// Pro Max. Reference width 390 (iPhone 14 Pro), clamped 0.85×–1.15× on
  /// phones so extreme devices don't blow out the layout. Tablets go
  /// through a 1.25× step so they stay distinct from the phone scale.
  double _scaled(double base) {
    if (SizeConfig.isTablet) return base * 1.25;
    final factor = (SizeConfig.screenWidth / 390.0).clamp(0.85, 1.15);
    return base * factor;
  }

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
    // the natural height of this widget. In pinCta mode the bottom sheet
    // paints its own gradient behind us, so the Material must be
    // transparent — otherwise it would cover that gradient with a flat fill.
    return Material(
      color: widget.pinCta ? Colors.transparent : AppColors.white,
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
                    fontSize: _scaled(22),
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

  /// Picks the plan to display. The API can return multiple versions of a
  /// plan (e.g. old pricing + current pricing with tax info) — prefer the
  /// one flagged `active: true` so tax/perk details come from the live
  /// version. Falls back to the first plan if none are active.
  SubscriptionPlanData? _pickPlan() {
    final list = controller.subscriptionPlanDetailsNewModel.value.data;
    if (list == null || list.isEmpty) return null;
    for (final plan in list) {
      if (plan.active == true) return plan;
    }
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
    if (isTrial) return _buildTrialOfferCard(plan);

    final priceText =
        '${AppConstants.rupeeSymbol}${plan.amount != null ? (plan.amount! / 100).toStringAsFixed(0) : '0'}';
    final periodText =
        '${plan.interval ?? ''} ${(plan.period ?? '').capitalizeFirst ?? ''}'
            .trim();
    final fullPriceText = plan.amountBeforeDiscount != null
        ? '${AppConstants.rupeeSymbol}${(plan.amountBeforeDiscount! / 100).toStringAsFixed(0)}'
        : null;

    return _screen(
      card: _planCard(
        plan: plan,
        tagText: 'Premium Plan',
        priceText: priceText,
        periodText: periodText,
        subtitle: fullPriceText != null ? _autoPayLine(fullPriceText) : null,
        bodyText: (plan.description == null || plan.description!.isEmpty)
            ? 'Upload and showcase your products, increase visibility to local clients and expand your business with us. Get found, get noticed and get more orders here.'
            : plan.description!,
        perks: plan.perks ?? const [],
      ),
      cta: _primaryButton(title: 'Go Live Now', onTap: _handlePay),
    );
  }

  // ──────────────────── Trial offer card (new design) ─────────────────────
  Widget _buildTrialOfferCard(SubscriptionPlanData plan) {
    final perkValue = plan.perkValue ?? 0;
    final perkBonus = plan.perkBonus ?? 0;
    final totalUnits = perkValue + perkBonus;
    final perkLabel = _perkTypeLabel(plan.perkType);
    final bonusPct =
        perkValue > 0 ? ((perkBonus / perkValue) * 100).round() : 0;
    final afterTrialLine = _afterTrialBillingLine(plan);

    final dynamicPerks = (plan.perks ?? const <String>[])
        .where((p) => !_perkDuplicatesCounts(p, perkValue, perkBonus))
        .toList();

    // The photo paints the full card as a DecorationImage. The frosted
    // glass effect lives only on _trialHeader() below — the rest of the
    // card shows the image as-is.
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.purpleE9, width: 0.5),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.subscriptionBgCard),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _trialHeader(),

            Container(height: 1, color: AppColors.white),
            _trialStaticPerks(),

            // Single horizontal dashed separator below the static perks.
            DashedHorizontalLine(
              color: AppColors.purpleE9,
              strokeWidth: 1,
              dashLength: 5,
              gapLength: 3,
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size12,
                SizeConfig.size16,
                SizeConfig.size4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "WHAT'S INCLUDED",
                    fontSize: _scaled(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey50,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _includedHighlightBox(
                    perkValue: perkValue,
                    perkBonus: perkBonus,
                    perkLabel: perkLabel,
                    bonusPct: bonusPct,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  ...dynamicPerks.map(_trialPerkItem),
                  if (afterTrialLine != null) ...[
                    _trialPerkItem(afterTrialLine),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final cta =
        _trialCtaButton(totalUnits: totalUnits, perkLabel: perkLabel);

    return _pinnableLayout(card: card, cta: cta);
  }

  Widget _trialHeader() {
    // Frosted-glass band: blurs the card's background image underneath and
    // lays a 60% white veil on top, then renders the header content. The
    // ClipRRect bounds the blur so it can't leak onto the rest of the card.
    // The purpleE9 hairline border is painted on the inner Container (inside
    // the clip) so it isn't trimmed by the rounded corners.
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: AppColors.purpleE9, width: 0.5),
              left: BorderSide(color: AppColors.purpleE9, width: 0.5),
              right: BorderSide(color: AppColors.purpleE9, width: 0.5),
            ),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${AppConstants.rupeeSymbol}0',
                          style: TextStyle(
                            fontSize: _scaled(40),
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: ' / 3 Days',
                          style: TextStyle(
                            fontSize: _scaled(20),
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  'Try Free — No Upfront Cost',
                  fontSize: _scaled(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey50,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.white),
                ),
                child: CustomText(
                  'FREE Trial',
                  fontSize: _scaled(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _trialStaticPerks() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size15,
        SizeConfig.size16,
        SizeConfig.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkIcon(),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: _scaled(16),
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey50,
                    ),
                    children: [
                      TextSpan(
                        text: '${AppConstants.rupeeSymbol}5',
                        style: TextStyle(
                          fontSize: _scaled(16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      TextSpan(
                        text: ' Verification Only  ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: _scaled(16),
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      TextSpan(
                        text: '  Refunded Instantly',
                        style: TextStyle(
                          fontSize: _scaled(16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.green17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkIcon(),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: CustomText(
                  'No Card Locked. Cancel Anytime.',
                  fontSize: _scaled(16),
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _includedHighlightBox({
    required int perkValue,
    required int perkBonus,
    required String perkLabel,
    required int bonusPct,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.whiteF5,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: AppColors.purpleE9
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  '$perkValue + $perkBonus',
                  fontSize: _scaled(24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                // SizedBox(height: SizeConfig.size2),
                CustomText(
                  '$perkLabel Total',
                  fontSize: _scaled(16),
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey50,
                ),
              ],
            ),
          ),
          if (bonusPct > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: AppColors.green17.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    '+$bonusPct%',
                    fontSize: _scaled(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.green17,
                  ),
                  // SizedBox(height: SizeConfig.size1),
                  CustomText(
                    'Bonus $perkLabel',
                    fontSize: _scaled(12),
                    fontWeight: FontWeight.w400,
                    color: AppColors.green17,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _trialPerkItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checkIcon(),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: _scaled(16),
              fontWeight: FontWeight.w400,
              color: AppColors.grey50,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon() {
    return LocalAssets(
      imagePath: AppIconAssets.greenCircleTickIcon,
      width: _scaled(18),
      height: _scaled(18),
      imgColor: AppColors.secondaryTextColor,
    );
  }

  Widget _trialCtaButton({
    required int totalUnits,
    required String perkLabel,
  }) {
    return GestureDetector(
      onTap: _handlePay,
      child: Container(
        width: SizeConfig.screenWidth,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomText(
                'Start Free  —  Claim My $totalUnits $perkLabel',
                fontSize: _scaled(16),
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: SizeConfig.size2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomText(
                'Verify identity with ${AppConstants.rupeeSymbol}5  —  refunded within seconds.',
                fontSize: _scaled(12),
                fontWeight: FontWeight.w400,
                color: AppColors.yellow6C,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Title-cases the `perk_type` string from the API ("leads" → "Leads",
  // "rides" → "Rides"). Falls back to a safe default when missing.
  String _perkTypeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Items';
    final lower = type.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // Drops perk strings whose only information is the numeric value already
  // rendered in the highlight box (e.g. "30 Leads", "5 Bonus Leads"). Keeps
  // everything else from the API unchanged so copy tweaks on the backend
  // still land in the UI.
  bool _perkDuplicatesCounts(String perk, int perkValue, int perkBonus) {
    final lower = perk.toLowerCase();
    if (perkValue > 0 && lower.contains('$perkValue ')) return true;
    if (perkBonus > 0 && lower.contains('$perkBonus ') && lower.contains('bonus')) {
      return true;
    }
    return false;
  }

  // "After Trial: ₹99 + GST/Year With Auto Pay". Uses `amount` (paise) and
  // appends "+ GST" when the backend reports a non-zero tax percent. Returns
  // null when amount is missing so the line is skipped entirely.
  String? _afterTrialBillingLine(SubscriptionPlanData plan) {
    if (plan.amount == null) return null;
    final rupees = (plan.amount! / 100).toStringAsFixed(0);
    final hasTax = (plan.taxPercent ?? 0) > 0;
    final period = (plan.period ?? 'year').toLowerCase();
    final periodWord = period == 'yearly' ? 'Year' : period.capitalizeFirst ?? 'Year';
    final priceWithTax =
        hasTax ? '${AppConstants.rupeeSymbol}$rupees+GST' : '${AppConstants.rupeeSymbol}$rupees';
    return 'After Trial: $priceWithTax/$periodWord With Auto Pay';
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
    if (widget.pinCta && cta != null) {
      return _pinnableLayout(card: card, cta: cta, edgeToEdge: edgeToEdge);
    }
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

  /// Lays out a card + CTA so the CTA sticks to the bottom of a bounded
  /// area while the card scrolls above it. Falls back to a plain scrollable
  /// column when [pinCta] is false.
  Widget _pinnableLayout({
    required Widget card,
    required Widget cta,
    bool edgeToEdge = false,
  }) {
    final horizontal = edgeToEdge ? 0.0 : SizeConfig.size12;

    if (!widget.pinCta) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: SizeConfig.size12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card,
            SizedBox(height: SizeConfig.paddingL),
            cta,
            SizedBox(height: SizeConfig.paddingS),
          ],
        ),
      );
    }

    // `mainAxisSize.min` + `Flexible(fit: loose)` lets the column shrink to
    // its content when the card is shorter than the parent's maxHeight, and
    // still lets the scroll view take only the space remaining when the card
    // overflows. This is what makes the bottom sheet height dynamic while
    // keeping the CTA pinned at the bottom.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              SizeConfig.size12,
              horizontal,
              SizeConfig.size12,
            ),
            physics: const ClampingScrollPhysics(),
            child: card,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              SizeConfig.size12,
            ),
            child: cta,
          ),
        ),
      ],
    );
  }

  /// "Then ₹X/year with Auto Pay" subtitle used in the trial offer.
  Widget _autoPayLine(String fullPriceText) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: _scaled(12),
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        children: [
          const TextSpan(text: 'Then '),
          TextSpan(
            text: '$fullPriceText/year ',
            style: TextStyle(
              fontSize: _scaled(12),
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          const TextSpan(text: 'with '),
          TextSpan(
            text: 'Auto Pay',
            style: TextStyle(
              fontSize: _scaled(12),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$priceText / ',
                          style: TextStyle(
                            fontSize: _scaled(44),
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        TextSpan(
                          text: periodText,
                          style: TextStyle(
                            fontSize: _scaled(20),
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (subtitle != null) ...[
                  SizedBox(height: SizeConfig.size4),
                  subtitle,
                ],

                SizedBox(height: SizeConfig.size12),

                CustomText(
                  bodyText,
                  fontSize: _scaled(14),
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
            height: _scaled(22),
            width: _scaled(22),
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
        fontSize: _scaled(12),
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
                fontSize: _scaled(14),
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
            size: _scaled(16),
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: _scaled(14),
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

