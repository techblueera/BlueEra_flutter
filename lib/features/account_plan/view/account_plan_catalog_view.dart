import 'dart:math' as math;

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
import 'package:visibility_detector/visibility_detector.dart';

import '../controller/account_plan_controller.dart';
import '../model/account_plan_models.dart';

/// The Account Plan catalog, as a plain (non-scrolling) column.
///
/// Renders whatever `plans[]` the backend returns and draws each card from its
/// archetype plus the attributes on it, so adding a 139th account type on the
/// backend needs no change here.
///
/// **No inner scroll**: the host owns the scroll view, which is what lets the
/// contribution screen stack the explainer video above this and have the two
/// move as one. Loading/error states get a bounded height for the same reason.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanCatalogView extends StatelessWidget {
  const AccountPlanCatalogView({super.key, required this.controller});

  final AccountPlanController controller;

  /// Headline per archetype — the question the cards below answer.
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

  /// Every job type any plan in this catalog offers, first-seen order.
  ///
  /// This is what turns five separate cards into one comparison: each card
  /// draws the whole set and lights only its own. Derived rather than
  /// hardcoded, so a vehicle class with two job types and one with four both
  /// render correctly.
  static List<String> jobTypeUniverseOf(PlanCatalog catalog) {
    final seen = <String>[];
    for (final plan in catalog.plans) {
      for (final job in plan.jobTypes ?? const <String>[]) {
        if (job.isNotEmpty && !seen.contains(job)) seen.add(job);
      }
    }
    return seen;
  }

  /// Largest finite radius on offer, for scaling the reach bar. All-India
  /// (`-1`) is excluded — it is the top of the ladder, not a length.
  static int maxRadiusOf(PlanCatalog catalog) {
    var max = 0;
    for (final plan in catalog.plans) {
      final r = plan.radiusKm;
      if (r != null && r > max) max = r;
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
          break;
      }

      final catalog = controller.catalog.value;
      if (catalog == null || catalog.plans.isEmpty) {
        return SizedBox(
          height: 320,
          child: AccountPlanErrorState(
            message: AppStrings.noPlansForAccount.tr,
            onRetry: controller.fetchPlans,
          ),
        );
      }

      final universe = jobTypeUniverseOf(catalog);
      final maxRadius = maxRadiusOf(catalog);

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
            CustomText(
              headlineKeyFor(catalog.archetype).tr,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size12),
            for (final (index, plan) in catalog.plans.indexed)
              _PlanCardTile(
                card: plan,
                index: index,
                jobTypeUniverse: universe,
                maxRadiusKm: maxRadius,
                isOwned: controller.ownsPlan(plan),
                isBusy: controller.isProcessing.value &&
                    controller.purchasingCode.value == plan.optionCode,
                // Any purchase in flight dims and locks the others, so a
                // second checkout can't open on top of the first.
                isLocked: controller.isProcessing.value &&
                    controller.purchasingCode.value != plan.optionCode,
                onBuy: () => controller.buyPlan(plan),
              ),
            SizedBox(height: SizeConfig.size8),
            const _Footnote(),
          ],
        ),
      );
    });
  }
}

/// One plan, drawn from its own fields.
///
/// ## The signature: an entitlement meter, derived from the catalog
///
/// The five gig cards a bike rider gets back differ in exactly one thing —
/// which calls will ring on the phone — and the API expresses that as slugs
/// (`passenger`, `food_grocery`, `parcel`). Printed as chips those read as
/// lowercase noise and leave the rider comparing five lists by eye.
///
/// So each card shows the WHOLE set the catalog offers, with its own subset
/// lit. The cards then stack into a comparison table: "Passenger + Parcel"
/// visibly lights two of three.
///
/// Radius plans get the same idea in their own idiom — a bar filled against
/// the widest plan on offer, so 1 km / 3 km / All India read as an ordered
/// ladder instead of three similar numbers. A tier plan has neither and falls
/// back to a plain pill.
class _PlanCardTile extends StatefulWidget {
  const _PlanCardTile({
    required this.card,
    required this.index,
    required this.jobTypeUniverse,
    required this.maxRadiusKm,
    required this.isOwned,
    required this.isBusy,
    required this.isLocked,
    required this.onBuy,
  });

