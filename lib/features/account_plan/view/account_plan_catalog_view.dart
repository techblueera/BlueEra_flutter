import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/account_plan_controller.dart';
import '../model/account_plan_models.dart';

/// Palette for the One-Time Contribution Plans surface.
///
/// The screen is a light-blue sheet carrying white plan cards; only the price
/// pill is saturated, which is what makes the price the first thing read on
/// each card. Colours are literal rather than [AppColors] tokens because this
/// surface is drawn to a specific comp — see assets/subscription_1.png and
/// assets/subscription_2.png.
abstract class AccountPlanPalette {
  /// The sheet the cards sit on.
  static const Color canvas = Color(0xFFD9EDF8);

  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4EDF3);
  static const Color divider = Color(0xFFD5E2EA);

  static const Color heading = Color(0xFF12161C);
  static const Color muted = Color(0xFF6C7B87);
  static const Color featureText = Color(0xFF4F5A64);

  /// Feature ticks. Green everywhere in the app means "you get this".
  static const Color tick = Color(0xFF23A455);

  /// The one condition that can disqualify a buyer, so it is the one warm
  /// colour on an otherwise cool card.
  static const Color gstWarning = Color(0xFF9B1C1C);

  static const Color link = Color(0xFF2F86E0);

  /// The backend's `popular` pick. Amber, and deliberately not green or blue:
  /// on these cards green already means "you own this" and blue means "you have
  /// selected this", so a recommendation borrowing either would be read as a
  /// state the user is already in.
  static const Color popular = Color(0xFFE59128);
  static const Color popularLight = Color(0xFFF8C45A);

  /// Barely-there warm wash behind a recommended card, so it separates from its
  /// neighbours on the blue sheet before the badge is even read.
  static const Color popularSurface = Color(0xFFFFFCF5);

  /// The active plan's panel — pine → green, and the ONLY filled card on a
  /// sheet of white ones.
  ///
  /// The sheet's whole visual system is white cards with ink type and one
  /// saturated pill; a card the user already owns is the one thing here that
  /// isn't for sale, so it is inverted rather than decorated. That single
  /// contrast does the work a badge was doing, and it is spent once — every
  /// other card is left exactly as it was.
  ///
  /// Green because green already means "you have this" on these cards (the
  /// feature ticks, the old Active stamp); the pine end just gives the sweep
  /// somewhere dark to travel from.
  static const List<Color> activePanel = [
    Color(0xFF0B4C3C),
    Color(0xFF14876B),
    Color(0xFF23A455),
  ];

  /// Price-pill gradients, one per card position. Assigned by catalog index so
  /// a card keeps its colour across rebuilds, and so five near-identical gig
  /// plans stay tellable apart when scrolling back to compare them.
  static const List<List<Color>> pricePills = [
    [Color(0xFF56BFD6), Color(0xFF2B93AF)], // teal
    [Color(0xFFF8C45A), Color(0xFFE59128)], // amber
    [Color(0xFF57C063), Color(0xFF23924B)], // green
    [Color(0xFF6A46A0), Color(0xFF35205C)], // deep violet
    [Color(0xFFC93BA0), Color(0xFF8E2372)], // magenta
  ];

  static List<Color> pricePillFor(int index) =>
      pricePills[index % pricePills.length];
}

/// The Account Plan catalog, as a plain (non-scrolling) column.
///
/// Renders whatever `plans[]` the backend returns and draws each card from its
/// own fields, so adding a 139th account type on the backend needs no change
/// here: the label, the sublabel, the **`features`** bullets and the
/// **`terms_and_conditions`** all come from the API and are rendered verbatim.
///
/// **No inner scroll**: the host owns the scroll view, which is what lets the
/// contribution screen stack the explainer video above this and have the two
/// move as one. Loading/error states get a bounded height for the same reason.
///
/// **No Buy button per card.** A card is *selected*; the host's pinned
/// [AccountPlanPayBar] buys whatever is selected — see the comp.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanCatalogView extends StatelessWidget {
  const AccountPlanCatalogView({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final AccountPlanController controller;

  /// The "Select a Contribution Plan" title block. Off when the host already
  /// says the same thing directly above.
  final bool showHeader;

  /// Headline per archetype — kept for hosts that want the question the cards
  /// answer ("Choose your visibility radius") rather than the generic title.
  static String headlineKeyFor(String archetype) {
    switch (archetype) {
      case PlanArchetype.radiusShop:
      case PlanArchetype.wideReach:
        return AppStrings.chooseVisibilityRadius;
      case PlanArchetype.gigCalls:
        return AppStrings.chooseYourCallPlan;
      case PlanArchetype.localService:
        return AppStrings.chooseServiceArea;
      case PlanArchetype.leadPro:
      case PlanArchetype.booking:
        return AppStrings.chooseYourListing;
      default:
        return AppStrings.chooseYourPlan;
    }
  }

  /// The catalog with owned plans hoisted to the front, each still carrying the
  /// index it had in the API's order.
  List<(int, PlanCard)> _ordered(List<PlanCard> plans) {
    final entries = plans.indexed.toList();
    return [
      ...entries.where((e) => controller.ownsPlan(e.$2)),
      ...entries.where((e) => !controller.ownsPlan(e.$2)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final catalog = controller.catalog.value;
      final hasCatalog = catalog != null && catalog.plans.isNotEmpty;

      // Loading and error states only take over the surface when there is
      // nothing to show yet. A pull-to-refresh over a catalog that already
      // loaded keeps the cards on screen — the RefreshIndicator is already
      // saying "working", and blanking a working screen (or worse, replacing it
      // with a Retry after a flaky refresh) loses the user's place mid-compare.
      if (!hasCatalog) {
        switch (controller.plansStatus.value) {
          case Status.INITIAL:
          case Status.LOADING:
            return SizedBox(
              height: 320,
              child: Center(child: staggeredDotsWaveLoading()),
            );
          case Status.ERROR:
            return SizedBox(
              height: 320,
              child: AccountPlanErrorState(
                message: controller.plansError.value,
                onRetry: controller.fetchPlans,
              ),
            );
          case Status.COMPLETE:
            // Answered, and the answer is that this account has nothing to buy.
            return SizedBox(
              height: 320,
              child: AccountPlanErrorState(
                message: AppStrings.noPlansForAccount.tr,
                onRetry: controller.fetchPlans,
              ),
            );
        }
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size16,
          SizeConfig.size16,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The campaign, above everything it discounts. Shown whenever one
            // is live — even if only some of the cards below are in its scope,
            // which is what `has_discount` decides per card.
            if (catalog.showCampaign)
              _CampaignBanner(
                campaign: catalog.campaign!,
                onExpired: controller.onOfferExpired,
              ),
            if (showHeader) ...[
              const _CatalogHeader(),
              SizedBox(height: SizeConfig.size14),
            ],
            // Coupon-only campaigns are invisible until the code is sent, so
            // the field is the only way to reach them. Hidden entirely when
            // discounts are switched off backend-side — there would be nothing
            // for a code to unlock.
            if (catalog.discountEnabled) ...[
              _CouponField(controller: controller),
              SizedBox(height: SizeConfig.size14),
            ],
            // Owned plans lead. What the merchant already has is the one thing
            // on this screen they don't have to decide about, and burying it
            // mid-catalog made them read every card to find it. The rest keep
            // the backend's order.
            //
            // The ORIGINAL catalog index travels with each plan: it picks the
            // price pill's colour, and a pill that changed colour because a
            // plan moved up the list would break the one thing those colours
            // are for — telling five near-identical plans apart while scrolling
            // back to compare them.
            for (final (index, plan) in _ordered(catalog.plans))
              if (controller.ownsPlan(plan))
                // The sales bar rides on the ACTIVE card and nowhere else: it
                // measures the plan the shop is holding, and it is null for
                // every account that is not an A1 sales shop.
                _ActivePlanCard(
                  card: plan,
                  usage: plan.isSalesShop ? controller.salesUsage.value : null,
                  // The PURCHASE behind this card — it carries the refund
                  // window, which the catalog card knows nothing about.
                  purchase: controller.ownedPlanFor(plan),
                  controller: controller,
                )
              else
                _PlanCardTile(
                  card: plan,
                  index: index,
                  hasGstin: controller.hasBuyerGstin,
                  isOwned: false,
                  isSelected: controller.isSelected(plan),
                  isBusy: controller.isProcessing.value &&
                      controller.purchasingCode.value == plan.optionCode,
                  onTap: () => controller.select(plan),
                  // The clock belongs to the banner when there is one. Only
                  // when the banner is absent or silent does each card carry
                  // its own — otherwise the same deadline would tick in six
                  // places at once.
                  showOfferCountdown:
                      catalog.campaign?.hasCountdown != true,
                  onOfferExpired: controller.onOfferExpired,
                ),
          ],
        ),
      );
    });
  }
}

