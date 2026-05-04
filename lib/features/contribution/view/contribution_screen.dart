import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_plans_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen contribution surface used by drawer menu / account-settings
/// entry points. Wraps [ContributionPlansView] in a Scaffold + back app bar.
class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the controller `ContributionPlansView` registers below — just
    // observe its `mode` reactive value to surface the test-mode banner.
    final controller = getOrPut(() => ContributionController());
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8FF),
      appBar: CommonBackAppBar(
        title: 'Contribution',
        isLeading: true,
        showElevation: 0,
      ),
      body: SafeArea(
        child: ColoredBox(
          color: const Color(0xFFEEF8FF),
          child: Column(
            children: [
              Obx(() => controller.isTestMode
                  ? const _TestModeBanner()
                  : const SizedBox.shrink()),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size4),
                  child: Obx(() {
                    // Wait for /recharge/current to answer before
                    // deciding which surface to show — avoids a flash
                    // of plan cards before flipping to the current-plan
                    // view, and vice versa.
                    final status = controller.currentStatus.value;
                    if (status == Status.INITIAL ||
                        status == Status.LOADING) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (controller.hasActiveRecharge.value) {
                      return _CurrentPlanView(controller: controller);
                    }
                    return const ContributionPlansView(
                      pinCta: true,
                      showHeader: false,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium "membership card" surface for the merchant's active
/// recharge. Reads fields from `controller.currentRecharge` matching
/// the real `/recharge/current` payload. Hierarchy:
///   1. Hero gradient card — tier badge, plan name, total paid, since
///   2. Animated perks gauge — remaining of total `perk_type`
///   3. What's-included checklist (`rechargePlanId.perks`)
///   4. Collapsible receipt drawer — payment / order IDs + timestamps
class _CurrentPlanView extends StatelessWidget {
  const _CurrentPlanView({required this.controller});

  final ContributionController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.currentRecharge.value ?? <String, dynamic>{};
    final plan = (data['rechargePlanId'] is Map<String, dynamic>)
        ? data['rechargePlanId'] as Map<String, dynamic>
        : <String, dynamic>{};

    final planName =
        (plan['name'] ?? 'Active Contribution').toString();
    final tier = (plan['tier'] ?? '').toString();
    final description = (plan['description'] ?? '').toString();
    final perksList = (plan['perks'] is List)
        ? (plan['perks'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final perkType = (plan['perk_type'] ?? '').toString();

    final finalAmount = _asInt(
        data['final_amount'] ?? plan['total_amount'] ?? plan['amount']);
    final totalPerks = _asInt(data['total_perks']);
    final perksRemaining = _asInt(data['perks_remaining']);
    final perksConsumed = _asInt(data['perks_consumed']);
    final isActive = data['isActive'] == true ||
        (data['status']?.toString().toLowerCase() == 'active');
    final createdAt = (data['created_at'] ?? '').toString();
    final updatedAt = (data['updated_at'] ?? '').toString();
    final paymentId = (data['razorpay_payment_id'] ?? '').toString();
    final orderId = (data['razorpay_order_id'] ?? '').toString();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MembershipHeroCard(
            planName: planName,
            tier: tier,
            description: description,
            isActive: isActive,
            totalRupees: finalAmount / 100.0,
            createdAt: createdAt,
          ),
          SizedBox(height: SizeConfig.size14),
          if (totalPerks > 0)
            _PerksGaugeCard(
              totalPerks: totalPerks,
              perksRemaining: perksRemaining,
              perksConsumed: perksConsumed,
              perkType: perkType,
            ),
          if (perksList.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _IncludedCard(perks: perksList),
          ],
          SizedBox(height: SizeConfig.size12),
          _ReceiptCard(
            paymentId: paymentId,
            orderId: orderId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ],
      ),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

String _formatLargeNumber(int n) {
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(n % 10000000 == 0 ? 0 : 1)}Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return '$n';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDateShort(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return '--';
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year.toString().substring(2)}';
}

String _formatDateLong(String raw) {
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  final hh = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year} · $hh:$mm $ampm';
}

// ─────────────────────────────────────────────
// 1. HERO MEMBERSHIP CARD — Aurora palette (deep indigo → violet →
// magenta) with a continuous diagonal sheen sweep, soft floating
// orbs, an entrance fade+scale, and a pulsating jade "ACTIVE" dot.
// Each animation has its own controller so they breathe at their
// own cadence rather than syncing into a hypnotic loop.
// ─────────────────────────────────────────────
class _MembershipHeroCard extends StatefulWidget {
  const _MembershipHeroCard({
    required this.planName,
    required this.tier,
    required this.description,
    required this.isActive,
    required this.totalRupees,
    required this.createdAt,
  });

  final String planName;
  final String tier;
  final String description;
  final bool isActive;
  final double totalRupees;
  final String createdAt;

  @override
  State<_MembershipHeroCard> createState() => _MembershipHeroCardState();
}

class _MembershipHeroCardState extends State<_MembershipHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierLabel =
        widget.tier.isNotEmpty ? widget.tier.toUpperCase() : 'MEMBER';
    final amountWhole = widget.totalRupees.toStringAsFixed(0);
    final amountFrac = ((widget.totalRupees -
                widget.totalRupees.truncateToDouble()) *
            100)
        .round()
        .toString()
        .padLeft(2, '0');

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entryCtrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: Transform.scale(
              scale: 0.96 + 0.04 * t,
              child: child,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D2B1B5C),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Aurora gradient — three-stop indigo → violet → magenta
              // arranged diagonally for a distinct "northern lights"
              // signature.
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1F1B5C),
                      Color(0xFF5E2BA8),
                      Color(0xFFB2308C),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Two soft floating orbs — picked up by the gradient,
              // give the surface depth without competing with content.
              Positioned(
                right: -70,
                top: -70,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: 70,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC07A).withValues(alpha: 0.10),
                  ),
                ),
              ),
              // Diagonal sheen — moves left → right every 3.6s like a
              // metallic card catching light. Wrapped in Positioned.fill
              // so the LayoutBuilder gets bounded constraints from the
              // outer Stack and can hand its child a real width.
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth;
                        return AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (_, __) {
                            const bandWidth = 110.0;
                            final v = _shimmerCtrl.value;
                            final x =
                                -bandWidth + v * (cardWidth + bandWidth * 2);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: x,
                                  top: -60,
                                  bottom: -60,
                                  width: bandWidth,
                                  child: Transform.rotate(
                                    angle: -0.35,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white
                                                .withValues(alpha: 0),
                                            Colors.white
                                                .withValues(alpha: 0.16),
                                            Colors.white
                                                .withValues(alpha: 0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Content layer.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier badge + active pulse pill.
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 13, color: Color(0xFFFFD9B0)),
                              const SizedBox(width: 5),
                              CustomText(
                                'MEMBER · $tierLabel',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.isActive) _buildActivePill(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Plan name in display weight.
                    CustomText(
                      widget.planName,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      'Your contribution is live.',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                    const SizedBox(height: 28),
                    // Amount + activation date.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white),
                            children: [
                              TextSpan(
                                text: '₹',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFE6B0),
                                ),
                              ),
                              TextSpan(
                                text: amountWhole,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: '.$amountFrac',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.createdAt.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                'SINCE',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 1.5,
                              ),
                              const SizedBox(height: 2),
                              CustomText(
                                _formatDateShort(widget.createdAt),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePill() {
    // Deep emerald → forest gradient pill with a bright lime pulse
    // dot. The dark fill cuts cleanly through the aurora gradient so
    // the pill reads as a tangible "live" stamp instead of a faint
    // tint, while the bright dot keeps the energy.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF047857),
            Color(0xFF065F46),
            Color(0xFF064E3B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.55),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final v = _pulseCtrl.value;
              final s = 0.85 + 0.30 * v;
              return Container(
                width: 8 * s,
                height: 8 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34D399)
                          .withValues(alpha: 0.65 * (1.0 - v * 0.4)),
                      blurRadius: 6 + 6 * v,
                      spreadRadius: 0.5 + 1.5 * v,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 7),
          const CustomText(
            'ACTIVE',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.4,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. PERKS GAUGE CARD — "Midnight Treasury". Deep midnight surface
// with a faint dot-grid texture, a small gold corner spark, and a
// gold→copper bar carrying a continuous traveling sheen. Adds:
//   • count-up of remaining perks (TweenAnimationBuilder<int>)
//   • bar entrance fill (TweenAnimationBuilder<double>)
//   • CONTINUOUS traveling shimmer on the filled portion (controller
//     repeating every 2.4s)
//   • softly pulsing percent badge (controller repeating reverse)
// ─────────────────────────────────────────────
class _PerksGaugeCard extends StatefulWidget {
  const _PerksGaugeCard({
    required this.totalPerks,
    required this.perksRemaining,
    required this.perksConsumed,
    required this.perkType,
  });

  final int totalPerks;
  final int perksRemaining;
  final int perksConsumed;
  final String perkType;

  @override
  State<_PerksGaugeCard> createState() => _PerksGaugeCardState();
}

class _PerksGaugeCardState extends State<_PerksGaugeCard>
    with TickerProviderStateMixin {
  late final AnimationController _badgePulse;
  late final AnimationController _barShimmer;

  // Midnight palette.
  static const _bg = Color(0xFF0B1024);
  static const _bgInner = Color(0xFF13182E);
  static const _track = Color(0xFF1E263F);
  static const _border = Color(0xFF26314D);
  static const _textHi = Color(0xFFF5F0E8);
  static const _textMid = Color(0xFFB6BCD0);
  static const _textLow = Color(0xFF7A839A);

  // Gold / copper accents.
  static const _gold = Color(0xFFF59E0B);
  static const _goldLight = Color(0xFFFCD34D);
  static const _goldHi = Color(0xFFFFE9A5);
  static const _copper = Color(0xFFB7781F);

  @override
  void initState() {
    super.initState();
    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _barShimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _badgePulse.dispose();
    _barShimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.totalPerks > 0
        ? (widget.perksRemaining / widget.totalPerks).clamp(0.0, 1.0)
        : 1.0;
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bgInner],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Faint dot-grid wash for texture.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _DotGridPainter()),
              ),
            ),
            // Tiny gold corner spark — barely there, gives a luxury
            // glint to the surface.
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _goldLight.withValues(alpha: 0.16),
                      _gold.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            // Content.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_goldHi, _gold, _copper],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            size: 14, color: Color(0xFF1A1300)),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        'PERKS REMAINING',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _textLow,
                        letterSpacing: 1.4,
                      ),
                      const Spacer(),
                      // Pulsing percentage badge.
                      AnimatedBuilder(
                        animation: _badgePulse,
                        builder: (_, __) {
                          final v = _badgePulse.value;
                          final glow = 0.30 + 0.45 * v;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [_goldHi, _gold, _copper],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: glow),
                                  blurRadius: 10 + 6 * v,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CustomText(
                              pctLabel,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1300),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Count-up numeric display.
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.perksRemaining),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CustomText(
                            _formatLargeNumber(val),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _textHi,
                            letterSpacing: -0.5,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMid,
                                ),
                                children: [
                                  const TextSpan(text: '/ '),
                                  TextSpan(
                                      text: _formatLargeNumber(
                                          widget.totalPerks)),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: widget.perkType.isNotEmpty
                                        ? widget.perkType
                                        : 'perks',
                                    style: const TextStyle(
                                      color: _goldLight,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // Progress bar — entrance fill + continuous shimmer.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 12,
                      color: _track,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: pct),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: val,
                              heightFactor: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Gold→copper fill with glow.
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            _goldHi,
                                            _goldLight,
                                            _gold,
                                            _copper,
                                          ],
                                          stops: [0.0, 0.4, 0.75, 1.0],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _gold.withValues(
                                                alpha: 0.55),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Continuous traveling sheen.
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: LayoutBuilder(
                                          builder: (ctx, constraints) {
                                            final w = constraints.maxWidth;
                                            return AnimatedBuilder(
                                              animation: _barShimmer,
                                              builder: (_, __) {
                                                const bandW = 36.0;
                                                final v =
                                                    _barShimmer.value;
                                                final x = -bandW +
                                                    v * (w + bandW * 2);
                                                return Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned(
                                                      left: x,
                                                      top: -4,
                                                      bottom: -4,
                                                      width: bandW,
                                                      child:
                                                          Transform.rotate(
                                                        angle: -0.35,
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha: 0),
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha: 0.55),
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha: 0),
                                                              ],
                                                              stops: const [
                                                                0.0,
                                                                0.5,
                                                                1.0
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Foot note — usage status (light text on dark).
                  if (widget.perksConsumed > 0)
                    CustomText(
                      '${_formatLargeNumber(widget.perksConsumed)} ${widget.perkType.isNotEmpty ? widget.perkType : 'perks'} used so far',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _textLow,
                    )
                  else
                    CustomText(
                      'Full balance available — start earning today.',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _textLow,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint dot-grid texture for the midnight surface — gives it the
/// "premium ledger paper" feel rather than a flat dark fill.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    for (var x = 4.0; x < size.width; x += spacing) {
      for (var y = 4.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// 3. WHAT'S INCLUDED — jade palette. Each perk row staggers in (fade
// + slide-up) so the checklist reveals top-to-bottom on first paint
// rather than appearing as a static block.
// ─────────────────────────────────────────────
class _IncludedCard extends StatefulWidget {
  const _IncludedCard({required this.perks});
  final List<String> perks;

  @override
  State<_IncludedCard> createState() => _IncludedCardState();
}

class _IncludedCardState extends State<_IncludedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _jade = Color(0xFF059669);
  static const _jadeBright = Color(0xFF10B981);
  static const _jadeSoft = Color(0xFFD1FAE5);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250 + 80 * widget.perks.length),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_jadeBright, _jade],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.verified_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              CustomText(
                "What's included",
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.perks.length, (i) {
            // Stagger the rows: each row's animation occupies a 350ms
            // window, shifted by i * 80ms. The total controller
            // duration above is sized to fit them all.
            final total = _ctrl.duration!.inMilliseconds.toDouble();
            final start = (i * 80) / total;
            final end = ((i * 80) + 350) / total;
            final anim = CurvedAnimation(
              parent: _ctrl,
              curve: Interval(
                start.clamp(0.0, 1.0),
                end.clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            );
            return AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                final v = anim.value;
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 14),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: _jadeSoft,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: _jadeBright, width: 0.6),
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 13, color: _jade),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomText(
                              widget.perks[i],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. RECEIPT — collapsible drawer with payment / order ids and dates.
// ─────────────────────────────────────────────
class _ReceiptCard extends StatefulWidget {
  const _ReceiptCard({
    required this.paymentId,
    required this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String paymentId;
  final String orderId;
  final String createdAt;
  final String updatedAt;

  @override
  State<_ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<_ReceiptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withValues(alpha: 0.85),
                          AppColors.primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  CustomText(
                    'Receipt',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  const Spacer(),
                  // Chevron tints to brand-blue when expanded.
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        begin: AppColors.secondaryTextColor,
                        end: _expanded
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                      ),
                      duration: const Duration(milliseconds: 220),
                      builder: (_, color, __) => Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Column(
                    children: [
                      Container(height: 1, color: const Color(0xFFEEF1F4)),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          children: [
                            if (widget.paymentId.isNotEmpty)
                              _row('Payment ID', widget.paymentId,
                                  mono: true),
                            if (widget.orderId.isNotEmpty)
                              _row('Order ID', widget.orderId, mono: true),
                            if (widget.createdAt.isNotEmpty)
                              _row('Activated',
                                  _formatDateLong(widget.createdAt)),
                            if (widget.updatedAt.isNotEmpty &&
                                widget.updatedAt != widget.createdAt)
                              _row('Last updated',
                                  _formatDateLong(widget.updatedAt)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              fontFamily: mono ? 'monospace' : null,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber strip that signals "this environment isn't real money" — only
/// rendered when the recharge service reports `mode == 'test'` from
/// `GET /recharge/plans`. The shape mirrors the rest of the page's
/// chip-and-shadow language so the banner reads as part of the UI
/// rather than a dev overlay.
class _TestModeBanner extends StatelessWidget {
  const _TestModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size8,
        SizeConfig.size12,
        0,
      ),
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6B84A), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined,
              size: 16, color: Color(0xFFB8860B)),
          SizedBox(width: SizeConfig.size8),
          const Expanded(
            child: CustomText(
              'Test Mode — payments will not charge real money.',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A6500),
            ),
          ),
        ],
      ),
    );
  }
}