  final PlanCard card;

  /// Position in the catalog — picks the card's splash palette and offsets its
  /// animation phase so neighbours never pulse in lockstep.
  final int index;

  /// Every job type any plan in this catalog offers, in catalog order.
  final List<String> jobTypeUniverse;

  /// Largest finite radius in this catalog, for scaling the reach bar.
  final int maxRadiusKm;

  final bool isOwned;
  final bool isBusy;
  final bool isLocked;
  final VoidCallback onBuy;

  @override
  State<_PlanCardTile> createState() => _PlanCardTileState();
}

class _PlanCardTileState extends State<_PlanCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splash;

  /// Whether this card is on screen. A catalog is five cards today, but the
  /// endpoint serves 138 account types and nothing caps the list — an
  /// off-screen card repainting a gradient every frame is pure cost, so each
  /// one only runs its ticker while it is actually visible.
  bool _visible = false;

  /// The OS "remove animations" setting. The gradient still paints; it just
  /// holds still.
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Slow on purpose: the splash is ambient identity, not an effect. Anything
    // quick enough to notice would compete with the entitlement meter, which
    // is the thing the card is actually for.
    // Slow enough to stay ambient, quick enough to actually read as motion —
    // the first pass at 14s was indistinguishable from a still image.
    _splash = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTicker();
  }

  /// Single place that decides whether the controller runs, so visibility and
  /// the reduced-motion setting can't fight over it.
  ///
  /// `repeat()` resumes from the controller's current value, so a card
  /// scrolled away and back picks its wash up where it left off rather than
  /// snapping to the start.
  void _syncTicker() {
    final shouldRun = _visible && !_reduceMotion;
    if (shouldRun && !_splash.isAnimating) {
      _splash.repeat();
    } else if (!shouldRun && _splash.isAnimating) {
      _splash.stop();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // Any sliver of the card counts as visible — the wash is ambient, and a
    // threshold would make it pop in mid-scroll.
    final visible = info.visibleFraction > 0;
    if (visible == _visible) return;
    _visible = visible;
    // Fires from a post-frame callback, and on dispose with a fraction of 0.
    if (!mounted) return;
    _syncTicker();
  }

  @override
  void dispose() {
    _splash.dispose();
    super.dispose();
  }

  PlanCard get card => widget.card;

  @override
  Widget build(BuildContext context) {
    final palette = _SplashPalette.forIndex(widget.index);
    // The card's own deep tone, so the type and controls belong to the same
    // colour as the wash behind them. Owned cards switch to green — it means
    // the same thing here as everywhere else in the app.
    final accent = widget.isOwned ? AppColors.green00 : palette.accent;
    return VisibilityDetector(
      // Namespaced and keyed on the option code, not the index: a refetch can
      // reorder the catalog, and VisibilityDetector's registry is global.
      key: ValueKey('account_plan_card_${card.optionCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Opacity(
        opacity: widget.isLocked ? 0.5 : 1,
        child: Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size12),
          decoration: BoxDecoration(
            // The ground the splash moves across. Painted on the container so
            // the card still has its colour wherever the blobs have drifted
            // away.
            gradient: palette.baseGradient,
            borderRadius: BorderRadius.circular(SizeConfig.size14),
            border: Border.all(
              color: accent.withValues(alpha: widget.isOwned ? 0.85 : 0.18),
              width: widget.isOwned ? 1.4 : 1,
            ),
            boxShadow: [
              // Tinted with the card's own accent rather than neutral grey, so
              // the colour reads as belonging to the card instead of a shadow
              // dropped under it.
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Ambient gradient wash, unique per card. Sits UNDER the content
              // and is ignored by hit-testing, so it can never eat a tap.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _splash,
                    builder: (_, __) => CustomPaint(
                      painter: _SplashPainter(
                        t: _splash.value,
                        phase: widget.index * 0.37,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
              ),
              _content(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size14,
                SizeConfig.size14,
                SizeConfig.size14,
                SizeConfig.size12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle class as an eyebrow — the one bit of context the
                  // label leaves out ("Passenger" on a BIKE vs a CAR). Absent
                  // on shop plans, where the row simply doesn't render.
                  if ((card.vehicleClass ?? '').isNotEmpty) ...[
                    CustomText(
                      card.vehicleClass!.toUpperCase(),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: accent.withValues(alpha: 0.75),
                    ),
                    SizedBox(height: SizeConfig.size6),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomText(
                          card.label,
                          fontSize: SizeConfig.size16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          height: 1.2,
                          maxLines: 2,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      _PriceTag(card: card, accent: accent),
                    ],
                  ),
                  // Only rendered when the API actually sends one — it comes
                  // back as "" for every gig plan.
                  if ((card.sublabel ?? '').isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      card.sublabel!,
                      fontSize: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                    ),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  _entitlement(accent),
                ],
              ),
            ),
            _ActionBar(
              card: card,
              accent: accent,
              isOwned: widget.isOwned,
              isBusy: widget.isBusy,
              isLocked: widget.isLocked,
              onBuy: widget.onBuy,
            ),
      ],
    );
  }

  /// The one loud element, picked by what the card actually carries.
  Widget _entitlement(Color accent) {
    if (widget.jobTypeUniverse.isNotEmpty) {
      return _JobTypeStrip(
        all: widget.jobTypeUniverse,
        included: card.jobTypes ?? const [],
        accent: accent,
      );
    }
    if (card.radiusKm != null) {
      return _ReachBar(
        radiusKm: card.radiusKm!,
        maxRadiusKm: widget.maxRadiusKm,
        isAllIndia: card.isAllIndia,
        accent: accent,
        // Reuses the card's controller rather than starting its own, so the
        // sheen is already paused when the card scrolls off screen and there
        // is still exactly one ticker per card.
        sweep: _splash,
      );
    }
    final chips = <String>[
      if (card.tier != null) card.tier!,
      if (card.validityDays != null) '${card.validityDays} days',
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final c in chips) _Pill(text: c, accent: accent)],
    );
  }
}