/// "Select a Contribution Plan" + the one-line reason to.
class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.selectContributionPlan.tr,
          fontSize: SizeConfig.size22,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          height: 1.2,
          maxLines: 2,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.contributionPlanSubtitle.tr,
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
          height: 1.35,
          maxLines: 3,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DISCOUNTS — the campaign banner, its countdown, and the coupon field.
//
// See docs/backend/ACCOUNT_PLAN_DISCOUNT_FLUTTER_GUIDE.md. Every colour, every
// word and every number below comes off the payload: a new festival is a row in
// the admin console, never a release of this app.
// ═══════════════════════════════════════════════════════════════

/// "Offer ends in 2d 21h 5m", ticking down from the SERVER's count.
///
/// It counts down from `ends_in_seconds` rather than diffing `ends_at` against
/// `DateTime.now()`, because a device clock a day out would otherwise either
/// hide a live sale or leave an expired one on screen. Every refetch delivers a
/// fresh server value and restarts the clock from it.
///
/// [onExpired] fires exactly once, when the count reaches zero — the offer is
/// over and the prices on screen have stopped being true.
class OfferCountdown extends StatefulWidget {
  const OfferCountdown({
    super.key,
    required this.endsInSeconds,
    required this.color,
    this.onExpired,
    this.fontSize,
  });

  /// Seconds remaining as the SERVER counted them.
  final int endsInSeconds;

  final Color color;
  final VoidCallback? onExpired;
  final double? fontSize;

  @override
  State<OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<OfferCountdown> {
  late int _left;
  Timer? _timer;

  /// [OfferCountdown.onExpired] refetches; the refetch rebuilds this widget.
  /// Without this latch a rebuild that arrives before the timer is torn down
  /// could fire a second refetch off the same expiry.
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant OfferCountdown old) {
    super.didUpdateWidget(old);
    // A refetch brought a fresh server count — restart from it rather than
    // carrying on from the local one, which has been drifting since it started.
    if (old.endsInSeconds != widget.endsInSeconds) _start();
  }

  void _start() {
    _timer?.cancel();
    _fired = false;
    _left = widget.endsInSeconds;
    if (_left <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left == 0 && !_fired) {
        _fired = true;
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    // A one-second timer left running behind a closed plans screen is a battery
    // cost and a stream of rebuilds nobody sees.
    _timer?.cancel();
    super.dispose();
  }

  /// Drops the units that no longer matter: days hide seconds, hours hide days.
  String get _label {
    final d = _left ~/ 86400;
    final h = (_left % 86400) ~/ 3600;
    final m = (_left % 3600) ~/ 60;
    final s = _left % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_left <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: SizeConfig.size14, color: widget.color),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          '${AppStrings.offerEndsIn.tr} $_label',
          fontSize: widget.fontSize ?? SizeConfig.size11,
          fontWeight: FontWeight.w700,
          color: widget.color,
        ),
      ],
    );
  }
}

/// The campaign banner above the catalog.
///
/// Wears the campaign's OWN colours and icon, with an app-palette fallback
/// behind every one of them: `theme` is admin-authored and every field in it
/// can be null or a typo, and a mis-typed colour must cost a wrong tint, never
/// the screen the user buys from.
class _CampaignBanner extends StatelessWidget {
  const _CampaignBanner({required this.campaign, required this.onExpired});

  final PlanCampaign campaign;

  /// Fired when the countdown runs out — the controller refetches, the prices
  /// go back to list, and this banner disappears with them.
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    final accent = campaign.theme.accent(AppColors.primaryColor);
    final bg = campaign.theme
        .background(AppColors.primaryColor.withValues(alpha: 0.08));
    final fg = campaign.theme.text(AppColors.mainTextColor);

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size14),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SizeConfig.size14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon is an EMOJI string from the DB, not an asset name — so it
          // renders as text, and a campaign that sent none gets a generic tag.
          CustomText(
            campaign.theme.icon ?? '🏷️',
            fontSize: SizeConfig.size22,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin copy, rendered verbatim — never run through `.tr`.
                CustomText(
                  campaign.bannerText,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  height: 1.25,
                  maxLines: 2,
                ),
                if (campaign.bannerSubtext.isNotEmpty) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    campaign.bannerSubtext,
                    fontSize: SizeConfig.size11,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.75),
                    height: 1.3,
                    maxLines: 2,
                  ),
                ],
                // Only when the server both asked for a clock and sent a
                // remaining time — an open-ended campaign still applies, it
                // just has no deadline to show.
                if (campaign.hasCountdown) ...[
                  SizedBox(height: SizeConfig.size8),
                  OfferCountdown(
                    endsInSeconds: campaign.endsInSeconds!,
                    color: accent,
                    onExpired: onExpired,
                  ),
                ],
              ],
            ),
          ),
          if (campaign.termsAndConditions.isNotEmpty) ...[
            SizedBox(width: SizeConfig.size6),
            GestureDetector(
              onTap: () => showCampaignTermsSheet(context, campaign),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                child: CustomText(
                  AppStrings.offerTerms.tr,
                  fontSize: SizeConfig.size10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The coupon field — the only way to reach a campaign the admin marked
/// coupon-only, which is invisible until the code is sent.
///
/// It applies nothing itself: the code goes to `GET /plans`, the server decides
/// whether anything comes back under it, and "invalid" here means only that
/// nothing did.
class _CouponField extends StatefulWidget {
  const _CouponField({required this.controller});

  final AccountPlanController controller;

  @override
  State<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<_CouponField> {
  late final TextEditingController _input =
      TextEditingController(text: widget.controller.couponCode.value);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    FocusScope.of(context).unfocus();
    final code = _input.text.trim();
    if (code.isEmpty) return;
    await widget.controller.applyCoupon(code);
  }

  Future<void> _clear() async {
    FocusScope.of(context).unfocus();
    _input.clear();
    await widget.controller.clearCoupon();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final applied = widget.controller.couponCode.value;
      final invalid = widget.controller.couponInvalid.value;
      final busy = widget.controller.isApplyingCoupon.value;
      // "Applied" means a code is live AND the catalog came back carrying it.
      final isLive = applied.isNotEmpty && !invalid;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size4,
            ),
            decoration: BoxDecoration(
              color: AccountPlanPalette.cardSurface,
              borderRadius: BorderRadius.circular(SizeConfig.size12),
              border: Border.all(
                color: isLive
                    ? AccountPlanPalette.tick.withValues(alpha: 0.55)
                    : (invalid
                        ? AccountPlanPalette.gstWarning.withValues(alpha: 0.45)
                        : AccountPlanPalette.cardBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: SizeConfig.size16,
                  color: isLive
                      ? AccountPlanPalette.tick
                      : AccountPlanPalette.muted,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !busy && !isLive,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _apply(),
                    style: TextStyle(
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w700,
                      color: AccountPlanPalette.heading,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: AppStrings.couponHint.tr,
                      hintStyle: TextStyle(
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w500,
                        color: AccountPlanPalette.muted,
                      ),
                    ),
                  ),
                ),
                if (busy)
                  SizedBox(
                    height: SizeConfig.size16,
                    width: SizeConfig.size16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryColor),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: isLive ? _clear : _apply,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size6,
                        vertical: SizeConfig.size8,
                      ),
                      child: CustomText(
                        isLive
                            ? AppStrings.couponRemove.tr
                            : AppStrings.couponApply.tr,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w800,
                        color: isLive
                            ? AccountPlanPalette.gstWarning
                            : AccountPlanPalette.link,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // The server's verdict, in both directions. Never our own rule about
          // what a valid code looks like.
          if (invalid) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              AppStrings.couponInvalid.tr,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w600,
              color: AccountPlanPalette.gstWarning,
              maxLines: 2,
            ),
          ] else if (isLive) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              AppStrings.couponAppliedFmt.trParams({'code': applied}),
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w700,
              color: AccountPlanPalette.tick,
              maxLines: 2,
            ),
          ],
        ],
      );
    });
  }
}

