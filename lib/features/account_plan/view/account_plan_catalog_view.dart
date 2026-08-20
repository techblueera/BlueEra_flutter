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
            if (showHeader) ...[
              const _CatalogHeader(),
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
  });

  final PlanCard card;

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
    // one either.
    final terms = card.termsAndConditions.isEmpty ? null : _TermsLink(card: card);

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
                // The backend's recommended pick. Sits above the headline
                // rather than over the card's corner because the corner is
                // already the price pill's, and a ribbon crossing it would
                // obscure the one number the card exists to show.
                if (_showPopular) ...[
                  const _PopularBadge(),
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

  /// What the payment covers, read off the plan itself.
  ///
  /// Gig plans buy call types, so the caption counts them — one is a single job
  /// stream, two is a pairing, three or more is the lot. Everything else is a
  /// one-time purchase, which is what `billing: "lifetime"` means to a buyer.
  String get _caption {
    final jobs = card.jobTypes ?? const <String>[];
    if (jobs.isEmpty) return AppStrings.oneTimeLabel.tr;
    if (jobs.length == 1) return AppStrings.perJobLabel.tr;
    if (jobs.length == 2) return AppStrings.combinationLabel.tr;
    return AppStrings.fullCombinationLabel.tr;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
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
              CustomText(
                '${AppConstants.rupeeSymbol} ${_rupees(card.priceBase)}',
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
        // "+ ₹27 (18% GST)". Skipped when the backend priced the tax at zero,
        // rather than printing a "+ ₹0" that only raises a question.
        if (card.gstAmount > 0) ...[
          SizedBox(height: SizeConfig.size4),
          CustomText(
            '+ ${AppConstants.rupeeSymbol}${_rupees(card.gstAmount)}'
            ' (${card.gstPercent}${AppStrings.gstSuffix.tr})',
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w600,
            color: AccountPlanPalette.muted,
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
                  if (card.validityDays != null) ...[
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
                        AppStrings.planValidDaysFmt
                            .trParams({'days': '${card.validityDays}'}),
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
class _TermsLink extends StatelessWidget {
  const _TermsLink({required this.card});

  final PlanCard card;

  @override
  Widget build(BuildContext context) {
    if (card.termsAndConditions.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showAccountPlanTermsSheet(context, card),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Widens the tap target without moving the text off the comp's
        // bottom-right corner.
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        child: CustomText(
          AppStrings.tcStar.tr,
          fontSize: SizeConfig.size11,
          fontWeight: FontWeight.w600,
          color: AccountPlanPalette.link,
        ),
      ),
    );
  }
}

/// The plan's `terms_and_conditions`, rendered verbatim.
void showAccountPlanTermsSheet(BuildContext context, PlanCard card) {
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
                AppStrings.termsConditions.tr,
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                card.label,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: AccountPlanPalette.muted,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.size16),
              for (final term in card.termsAndConditions)
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
                CustomText(
                  '${AppConstants.rupeeSymbol}${_rupees(card.priceTotal)}',
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
            if (card.gstAmount > 0) ...[
              SizedBox(height: SizeConfig.size2),
              CustomText(
                '${AppConstants.rupeeSymbol}${_rupees(card.priceBase)}'
                ' + ${AppConstants.rupeeSymbol}${_rupees(card.gstAmount)}'
                ' ${AppStrings.gstShort.tr}',
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w500,
                color: AccountPlanPalette.muted,
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