/// The colours one card is built from: a near-white base, three pastel blobs
/// that drift across it, and one deep accent for the type and controls.
///
/// ## Getting a visible splash onto a LIGHT card
///
/// Two earlier passes bracketed this. Pale tints at 8% alpha on white were
/// invisible — nothing to see. Vivid blobs on a dark base were visible but
/// turned five cards into black slabs in an otherwise light app.
///
/// What works on a light surface is the mesh-gradient approach: keep the blobs
/// **high-luminance** (pastels, not mid-tones) and then run them at a real
/// alpha. A pastel at 55% over white still lands around #CFD6FD — clearly a
/// colour, and dark text over it keeps full contrast. Saturation is what would
/// have cost legibility, not opacity, so opacity is where the visibility comes
/// from.
///
/// Five gig plans also arrive looking almost identical — same shape, same
/// chips, only the price and the lit set differ. A distinct wash per card
/// makes each recognisable when scrolling back to compare. Assigned by catalog
/// position, so a card keeps its colour across rebuilds.
class _SplashPalette {
  const _SplashPalette({
    required this.tint,
    required this.accent,
    required this.a,
    required this.b,
    required this.c,
  });

  /// The faintest wash of the card's colour, under the blobs, so the card is
  /// never pure white even where nothing has drifted.
  final Color tint;

  /// Deep enough to carry text and controls over the wash. Chips, the eyebrow
  /// and the Buy button all take this, which is what ties a card's identity
  /// together rather than leaving the colour purely decorative.
  final Color accent;