/// The CAMPAIGN's terms, rendered verbatim — separate from any plan's own.
void showCampaignTermsSheet(BuildContext context, PlanCampaign campaign) {
  _showTermsSheet(
    context,
    title: AppStrings.termsConditions.tr,
    subtitle: campaign.name,
    terms: campaign.termsAndConditions,
  );
}

/// The big headline, split into a number and its unit.
///
/// A radius plan's label arrives as "1 km" and the comp sets it as **1KM** with
/// a lighter "Radius" beside it. Anything that isn't that shape — "All India",
/// "Passenger + Parcel", "Pro" — is printed as it came, because the catalog
/// serves 138 account types and only some of them measure anything.
///
/// Shared by the buyable card and the active panel so one plan reads the same
/// way whichever of the two is drawing it.
({String title, String? unit}) _headlineOf(PlanCard card) {
  final match =
      RegExp(r'^\s*(\d+)\s*km\s*$', caseSensitive: false).firstMatch(card.label);
  if (match != null) {
    return (title: '${match.group(1)}KM', unit: AppStrings.radiusLabel.tr);
  }
  return (title: card.label, unit: null);
}

/// Keeps a numeric range on one line.
///
/// Left alone, the line breaker takes the dash as its break opportunity and
/// splits the range itself: "Sales 30–" / "40 Lakh", "Sales 1–" / "1.25 Cr". The
/// number the plan is NAMED for ends up straddling two lines and the first line
/// is left half empty. A word joiner either side moves the break to the space
/// instead — "Sales" / "30–40 Lakh".
///
/// U+2060 rather than swapping in a non-breaking hyphen: it is zero-width and
/// default-ignorable, so the API's own dash glyph is what renders, and a font
/// without the codepoint draws nothing rather than tofu.
String _unbreakableRanges(String value) => value.replaceAllMapped(
      RegExp(r'(\d)\s*([-–—])\s*(\d)'),
      // Escaped, not the literal character: U+2060 renders as nothing, so a
      // pasted one is invisible in this source and in any diff that touches it.
      (m) => '${m[1]}\u2060${m[2]}\u2060${m[3]}',
    );

/// Headline size for [value], stepped down from [base] when the label is too
/// long to sit on two lines at full size.
///
/// The comp's sizes were set for the short labels this catalog was built on —
/// "3 km", "Pro", "All India". The sales-band plans are three or four words
/// ("Sales 30–40 Lakh") and at full size the longest of them ellipsised, which
/// on a price card means the plan is no longer named. Two steps is enough for
/// everything the catalog currently sends, and short labels keep their intended
/// weight.
///
/// Length-driven rather than a `FittedBox`: scaling down a two-line paragraph to
/// fit its box shrinks it until BOTH lines fit, which on the narrow half of this
/// row lands far smaller than the sublabel beneath it.
double _headlineFontSize(String value, {required double base}) {
  final length = value.trim().length;
  if (length <= 14) return base;
  if (length <= 20) return base * 0.84;
  return base * 0.7;
}

/// One plan card: headline + price pill, the promise line, then the DB-driven
/// feature bullets, the GST condition, and the per-plan T&C link.
///
/// Everything visible here except the pill's colour comes off the API. The card
/// knows nothing about radii, job types or tiers by name — it reads whichever
/// of those the plan happens to carry and formats it.
class _PlanCardTile extends StatelessWidget {
  const _PlanCardTile({
    required this.card,
    required this.index,
    required this.hasGstin,
    required this.isOwned,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
    this.showOfferCountdown = false,
    this.onOfferExpired,
  });

  final PlanCard card;

  /// Whether this card carries the offer's clock.
  ///
  /// False whenever the campaign banner above is already counting the same
  /// deadline down: one page-level clock says it once, and a copy on every card
  /// would be the same sentence repeated five times — and five one-second
  /// timers rebuilding five cards.
  final bool showOfferCountdown;

  /// Fired when this card's own countdown runs out.
  final VoidCallback? onOfferExpired;

  /// Position in the catalog — picks the price pill's gradient.
  final int index;

  /// Whether the buyer already has a GSTIN on hand. Decides whether this card's
  /// GST condition reads as a warning or as a satisfied requirement.
  final bool hasGstin;

  final bool isOwned;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;

  /// Whether this card can be picked up by the pay bar at all.
  bool get _selectable => card.isPurchasable && !isOwned;

  /// Whether to paint the recommendation at all.
  ///
  /// Suppressed once the plan is owned — a plan you already hold is not a
  /// suggestion, and the green "Active" treatment is the more useful thing to
  /// say about it. The selected case needs no check here: the decoration below
  /// tests `isSelected` first, so blue simply wins.
  bool get _showPopular => card.popular && !isOwned;

  ({String title, String? unit}) get _headline => _headlineOf(card);

  /// The bold promise under the title.
  ///
  /// Prefers the API's `sublabel`; gig plans send an empty one, so the first
  /// feature is promoted instead (it reads as the promise — "Receive Passenger
  /// Ride Jobs") and then dropped from the bullets below so it isn't said
  /// twice.
  String? get _promise {
    final sublabel = card.sublabel;
    if (sublabel != null && sublabel.isNotEmpty) return sublabel;
    return card.features.isNotEmpty ? card.features.first : null;
  }

  List<String> get _bullets {
    final promoted = (card.sublabel == null || card.sublabel!.isEmpty) &&
        card.features.isNotEmpty;
    return promoted ? card.features.skip(1).toList() : card.features;
  }