  /// The three drifting blobs — pastel by design, see the class doc.
  final Color a;
  final Color b;
  final Color c;

  /// Full-strength brand tones — the 500/600 step, not tints.
  ///
  /// Depth comes from the COLOUR, and the painter then pulls its alpha back to
  /// compensate, rather than the reverse. That is what keeps the card "deeper
  /// but not dark": at the painter's alpha these land around #A9ABF7, so the
  /// wash reads as a real colour while `mainTextColor` stays well clear of the
  /// contrast floor. This is the end of the scale — anything stronger and the
  /// small print starts to suffer, at which point the answer is a different
  /// treatment, not more saturation.
  static const List<_SplashPalette> _wheel = [
    // Indigo / blue / violet
    _SplashPalette(
      tint: Color(0xFFE8ECFF),
      accent: Color(0xFF4338CA),
      a: Color(0xFF6366F1),
      b: Color(0xFF3B82F6),
      c: Color(0xFF8B5CF6),
    ),
    // Emerald / teal / green
    _SplashPalette(
      tint: Color(0xFFE3FBF1),
      accent: Color(0xFF0F766E),
      a: Color(0xFF10B981),
      b: Color(0xFF14B8A6),
      c: Color(0xFF34D399),
    ),
    // Orange / amber / red
    _SplashPalette(
      tint: Color(0xFFFFEEDD),
      accent: Color(0xFFC2410C),
      a: Color(0xFFF97316),
      b: Color(0xFFF59E0B),
      c: Color(0xFFEF4444),
    ),
    // Pink / purple / rose
    _SplashPalette(
      tint: Color(0xFFFFE8F2),
      accent: Color(0xFFBE185D),
      a: Color(0xFFEC4899),
      b: Color(0xFFA855F7),
      c: Color(0xFFF43F5E),
    ),
    // Sky / blue / indigo
    _SplashPalette(
      tint: Color(0xFFE2F3FF),
      accent: Color(0xFF0369A1),
      a: Color(0xFF0EA5E9),
      b: Color(0xFF60A5FA),
      c: Color(0xFF6366F1),
    ),
  ];

  static _SplashPalette forIndex(int i) => _wheel[i % _wheel.length];

  /// White at the top-left fading into the card's tint — the wash the blobs
  /// then move across.
  LinearGradient get baseGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFFFFFFF), tint],
      );
}

/// Three pastel radial blobs drifting and breathing across the card's base.
///
/// [t] is the loop progress (0→1) and [phase] the per-card offset that keeps
/// neighbours out of sync. The travel is a large fraction of the card, not a
/// nudge — a small drift reads as a rendering artefact rather than movement.
class _SplashPainter extends CustomPainter {
  const _SplashPainter({
    required this.t,
    required this.phase,
    required this.palette,
  });

  final double t;
  final double phase;
  final _SplashPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // One full turn per loop, offset per card.
    final angle = (t + phase) * 2 * math.pi;

    void blob(Color color, double cx, double cy, double r, double drift) {
      final dx = math.cos(angle + drift) * w * 0.22;
      final dy = math.sin(angle * 0.8 + drift) * h * 0.45;
      // Breathe by ±14% so the wash never sits still.
      final radius = r * (1 + 0.14 * math.sin(angle + drift));
      final center = Offset(w * cx + dx, h * cy + dy);
      final paint = Paint()
        ..shader = RadialGradient(
          // Fades through a mid stop so the edge dissolves into the base
          // instead of ending on a visible rim.
          //
          // Alpha is the counterweight to saturation: the palette moved to
          // full-strength brand tones, so this pulled back from 0.62 to keep
          // the card deeper WITHOUT going dark. Raise both together and the
          // text goes with it.
          colors: [
            color.withValues(alpha: 0.52),
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(palette.a, 0.10, 0.10, w * 0.55, 0);
    blob(palette.b, 0.92, 0.28, w * 0.48, 2.1);
    blob(palette.c, 0.52, 1.05, w * 0.60, 4.2);
  }

  @override
  bool shouldRepaint(_SplashPainter old) =>
      old.t != t || old.phase != phase || old.palette != palette;
}

/// Human name and glyph for a job-type slug.
///
/// An unknown slug still renders — title-cased with a neutral tag icon — so a
/// job type added on the backend appears without an app release.
class _JobType {
  const _JobType(this.icon, this.label);

  final IconData icon;
  final String label;

  static _JobType of(String slug) {
    switch (slug) {
      case 'passenger':
        return const _JobType(Icons.person_rounded, 'Passenger');
      case 'food_grocery':
        return const _JobType(Icons.shopping_bag_rounded, 'Food & Grocery');
      case 'parcel':
        return const _JobType(Icons.inventory_2_rounded, 'Parcel');
      default:
        return _JobType(Icons.local_offer_rounded, _titleCase(slug));
    }
  }

  static String _titleCase(String slug) => slug
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// The whole set of call types on offer, with this plan's own lit.
class _JobTypeStrip extends StatelessWidget {
  const _JobTypeStrip({
    required this.all,
    required this.included,
    required this.accent,
  });

  final List<String> all;
  final List<String> included;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final slug in all)
          _JobChip(
            type: _JobType.of(slug),
            on: included.contains(slug),
            accent: accent,
          ),
      ],
    );
  }
}

class _JobChip extends StatelessWidget {
  const _JobChip({required this.type, required this.on, required this.accent});

  final _JobType type;
  final bool on;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // The lit/unlit contrast IS the information, so BOTH states have to be
    // legible — an unlit chip that disappears tells the reader nothing about
    // what this plan leaves out.
    //
    // Lit is solid accent with white type. Unlit is the same hue held back:
    // solid white fill so it lifts off the coloured wash, an accent border at
    // a third strength, and accent-toned text. Grey was the first attempt and
    // it sank into the background.
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: on ? accent : Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        border: Border.all(
          color: on ? accent : accent.withValues(alpha: 0.35),
          width: on ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: on ? 0.28 : 0.10),
            blurRadius: on ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: 13,
            color: on ? Colors.white : accent.withValues(alpha: 0.55),
          ),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            type.label,
            fontSize: 11,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? Colors.white : accent.withValues(alpha: 0.70),
          ),
        ],
      ),
    );
  }
}

/// Reach, drawn to scale against the widest plan in the catalog, so the
/// options read as an ordered ladder rather than three similar numbers.
class _ReachBar extends StatelessWidget {
  const _ReachBar({
    required this.radiusKm,
    required this.maxRadiusKm,
    required this.isAllIndia,
    required this.accent,
    required this.sweep,
  });

  final int radiusKm;
  final int maxRadiusKm;
  final bool isAllIndia;
  final Color accent;

  /// Drives the sheen travelling along the filled part. Supplied by the card
  /// so the bar adds no ticker of its own.
  final Animation<double> sweep;