  @override
  Widget build(BuildContext context) {
    final headline = _headline;
    final promise = _promise;
    final bullets = _bullets;
    // The trailing rows: every feature, then the GST condition if the plan
    // carries one. The last of them also holds the T&C link, which is how the
    // comp keeps that link tucked against the card's bottom-right corner
    // instead of on a line of its own.
    final rowCount = bullets.length + (card.requiresGst ? 1 : 0);
    // A plan with no terms gets no link — and then no empty slot reserved for
    // one either. During a sale there can be TWO: the plan's terms and the
    // campaign's are separate documents, so they get separate links rather than
    // one that quietly concatenates them.
    final hasTerms = card.termsAndConditions.isNotEmpty ||
        (card.showsOffer && card.discount!.termsAndConditions.isNotEmpty);
    final terms = hasTerms ? _TermsLinks(card: card) : null;

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectable ? onTap : null,
          borderRadius: BorderRadius.circular(SizeConfig.size16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(SizeConfig.size16),
            // Four looks, in strict precedence: SELECTED (blue) beats OWNED
            // (green) beats POPULAR (amber) beats plain. Selection has to win —
            // it is the state the pay bar acts on, and a recommendation that
            // out-shouted the user's own choice would make the CTA ambiguous.
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF4FAFF)
                  : (_showPopular
                      ? AccountPlanPalette.popularSurface
                      : AccountPlanPalette.cardSurface),
              borderRadius: BorderRadius.circular(SizeConfig.size16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : (isOwned
                        ? AppColors.green00.withValues(alpha: 0.55)
                        : (_showPopular
                            ? AccountPlanPalette.popular
                                .withValues(alpha: 0.65)
                            : AccountPlanPalette.cardBorder)),
                width: isSelected ? 1.6 : (_showPopular ? 1.4 : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.16)
                      : (_showPopular
                          ? AccountPlanPalette.popular.withValues(alpha: 0.18)
                          : const Color(0x14102A43)),
                  blurRadius: isSelected ? 16 : (_showPopular ? 14 : 10),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The offer ribbon and the backend's recommended pick, side by
                // side above the headline rather than over the card's corner:
                // the corner is already the price pill's, and a ribbon crossing
                // it would obscure the one number the card exists to show.
                //
                // A Wrap, not a Row — a long `badge_text` ("FLAT ₹2,000 OFF")
                // beside POPULAR overflows a narrow card, and admin copy has no
                // length limit.
                if (card.showsOffer || _showPopular) ...[
                  Wrap(
                    spacing: SizeConfig.size8,
                    runSpacing: SizeConfig.size6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (card.showsOffer) _OfferRibbon(discount: card.discount!),
                      if (_showPopular) const _PopularBadge(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _Headline(
                        title: headline.title,
                        unit: headline.unit,
                        vehicleClass: card.vehicleClass,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    _PricePill(
                      card: card,
                      gradient: AccountPlanPalette.pricePillFor(index),
                      isBusy: isBusy,
                    ),
                  ],
                ),
                if (isOwned) ...[
                  SizedBox(height: SizeConfig.size10),
                  const _ActiveBadge(),
                ],
                // The offer's own deadline, when no banner above is already
                // counting it down (a coupon-scoped offer has no banner).
                if (showOfferCountdown &&
                    card.showsOffer &&
                    card.discount!.hasCountdown) ...[
                  SizedBox(height: SizeConfig.size10),
                  OfferCountdown(
                    endsInSeconds: card.discount!.endsInSeconds!,
                    color: card.discount!.theme.accent(AppColors.primaryColor),
                    onExpired: onOfferExpired,
                  ),
                ],
                if (promise != null) ...[
                  SizedBox(height: SizeConfig.size12),
                  _PromiseLine(text: promise, isSelected: isSelected),
                ],
                if (rowCount > 0) ...[
                  SizedBox(height: SizeConfig.size12),
                  const _DashedDivider(),
                  SizedBox(height: SizeConfig.size12),
                  for (final (i, feature) in bullets.indexed)
                    _FeatureRow(
                      text: feature,
                      // Only the very last row carries the link.
                      trailing: (i == rowCount - 1) ? terms : null,
                    ),
                  if (card.requiresGst)
                    _GstRequiredRow(satisfied: hasGstin, trailing: terms),
                ] else if (terms != null) ...[
                  // Nothing to list — the link still needs somewhere to live.
                  SizedBox(height: SizeConfig.size10),
                  Align(alignment: Alignment.centerRight, child: terms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The offer ribbon — "30% OFF", or whatever copy the admin wrote.
///
/// Wears the campaign's accent as a filled chip, which is the loudest thing on
/// a white card and is meant to be: it is the reason the price beside it is
/// lower than the one struck through above it.
class _OfferRibbon extends StatelessWidget {
  const _OfferRibbon({required this.discount});

  final CardDiscount discount;

  @override
  Widget build(BuildContext context) {
    final accent = discount.theme.accent(AppColors.primaryColor);
    // `badge_text` is admin copy and stands alone; the fallback is built from
    // the REALISED percentage (`percent_off`), never the campaign's headline
    // `value` — a capped campaign realises less than it advertises, and the
    // card must promise only what the price delivers.
    final label = discount.badgeText.isNotEmpty
        ? discount.badgeText
        : '${discount.badgeOrPercent} ${AppStrings.offSuffix.tr}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(SizeConfig.size6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (discount.theme.icon != null) ...[
            CustomText(discount.theme.icon!, fontSize: SizeConfig.size12),
            SizedBox(width: SizeConfig.size4),
          ],
          CustomText(
            label,
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// "POPULAR" — the backend's `popular: true` pick, one per group.
///
/// Cosmetic only: it changes no price and no purchase path (see the guide,
/// §2.1). Amber so it reads as a recommendation rather than as a state — green
/// on this card already means "owned" and blue means "selected".
class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AccountPlanPalette.popularLight,
            AccountPlanPalette.popular,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(SizeConfig.size20),
        boxShadow: [
          BoxShadow(
            color: AccountPlanPalette.popular.withValues(alpha: 0.30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: Colors.white),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            AppStrings.popularTier.tr,
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// "1KM Radius" — the number carries the weight, the unit sits back.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.title,
    required this.unit,
    required this.vehicleClass,
  });

  final String title;
  final String? unit;

  /// The one bit of context a gig label leaves out ("Passenger" on a BIKE vs a
  /// CAR). Absent on shop plans, where the eyebrow simply doesn't render.
  final String? vehicleClass;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((vehicleClass ?? '').isNotEmpty) ...[
          CustomText(
            vehicleClass!.toUpperCase(),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AccountPlanPalette.muted,
          ),
          SizedBox(height: SizeConfig.size4),
        ],
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CustomText(
              _unbreakableRanges(title),
              fontSize: _headlineFontSize(title, base: SizeConfig.size26),
              fontWeight: FontWeight.w800,
              color: AccountPlanPalette.heading,
              height: 1.1,
              maxLines: 2,
              // A label long enough to not fit beside the price pill clips
              // cleanly instead of painting into it.
              overflow: TextOverflow.ellipsis,
            ),
            if (unit != null) ...[
              SizedBox(width: SizeConfig.size6),
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.size4),
                child: CustomText(
                  unit!,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w500,
                  color: AccountPlanPalette.muted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The price, as a gradient capsule — "₹ 500" and what the payment buys — with
/// the GST called out beneath it.
///
/// The capsule headlines the BASE price, not the total, and the line under it
/// adds "+ ₹90 (18% GST)". That split is the guide's rule (§2.1): the card
/// shows price + GST so the tax is never a surprise, and the total is stated
/// once, at payment time, in [_PayBarSummary] — which is also the only figure
/// that gets charged, and the backend owns it.
///
/// ## During a sale
///
/// Every live figure here reads `final_*`, which is what the buyer will be
/// charged and which equals the list price exactly when nothing is running.
/// The LIST price survives only above the capsule, struck through, and only
/// when there is a real saving to strike it for. GST follows the discount —
/// tax is levied on the reduced base — so the line beneath quotes
/// `final_gst_amount` too, and "You save ₹X" states the difference the server
/// computed rather than one worked out here.
class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.card,
    required this.gradient,
    required this.isBusy,
  });

  final PlanCard card;
  final List<Color> gradient;
  final bool isBusy;

  /// Paise → rupees, dropping a trailing `.00` so whole prices read cleanly.
  String _rupees(int paise) {
    final v = paise / 100;
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
  }

  /// What the payment covers — how LONG it lasts, said in the backend's own
  /// words.
  ///
  /// The caption sits immediately after the price, so it is read as the unit
  /// the price is charged in. That is why the job-type count that used to live
  /// here was wrong: a one-job-type gig plan rendered "₹ 200 Per Job", which
  /// states per-job billing for what is a one-time, lifetime purchase. The
  /// plan's `validity_days` ("Life Time") is the honest thing to put next to a
  /// price, and it needs no app release when the backend changes the wording.
  ///
  /// The job-type counts remain only as a fallback for a plan that carries no
  /// validity at all, and [AppStrings.perJobLabel] is deliberately no longer
  /// among them — see [_jobBundleCaption].
  String get _caption {
    final label = card.validityLabel;
    if (label != null && label.isNotEmpty) return label;
    if (card.isLifetime) return AppStrings.lifeTimeLabel.tr;
    if (card.validityDays != null) {
      return AppStrings.planValidDaysFmt
          .trParams({'days': '${card.validityDays}'});
    }
    return _jobBundleCaption;
  }

  /// The old caption, kept for a plan with no validity of any kind.
  ///
  /// "Per Job" is gone from it: whatever it was meant to say about a
  /// single-job-type plan, beside a price it only ever read as a billing rate.
  /// One job type now says the same "One Time" every other unbounded plan does.
  String get _jobBundleCaption {
    final jobs = card.jobTypes ?? const <String>[];
    if (jobs.length == 2) return AppStrings.combinationLabel.tr;
    if (jobs.length > 2) return AppStrings.fullCombinationLabel.tr;
    return AppStrings.oneTimeLabel.tr;
  }

  @override
  Widget build(BuildContext context) {
    if (!card.isPurchasable) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: AppColors.green00.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(color: AppColors.green00.withValues(alpha: 0.35)),
        ),
        child: CustomText(
          AppStrings.planFree.tr,
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w800,
          color: AppColors.green00,
        ),
      );
    }

    final offer = card.showsOffer ? card.discount! : null;
    final accent = offer?.theme.accent(AppColors.primaryColor) ??
        AppColors.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // What it used to cost. Struck through, muted, and only ever drawn when
        // there is a saving — this is the one place the LIST price still
        // appears on a card during a sale.
        if (offer != null) ...[
          CustomText(
            '${AppConstants.rupeeSymbol}${_rupees(card.priceBase)}',
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w600,
            color: AccountPlanPalette.muted,
            decoration: TextDecoration.lineThrough,
            decorationColor: AccountPlanPalette.muted,
          ),
          SizedBox(height: SizeConfig.size2),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.size20),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy) ...[
                const SizedBox(
                  height: 13,
                  width: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
              ],
              // The LIVE price — `final_*`, always. Equal to the list price
              // when no campaign is running, so this is correct either way.
              CustomText(
                '${AppConstants.rupeeSymbol} ${_rupees(card.finalPriceBase)}',
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                _caption,
                fontSize: SizeConfig.size11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
        // "+ ₹27 (18% GST)" — on the DISCOUNTED base, because that is what the
        // tax is levied on. Skipped when the backend priced the tax at zero,
        // rather than printing a "+ ₹0" that only raises a question.
        if (card.finalGstAmount > 0) ...[
          SizedBox(height: SizeConfig.size4),
          CustomText(
            '+ ${AppConstants.rupeeSymbol}${_rupees(card.finalGstAmount)}'
            ' (${card.gstPercent}${AppStrings.gstSuffix.tr})',
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w600,
            color: AccountPlanPalette.muted,
          ),
        ],
        // The saving, as the server computed it — never `list - final` worked
        // out here, which would disagree with the server the moment a cap or a
        // rounding rule applied.
        if (offer != null) ...[
          SizedBox(height: SizeConfig.size4),
          CustomText(
            '${AppStrings.youSave.tr} '
            '${AppConstants.rupeeSymbol}${_rupees(offer.discountAmount)}',
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ],
      ],
    );
  }
}

/// The bold line under the title — the plan's promise in one sentence.
class _PromiseLine extends StatelessWidget {
  const _PromiseLine({required this.text, required this.isSelected});

  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isSelected
              ? Icons.check_circle_rounded
              : Icons.check_circle_outline_rounded,
          size: SizeConfig.size18,
          color: isSelected
              ? AppColors.primaryColor
              : AccountPlanPalette.heading,
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.size14,
            fontWeight: FontWeight.w700,
            color: AccountPlanPalette.heading,
            height: 1.3,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

/// One DB-driven feature bullet, optionally carrying the T&C link on its right.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: SizeConfig.size16,
            color: AccountPlanPalette.tick,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w500,
              color: AccountPlanPalette.featureText,
              height: 1.35,
              maxLines: 3,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: SizeConfig.size8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// The GST condition, in the same bullet rhythm but warm — it is the one line
/// that can disqualify a buyer who read everything else and was satisfied.
///
/// Once the buyer HAS a GSTIN the condition is met, so the row drops to the
/// same green tick as any other feature. Leaving it red would warn an account
/// about a requirement it already satisfies, and the buyer would reasonably
/// read that as "I can't buy this".
class _GstRequiredRow extends StatelessWidget {
  const _GstRequiredRow({required this.satisfied, this.trailing});

  final bool satisfied;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.help_rounded,
            size: SizeConfig.size16,
            color: satisfied
                ? AccountPlanPalette.tick
                : AccountPlanPalette.gstWarning,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              satisfied
                  ? AppStrings.gstOnFile.tr
                  : AppStrings.gstRequired.tr,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w700,
              color: satisfied
                  ? AccountPlanPalette.featureText
                  : AccountPlanPalette.gstWarning,
              maxLines: 2,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: SizeConfig.size8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// THE ACTIVE PLAN — the plan the user already holds, drawn as a filled
/// gradient panel at the top of the catalog.
///
/// ## Why it looks nothing like its neighbours
///
/// It used to be an ordinary white card wearing a small green stamp, sitting
/// wherever the backend happened to order it. That asked the merchant to read
/// every card to find out what they already had. This card is the one thing on
/// the sheet that is NOT for sale, so it stops pretending to be a choice: it is
/// the only filled surface among white ones, and it leads the list. Nothing
/// else on the screen changed — the contrast is the whole point and it is spent
/// once.
///
/// ## The motion
///
/// A light sweep crosses the panel about every four seconds, and the dot beside
/// "Active" breathes with it. Both say the same thing — this plan is running
/// right now — and the pulse is the vocabulary the app already uses for live
/// state on the rider bar. One orchestrated moment, no hover tricks, nothing
/// that competes with the pay bar below.
///
/// Motion is dropped entirely when the platform asks for reduced motion; the
/// panel then stands on its gradient alone, which was designed to work still.
class _ActivePlanCard extends StatefulWidget {
  const _ActivePlanCard({
    required this.card,
    this.usage,
    this.purchase,
    this.controller,
  });

  final PlanCard card;

  /// Sales consumed against this plan's cap — A1 sales shops only, and null
  /// until `sales/usage` has answered. See [_SalesUsageMeter].
  final SalesUsage? usage;

  /// The user's purchase of [card] — the object that carries the refund
  /// window. Null while `my-plans` is still loading, which simply means no
  /// refund control yet.
  final UserAccountPlan? purchase;

  /// Needed only to submit a refund request. Null in any preview that has no
  /// controller to talk to, which also hides the control.
  final AccountPlanController? controller;

  @override
  State<_ActivePlanCard> createState() => _ActivePlanCardState();
}

class _ActivePlanCardState extends State<_ActivePlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  /// Whether the ticker is currently allowed to run. Read from MediaQuery, so
  /// it is re-evaluated when the platform setting changes mid-session.
  bool _animating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowed = !MediaQuery.disableAnimationsOf(context);
    if (allowed == _animating) return;
    _animating = allowed;
    if (allowed) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final headline = _headlineOf(card);
    final promise = card.sublabel?.isNotEmpty == true
        ? card.sublabel!
        : (card.features.isNotEmpty ? card.features.first : null);
    final bullets = (card.sublabel == null || card.sublabel!.isEmpty)
        ? card.features.skip(1).toList()
        : card.features;

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SizeConfig.size18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AccountPlanPalette.activePanel,
          ),
          boxShadow: [
            BoxShadow(
              color: AccountPlanPalette.activePanel.last
                  .withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The sweep rides behind the content, so type never dims.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _SweepPainter(progress: _controller.value),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActiveEyebrow(pulse: _controller),
                  SizedBox(height: SizeConfig.size12),
                  // The plan itself, set as large as the buyable cards set
                  // their price — on this card the plan IS the headline,
                  // because there is no longer a price to lead with.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: CustomText(
                          _unbreakableRanges(headline.title),
                          fontSize: _headlineFontSize(
                            headline.title,
                            base: SizeConfig.size30,
                          ),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (headline.unit != null) ...[
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          headline.unit!,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ],
                    ],
                  ),
                  if (promise != null) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      promise,
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                      maxLines: 3,
                    ),
                  ],
                  if (bullets.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size14),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    SizedBox(height: SizeConfig.size12),
                    for (final feature in bullets)
                      Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: SizeConfig.size2),
                              child: Icon(
                                Icons.check_rounded,
                                size: SizeConfig.size16,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: CustomText(
                                feature,
                                fontSize: SizeConfig.size13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.90),
                                height: 1.35,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // How much of the sales cap is spent. A1 sales plans only —
                  // this is the one plan shape that ends by being used up
                  // rather than by a date, so it is the one that needs a meter.
                  if (widget.usage != null) ...[
                    SizedBox(height: SizeConfig.size14),
                    _SalesUsageMeter(usage: widget.usage!),
                  ],
                  // "Bought in Diwali Dhamaka — you saved ₹1,079".
                  //
                  // Read from the purchase's FROZEN snapshot, not from any live
                  // campaign: the offer that bought this plan may have ended
                  // months ago, and what the merchant paid does not change when
                  // it does. That is exactly why the line is worth keeping —
                  // it is the one place the saving survives.
                  if (widget.purchase?.boughtOnOffer == true) ...[
                    SizedBox(height: SizeConfig.size12),
                    _BoughtOnOfferLine(purchase: widget.purchase!),
                  ],
                  // Refund on this purchase. Drawn from the server's `refund`
                  // object alone — see [_RefundControl].
                  if (widget.purchase != null && widget.controller != null)
                    _RefundControl(
                      plan: widget.purchase!,
                      controller: widget.controller!,
                    ),
                  // Validity, when the plan carries one. No price line: a
                  // migrated plan was activated free, and stamping an amount
                  // on a card the user may never have paid would be a claim
                  // this screen cannot make.
                  if (_validityChipLabel(card) != null) ...[
                    SizedBox(height: SizeConfig.size4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                        vertical: SizeConfig.size4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(SizeConfig.size20),
                      ),
                      child: CustomText(
                        _validityChipLabel(card)!,
                        fontSize: SizeConfig.size11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The validity chip on the active plan panel — "Life Time", or "Valid for 30
/// days" — or null when the plan states no validity and the chip is skipped.
///
/// Shared by the gate and the label so the two cannot disagree: the chip used
/// to be gated on `validityDays != null` while a lifetime plan parsed to `0`,
/// which is not null, so it rendered "Valid for 0 days".
String? _validityChipLabel(PlanCard card) {
  final label = card.validityLabel;
  if (label != null && label.isNotEmpty) return label;
  if (card.isLifetime) return AppStrings.lifeTimeLabel.tr;
  final days = card.validityDays;
  if (days != null) {
    return AppStrings.planValidDaysFmt.trParams({'days': '$days'});
  }
  return null;
}

/// "🏷️ Bought in Diwali Dhamaka — you saved ₹1,079" on the active plan panel.
///
/// A permanent receipt line, not an advertisement: it states what this purchase
/// cost against what the tier lists at, and it stays true after the campaign is
/// gone, because the purchase carries its own frozen copy of the campaign.
class _BoughtOnOfferLine extends StatelessWidget {
  const _BoughtOnOfferLine({required this.purchase});

  final UserAccountPlan purchase;

  /// PAISE → rupees, the same rule as every other price on this surface.
  String _rupees(int paise) {
    final v = paise / 100;
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(SizeConfig.size8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: SizeConfig.size14,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              // The campaign's name is admin copy and goes in verbatim; only
              // the words around it are translated.
              '${AppStrings.boughtInOffer.tr} ${purchase.discountTitle} — '
              '${AppStrings.youSaved.tr} ${AppConstants.rupeeSymbol}'
              '${_rupees(purchase.discountAmount)}',
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.3,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// "₹2,40,000 of ₹6,00,000 sales used" — the A1 sales plan's meter.
///
/// The active panel's deepest green, used as INK on a white plate.
///
/// Written as a literal rather than `AccountPlanPalette.activePanel.first`
/// because a list element is not a compile-time constant, and this has to be
/// const to sit inside a `const Icon`. It is the same value — keep the two in
/// step if the panel gradient is ever retuned.
const Color _refundInk = Color(0xFF0B4C3C);

/// The refund control on the active plan card.
///
/// Every state here is READ from the server's `refund` object (guide §2.2.2) —
/// this widget decides nothing. `can_request_refund` is the only thing that
/// enables the button; the dates are used for wording a DISABLED one and never
/// for unlocking it, so a device with a wrong clock cannot talk its way into a
/// request the server would refuse anyway.
///
/// Hidden entirely when refunds are switched off backend-side, and for free
/// plans, which took no money to give back.
///
/// ## Two states, two shapes
///
/// This used to be one outlined pill for every state, which failed both of
/// them. The pill was green-on-green — a 55%-white outline over the panel's own
/// gradient — so the ONE state that can be tapped looked disabled; and the
/// states that cannot be tapped (which is nearly always, the window opening six
/// months after activation) looked like buttons that did nothing.
///
/// So the shape now follows the job: an action gets a real control (white
/// plate, green label, the highest contrast this card has to offer), and a fact
/// gets a line of text with an icon. A label labels, a button acts.
class _RefundControl extends StatelessWidget {
  const _RefundControl({required this.plan, required this.controller});

  final UserAccountPlan plan;
  final AccountPlanController controller;

  @override
  Widget build(BuildContext context) {
    final refund = plan.refund;
    if (!refund.isVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          SizedBox(height: SizeConfig.size12),
          // Two states, two shapes — see the class doc.
          if (refund.canRequestRefund) _action(context) else _note(refund),
        ],
      ),
    );
  }

  /// The rare, actionable state: a white plate with the card's own deep green
  /// on it.
  ///
  /// White is the only value that reads instantly on a saturated green field —
  /// the outlined pill this replaces was green-on-green at 55% white, which
  /// looked disabled at exactly the moment it was not. Green TEXT rather than a
  /// new accent keeps the control inside the card's palette instead of
  /// importing a second hue for one button.
  Widget _action(BuildContext context) {
    return Obx(() {
      final busy = controller.isRequestingRefund.value;
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        child: InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          onTap: busy ? null : () => _confirm(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _refundInk,
                    ),
                  )
                else
                  const Icon(
                    Icons.assignment_return_outlined,
                    size: 17,
                    color: _refundInk,
                  ),
                SizedBox(width: SizeConfig.size8),
                CustomText(
                  AppStrings.requestRefund.tr,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w800,
                  color: _refundInk,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Every other state — and the one nearly every merchant sees, since the
  /// window opens six months after activation.
  ///
  /// Deliberately NOT a button. "Refund available after 19 Feb 2027" is a fact,
  /// not an offer, and drawing it inside a pill invited a tap that could never
  /// land. Left-aligned with a small icon, it reads as the note it is; the
  /// button shape is reserved for the one state that can be pressed.
  Widget _note(PlanRefund refund) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            _icon(refund),
            size: SizeConfig.size14,
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: CustomText(
            _label(refund),
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.35,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// The note's wording, in the order the guide lists the states.
  String _label(PlanRefund refund) {
    if (refund.isRequested) return AppStrings.refundUnderReview.tr;
    if (refund.isSettled) {
      return AppStrings.refundedAmountFmt
          .trParams({'amount': '${refund.refundableAmountInr}'});
    }
    if (refund.isRejected) return AppStrings.refundDeclined.tr;
    if (refund.isPending) {
      // The guide's exact wording: the server's day count, with the date it
      // lands on in brackets. The count is what a waiting merchant actually
      // reads — "after 19 Feb 2027" makes them do the arithmetic themselves.
      final days = refund.daysUntilEligible;
      final date = _date(refund.refundEligibleAt);
      if (days == null) {
        return AppStrings.refundAvailableAfterFmt.trParams({'date': date});
      }
      if (days == 1) {
        return AppStrings.refundAvailableInOneDayFmt.trParams({'date': date});
      }
      return AppStrings.refundAvailableInDaysFmt
          .trParams({'days': '$days', 'date': date});
    }
    // Expired, or a state the server gave no date to explain. "Closed" is the
    // one thing true of every remaining case.
    return AppStrings.refundWindowClosed.tr;
  }

  IconData _icon(PlanRefund refund) {
    if (refund.isRequested) return Icons.hourglass_top_rounded;
    if (refund.isSettled) return Icons.check_circle_outline_rounded;
    if (refund.isRejected) return Icons.cancel_outlined;
    return Icons.schedule_rounded;
  }

  static String _date(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[(local.month - 1).clamp(0, 11)]} '
        '${local.year}';
  }

  /// The terms the guide requires, stated BEFORE the user commits rather than
  /// after. `tnc_accepted: true` on the request is this sheet having been
  /// accepted, so it is not optional chrome.
  void _confirm(BuildContext context) {
    final refund = plan.refund;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size20,
            SizeConfig.size16,
            SizeConfig.size20,
            SizeConfig.size20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(
                AppStrings.refundConfirmTitle.tr,
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size6),
              CustomText(
                plan.optionLabel,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size12),
              // The amount is the server's, and it is the BASE fee — GST is not
              // refunded, which the body says in the same breath so the two
              // numbers are never a surprise at settlement.
              if (refund.refundableAmountInr > 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                  ),
                  child: CustomText(
                    AppStrings.refundConfirmAmountFmt
                        .trParams({'amount': '${refund.refundableAmountInr}'}),
                    fontSize: SizeConfig.size15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                AppStrings.refundConfirmBody.tr,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                height: 1.45,
                maxLines: 8,
              ),
              if (refund.refundWindowClosesAt != null) ...[
                SizedBox(height: SizeConfig.size10),
                CustomText(
                  AppStrings.refundCloseByFmt
                      .trParams({'date': _date(refund.refundWindowClosesAt)}),
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
              SizedBox(height: SizeConfig.size20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.size14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                        ),
                      ),
                      child: CustomText(
                        AppStrings.cancel.tr,
                        fontSize: SizeConfig.size13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        controller.requestRefund(plan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.size14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                        ),
                      ),
                      child: CustomText(
                        AppStrings.requestRefund.tr,
                        fontSize: SizeConfig.size13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sales plan doesn't expire on a date; it expires when the shop has sold
/// through its cap, at which point the backend deactivates it and orders stop.
/// That makes the remaining headroom the single most useful thing on this card,
/// and it is invisible without a meter — a merchant would otherwise find out by
/// going dark.
///
/// Drawn INSIDE the active (green) panel, so everything is white-on-green:
/// the track is a white wash, the fill is solid white, and the warning states
/// change the copy rather than the colour — a red bar on a green card would
/// read as the card being broken.
///
/// All amounts here are RUPEES, straight from the endpoint. See [SalesUsage].
class _SalesUsageMeter extends StatelessWidget {
  const _SalesUsageMeter({required this.usage});

  final SalesUsage usage;

  /// Indian digit grouping — ₹2,40,000, not ₹240,000. The last three digits
  /// group, then pairs, which is what every other rupee figure in the app and
  /// on the invoice does.
  static String _inr(int amount) {
    final digits = amount.abs().toString();
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    const rupee = AppConstants.rupeeSymbol;
    // Exhausted first: once the cap is spent, "20% left" is no longer the
    // useful sentence, "upgrade to keep receiving orders" is.
    final note = usage.isExhausted
        ? AppStrings.salesLimitReachedNote.tr
        : usage.isNearLimit
            ? AppStrings.salesNearLimitNote.tr
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
        SizedBox(height: SizeConfig.size12),
        Row(
          children: [
            Expanded(
              child: CustomText(
                AppStrings.salesUsedFmt.trParams({
                  'used': '$rupee${_inr(usage.salesAccruedInr)}',
                  'limit': '$rupee${_inr(usage.saleLimitInr)}',
                }),
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
                maxLines: 2,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              '${usage.percentUsed}%',
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        ClipRRect(
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          child: LinearProgressIndicator(
            value: usage.fraction,
            minHeight: SizeConfig.size8,
            // 0.30, not 0.22: a brand-new plan sits at 0%, where the track IS
            // the whole widget. At 22% white on this gradient it read as a
            // faint smudge, so the one card that most needs to say "nothing
            // used yet" was the one that showed nothing at all.
            backgroundColor: Colors.white.withValues(alpha: 0.30),
            valueColor: AlwaysStoppedAnimation<Color>(
              // Amber once it is nearly spent: still legible on green, and the
              // only place on this card that stops being plain white.
              usage.isNearLimit
                  ? AccountPlanPalette.popularLight
                  : Colors.white,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.salesRemainingFmt
              .trParams({'amount': '$rupee${_inr(usage.salesRemainingInr)}'}),
          fontSize: SizeConfig.size11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.80),
        ),
        if (note != null) ...[
          SizedBox(height: SizeConfig.size6),
          CustomText(
            note,
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
            maxLines: 3,
          ),
        ],
      ],
    );
  }
}

/// "Your plan · Active", with the breathing dot.
class _ActiveEyebrow extends StatelessWidget {
  const _ActiveEyebrow({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            // Two beats per sweep, so the dot and the light agree.
            final t = (1 - ((pulse.value * 2) % 1 - 0.5).abs() * 2);
            final glow = 0.35 + t * 0.55;
            return Container(
              width: SizeConfig.size8,
              height: SizeConfig.size8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: glow),
                    blurRadius: 6 + t * 4,
                    spreadRadius: t * 1.5,
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(width: SizeConfig.size8),
        CustomText(
          AppStrings.yourPlanLabel.tr,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.82),
          letterSpacing: 0.6,
        ),
        SizedBox(width: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(SizeConfig.size20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: CustomText(
            AppStrings.planActive.tr,
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// The light that crosses the panel: a wide, soft diagonal band, drawn once per
/// frame at [progress] through its travel.
///
/// A gradient band rather than an opacity flash — a flashing card reads as an
/// alert, and this plan is not asking for anything. It runs off both edges so
/// there is no visible start or end to the pass.
class _SweepPainter extends CustomPainter {
  const _SweepPainter({required this.progress});

  /// 0 → 1 across one full pass.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Travels from off the left edge to off the right, over 1.6 widths, so the
    // band is fully gone before it reappears.
    final dx = (progress * 2.6 - 0.8) * size.width;
    final rect = Rect.fromLTWH(dx, -size.height, size.width * 0.55,
        size.height * 3);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x24FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.save();
    // Tilted so the light reads as falling across the card rather than wiping
    // it, which is what separates a sheen from a loading shimmer.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.32);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Green "Active" stamp for a plan the user already holds.
// ignore: unused_element
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: AppColors.green00.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SizeConfig.size20),
        border: Border.all(color: AppColors.green00.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: SizeConfig.size14, color: AppColors.green00),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            AppStrings.planActive.tr,
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w800,
            color: AppColors.green00,
          ),
        ],
      ),
    );
  }
}

/// `*T&C` — opens the plan's own terms. Rendered only when the API sent some,
/// so a plan without terms doesn't advertise an empty sheet.
/// The card's terms links, tucked against its bottom-right corner.
///
/// Up to two, and deliberately not merged: the plan's terms describe what the
/// plan is, the campaign's describe what the offer is, and they have different
/// lifetimes — the offer's stop applying when the campaign ends while the
/// plan's do not. Concatenating them into one sheet would present a temporary
/// document as part of a permanent one.
class _TermsLinks extends StatelessWidget {
  const _TermsLinks({required this.card});

  final PlanCard card;

  @override
  Widget build(BuildContext context) {
    final offer = card.showsOffer ? card.discount! : null;
    final offerTerms = offer?.termsAndConditions ?? const <String>[];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (card.termsAndConditions.isNotEmpty)
          _TermsLink(
            label: AppStrings.tcStar.tr,
            color: AccountPlanPalette.link,
            onTap: () => showAccountPlanTermsSheet(context, card),
          ),
        if (offerTerms.isNotEmpty) ...[
          if (card.termsAndConditions.isNotEmpty)
            SizedBox(width: SizeConfig.size10),
          _TermsLink(
            label: AppStrings.offerTerms.tr,
            // The campaign's own accent, so the link reads as belonging to the
            // ribbon and the banner rather than to the plan.
            color: offer!.theme.accent(AccountPlanPalette.link),
            onTap: () => _showTermsSheet(
              context,
              title: AppStrings.termsConditions.tr,
              subtitle: offer.name,
              terms: offerTerms,
            ),
          ),
        ],
      ],
    );
  }
}

class _TermsLink extends StatelessWidget {
  const _TermsLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Widens the tap target without moving the text off the comp's
        // bottom-right corner.
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        child: CustomText(
          label,
          fontSize: SizeConfig.size11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// The plan's `terms_and_conditions`, rendered verbatim.
void showAccountPlanTermsSheet(BuildContext context, PlanCard card) {
  _showTermsSheet(
    context,
    title: AppStrings.termsConditions.tr,
    subtitle: card.label,
    terms: card.termsAndConditions,
  );
}

/// One sheet for both kinds of terms — a plan's and a campaign's.
///
/// They are genuinely separate documents (a card during a sale can carry both,
/// behind two links), but they are read the same way, so they are presented the
/// same way. [terms] is admin-authored in either case and is never translated.
void _showTermsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<String> terms,
}) {
  if (terms.isEmpty) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size20,
            SizeConfig.size16,
            SizeConfig.size20,
            SizeConfig.size24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AccountPlanPalette.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(
                title,
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                subtitle,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: AccountPlanPalette.muted,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.size16),
              for (final term in terms)
                Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: SizeConfig.size6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AccountPlanPalette.muted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CustomText(
                          term,
                          fontSize: SizeConfig.size13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          height: 1.4,
                          maxLines: 8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The pinned "Kindly Contribute Us" bar.
///
/// One CTA for the whole list: it buys whatever card is selected, which is why
/// selection lives on the controller rather than in the list's state. Disabled
/// while a checkout is open, and while there is nothing left to buy (every plan
/// already owned).
class AccountPlanPayBar extends StatelessWidget {
  const AccountPlanPayBar({super.key, required this.controller});

  final AccountPlanController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isProcessing.value;
      final card = controller.selectedCard;
      final enabled = !busy && card != null;
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A102A43),
              blurRadius: 14,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              SizeConfig.size12,
              SizeConfig.size16,
              SizeConfig.size12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // What this button is about to charge. The catalog can be
                // scrolled far away from the selected card, so without this the
                // user would be paying for a plan that is off screen. Display
                // only — the charged amount comes from `initiate`.
                if (card != null)
                  _PayBarSummary(card: card)
                else
                  // Nothing selected yet: fall back to the two promises the
                  // contribution flow has always made.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        AppStrings.noHiddenCharges.tr,
                        fontSize: SizeConfig.size10,
                        color: AccountPlanPalette.muted,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        AppStrings.noAutoPay.tr,
                        fontSize: SizeConfig.size10,
                        color: AccountPlanPalette.muted,
                      ),
                    ],
                  ),
                SizedBox(height: SizeConfig.size8),
                CustomBtn(
                  title: busy
                      ? AppStrings.processingEllipsis.tr
                      : AppStrings.kindlyContributeUs.tr,
                  bgColor:
                      enabled ? AppColors.primaryColor : AppColors.grey9B,
                  radius: SizeConfig.size12,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  isLoading: busy,
                  onTap: enabled ? controller.buySelected : null,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// "1KM Radius · ₹177" with the base + GST breakdown, above the pay button.
///
/// **This is payment time**, so this is the one place the TOTAL is headlined —
/// the cards deliberately show base + GST instead (see [_PricePill]). The
/// breakdown line underneath reconciles the two, so the number on the button
/// can't read as a price that grew between the card and the checkout.
///
/// Display only: `initiate` re-prices server-side and that is what gets charged.
class _PayBarSummary extends StatelessWidget {
  const _PayBarSummary({required this.card});

  final PlanCard card;

  String _rupees(int paise) {
    final v = paise / 100;
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: SizeConfig.size2),
            child: CustomText(
              card.label,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w700,
              color: AccountPlanPalette.heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // What it would have cost. Only when there is a saving, and
                // only ever struck through — the number beside it is the one
                // the button charges.
                if (card.showsOffer) ...[
                  CustomText(
                    '${AppConstants.rupeeSymbol}${_rupees(card.priceTotal)}',
                    fontSize: SizeConfig.size11,
                    fontWeight: FontWeight.w600,
                    color: AccountPlanPalette.muted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AccountPlanPalette.muted,
                  ),
                  SizedBox(width: SizeConfig.size6),
                ],
                CustomText(
                  '${AppConstants.rupeeSymbol}${_rupees(card.finalPriceTotal)}',
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w800,
                  color: AccountPlanPalette.heading,
                ),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  '${AppStrings.inclGstPrefix.tr} '
                  '${card.gstPercent}${AppStrings.gstSuffix.tr}',
                  fontSize: SizeConfig.size10,
                  fontWeight: FontWeight.w500,
                  color: AccountPlanPalette.muted,
                ),
              ],
            ),
            if (card.finalGstAmount > 0) ...[
              SizedBox(height: SizeConfig.size2),
              CustomText(
                '${AppConstants.rupeeSymbol}${_rupees(card.finalPriceBase)}'
                ' + ${AppConstants.rupeeSymbol}${_rupees(card.finalGstAmount)}'
                ' ${AppStrings.gstShort.tr}',
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w500,
                color: AccountPlanPalette.muted,
              ),
            ],
            // The saving restated at the moment of paying — the card that
            // advertised it may be scrolled far off screen by now.
            if (card.showsOffer) ...[
              SizedBox(height: SizeConfig.size2),
              CustomText(
                '${AppStrings.youSave.tr} ${AppConstants.rupeeSymbol}'
                '${_rupees(card.discount!.discountAmount)}',
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w800,
                color: card.discount!.theme.accent(AppColors.primaryColor),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Dashed rule between a card's promise and its feature list.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            dashCount,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
              color: AccountPlanPalette.divider,
            ),
          ),
        );
      },
    );
  }
}

/// The light-blue sheet the cards sit on, with the comp's faint wave texture.
///
/// Purely decorative and ignored by hit-testing, so it can never eat a tap on
/// the content stacked over it.
class AccountPlanBackdrop extends StatelessWidget {
  const AccountPlanBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AccountPlanPalette.canvas,
      child: Stack(
        // Expand, not loose: the child is a scroll view, and under loose
        // constraints it would shrink to its content — collapsing the
        // pull-to-refresh area to a 320px band while the catalog is loading or
        // errored, and leaving a short catalog unable to scroll at all.
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: CustomPaint(painter: _WavePainter())),
          child,
        ],
      ),
    );
  }
}

/// Long, shallow arcs sweeping across the sheet — the texture in the comp. Kept
/// at a whisper of alpha: it should register as paper grain, not as lines.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.55);

    const spacing = 46.0;
    final amplitude = size.width * 0.06;
    for (var y = -spacing; y < size.height + spacing; y += spacing) {
      final path = Path()..moveTo(-10, y);
      // Two half-waves across the width; the phase shifts per row so the arcs
      // never line up into a visible grid.
      final phase = (y / spacing) % 2 == 0 ? 1.0 : -1.0;
      path.quadraticBezierTo(
        size.width * 0.25,
        y - amplitude * phase,
        size.width * 0.5,
        y,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        y + amplitude * phase,
        size.width + 10,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

/// Message + Retry, shared by the catalog and its host screen.
class AccountPlanErrorState extends StatelessWidget {
  const AccountPlanErrorState(
      {super.key, required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              message.isEmpty ? AppStrings.couldNotLoadPlans.tr : message,
              fontSize: SizeConfig.size14,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            SizedBox(height: SizeConfig.size16),
            CustomBtn(
              title: AppStrings.retry.tr,
              bgColor: AppColors.primaryColor,
              radius: SizeConfig.size10,
              width: SizeConfig.size120,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