  /// A lighter band travelling left-to-right along the filled portion.
  ///
  /// The band is built from the accent itself rather than white, so the bar
  /// brightens as it passes instead of looking washed out. Stops run from
  /// off-the-left to off-the-right so the highlight enters and exits cleanly
  /// rather than popping at the ends.
  LinearGradient _sheen() {
    final head = -0.4 + sweep.value * 1.8;
    final light = Color.lerp(accent, Colors.white, 0.45)!;
    return LinearGradient(
      colors: [accent, light, accent],
      stops: [
        (head - 0.22).clamp(0.0, 1.0),
        head.clamp(0.0, 1.0),
        (head + 0.22).clamp(0.0, 1.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // All-India is the top of the ladder by definition; everything else is a
    // fraction of the widest finite radius. The floor keeps the smallest plan
    // visible instead of a hairline.
    final double fraction = isAllIndia
        ? 1.0
        : (maxRadiusKm <= 0 ? 1.0 : (radiusKm / maxRadiusKm).clamp(0.12, 1.0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.my_location_rounded, size: 13, color: accent),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              isAllIndia
                  ? AppStrings.allIndia.tr
                  : '$radiusKm ${AppStrings.kmVisibility.tr}',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        // Two motions, doing different jobs. The FILL draws itself in once, so
        // the ladder is read as a comparison rather than arriving pre-filled.
        // The SHEEN then keeps sliding along it — a still bar on a card whose
        // background is moving looks like it failed to load.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, filled, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  // The UNFILLED remainder. Grey vanished against the coloured
                  // wash behind the card, so the track is a deep tint of the
                  // accent instead — the empty part of the ladder has to be as
                  // readable as the full part, or there is nothing to compare
                  // the fill against.
                  Positioned.fill(
                    child: ColoredBox(
                      color: accent.withValues(alpha: 0.22),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: filled,
                    child: AnimatedBuilder(
                      animation: sweep,
                      builder: (context, __) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _sheen(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Footer strip: the state of this plan, or the way to buy it.
///
/// Tinted and divided off the body so the price and the action never compete
/// for the same corner of the card.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.card,
    required this.accent,
    required this.isOwned,
    required this.isBusy,
    required this.isLocked,
    required this.onBuy,
  });

  final PlanCard card;
  final Color accent;
  final bool isOwned;
  final bool isBusy;
  final bool isLocked;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final settled = isOwned || card.isFree;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        // A white veil, not a tint: it lifts the footer clear of whichever
        // blob happens to be under it, so the CTA never sits on a moving
        // colour.
        color: Colors.white.withValues(alpha: settled ? 0.45 : 0.62),
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          if (settled) ...[
            Icon(
              isOwned ? Icons.check_circle_rounded : Icons.verified_rounded,
              size: 16,
              color: accent,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              isOwned ? AppStrings.planActive.tr : AppStrings.planFree.tr,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ] else ...[
            Expanded(
              child: CustomText(
                '${AppStrings.inclGstPrefix.tr} ${card.gstPercent}${AppStrings.gstSuffix.tr}',
                fontSize: 10,
                color: AppColors.secondaryTextColor,
              ),
            ),
            _BuyButton(
              accent: accent,
              isBusy: isBusy,
              onTap: (isBusy || isLocked) ? null : onBuy,
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.accent,
    required this.isBusy,
    required this.onTap,
  });

  final Color accent;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SizeConfig.size20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size8,
          ),
          decoration: BoxDecoration(
            // Solid accent: the only saturated block on the card, so the one
            // action is unmistakable against a wash of pastels.
            color: onTap == null ? accent.withValues(alpha: 0.45) : accent,
            borderRadius: BorderRadius.circular(SizeConfig.size20),
            boxShadow: onTap == null
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: isBusy
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : CustomText(
                  AppStrings.buyNow.tr,
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.card, required this.accent});

  final PlanCard card;
  final Color accent;

  /// Paise → rupees, dropping a trailing `.00` so whole prices read cleanly.
  String _rupees(int paise) {
    final v = paise / 100;
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (card.isFree) {
      return CustomText(
        AppStrings.planFree.tr,
        fontSize: SizeConfig.size16,
        fontWeight: FontWeight.w800,
        color: accent,
      );
    }
    // The GST line lives in the action bar, not here — the price should be one
    // clean number next to the label.
    return CustomText(
      '${AppConstants.rupeeSymbol}${_rupees(card.priceTotal)}',
      fontSize: SizeConfig.size18,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SizeConfig.size20),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.size10,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
    );
  }
}

/// The two promises the contribution screen already makes, repeated here
/// because this is also a payment screen.
class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(
          AppStrings.noHiddenCharges.tr,
          fontSize: SizeConfig.size10,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          AppStrings.noAutoPay.tr,
          fontSize: SizeConfig.size10,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
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
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
