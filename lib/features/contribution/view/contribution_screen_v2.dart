import 'dart:math' as math;

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/controller/security_deposit_controller.dart';
import 'package:BlueEra/features/contribution/model/security_deposit_models.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Contribution flow **v2** — built on the Security Deposit backend
/// (docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md). Replaces the
/// recharge-based [ContributionScreen] at its call sites.
///
/// Shows the active (held) deposit when the user has one, otherwise the plan
/// catalog with a pay (initiate → confirm) CTA.
class ContributionScreenV2 extends StatelessWidget {
  const ContributionScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SecurityDepositController());
    _hydrateBuyerDetails(controller);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.contributionTitle.tr,
        isLeading: true,
        showElevation: 0,
      ),
      // Pinned "Pay Security Deposit" CTA — always visible on the plans view
      // whenever a payable plan exists (defaults to the first payable plan, so
      // it never hides waiting for the user to pick one). The active-deposit
      // view carries its own action, so the bar is hidden there.
      bottomNavigationBar: Obx(() {
        final status = controller.currentStatus.value;
        if (status == Status.INITIAL || status == Status.LOADING) {
          return const SizedBox.shrink();
        }
        if (controller.hasActiveDeposit) return const SizedBox.shrink();
        final plan =
            controller.selectedPlan.value ?? controller.firstPayablePlan;
        if (plan == null) return const SizedBox.shrink();
        return _PayBottomBar(
          plan: plan,
          busy: controller.isProcessing.value,
          onPay: () => controller.payDeposit(plan),
        );
      }),
      body: SafeArea(
        child: Obx(() {
          final status = controller.currentStatus.value;
          if (status == Status.INITIAL || status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }
          // The whole page scrolls as one — test banner, explainer video, and
          // the plans / active-deposit content. Only the Pay CTA stays pinned
          // (in bottomNavigationBar).
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.isTestMode) const _TestModeBanner(),
                if (controller.hasActiveDeposit)
                  // Deposit already held — nothing to buy, so no explainer video.
                  _ActiveDepositView(controller: controller)
                else ...[
                  // Only shown on the plans (needs-to-purchase) view.
                  _SecurityDepositVideoSection(controller: controller),
                  _PlansView(controller: controller),
                ],
                SizedBox(height: SizeConfig.size24),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Populate the controller's Razorpay prefill (name / email / phone) from the
  /// personal-details controller, falling back to the global mobile number.
  void _hydrateBuyerDetails(SecurityDepositController controller) {
    try {
      final viewCtrl = Get.find<ViewPersonalDetailsController>();
      final user = viewCtrl.personalProfileDetails.value.user;
      controller.userName = user?.name ?? '';
      controller.userEmail = user?.email ?? '';
      controller.userPhone = user?.contactNo ?? userMobileGlobal;
    } catch (_) {
      controller.userPhone = userMobileGlobal;
    }
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(String raw) {
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return '--';
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
}

String _rupees(int paise) {
  final r = paise / 100.0;
  return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(2);
}

// ─────────────────────────────────────────────
// EXPLAINER VIDEO (top of screen)
// ─────────────────────────────────────────────
/// Pinned explainer video shown above the plan catalog / active deposit.
/// Hidden entirely until the videos API returns at least one active video.
/// Reuses the shared [HorizontalVideoPlayer] (network streaming,
/// tap-to-play/pause, pause-on-scroll-away, multi-video paging) instead of a
/// bespoke player.
class _SecurityDepositVideoSection extends StatelessWidget {
  const _SecurityDepositVideoSection({required this.controller});

  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final videos = controller.videos;
      if (videos.isEmpty) return const SizedBox.shrink();
      final urls = videos.map((v) => v.fileUrl).toList();
      final first = videos.first;
      // Only caption a single video — with multiple, the player pages between
      // them and a fixed title/description would no longer match the visible one.
      final showCaption = videos.length == 1 &&
          (first.title.isNotEmpty || first.description.isNotEmpty);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
          0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EE)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14001120), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Keyed by the URL set so a changed list rebuilds the player.
              // Fixed square (1:1) box — the source clip is portrait, but a
              // full-height portrait player is too tall here, so we cap it to a
              // square instead of adopting the video's own ratio.
              HorizontalVideoPlayer(
                key: ValueKey(urls.join(',')),
                videoUrls: urls,
                isNetworkUrl: true,
                aspectRatio: 1,
                isAutoPlay: true,
                showMuteButton: true,
              ),
              if (showCaption)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size14,
                    SizeConfig.size12,
                    SizeConfig.size14,
                    SizeConfig.size14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (first.title.isNotEmpty)
                        CustomText(
                          first.title,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (first.description.isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          first.description,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// PLANS CATALOG
// ─────────────────────────────────────────────
class _PlansView extends StatelessWidget {
  const _PlansView({required this.controller});

  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.plansStatus.value;
      // States get a bounded height so they can sit inside the parent scroll.
      if (status == Status.INITIAL || status == Status.LOADING) {
        return const SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (status == Status.ERROR) {
        return SizedBox(
          height: 320,
          child: _ErrorState(
            message: controller.plansError.value,
            onRetry: controller.fetchPlans,
          ),
        );
      }
      final plans = controller.plans;
      if (plans.isEmpty) {
        return SizedBox(
          height: 320,
          child: _ErrorState(
            message: 'No deposit plans available',
            onRetry: controller.fetchPlans,
          ),
        );
      }
      // Plain Column (no inner scroll) — the parent SingleChildScrollView owns
      // the vertical scroll so the header + video + cards move as one.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PlansHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size4,
              SizeConfig.size12,
              0,
            ),
            child: Column(
              children: [
                for (int i = 0; i < plans.length; i++) ...[
                  if (i > 0) SizedBox(height: SizeConfig.size14),
                  _PlanCard(plan: plans[i], controller: controller),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Pinned intro above the plan list. States the single job of the screen
/// once — "pick a refundable security-deposit plan" — so the framing no
/// longer has to repeat above every card.
class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size6,
      ),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F001120), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: const Icon(Icons.shield_moon_outlined,
                size: 22, color: Colors.white),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'CHOOSE YOUR PLAN',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                  letterSpacing: 1.0,
                ),
                const SizedBox(height: 3),
                CustomText(
                  'Security Deposit',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  'Fully refundable — released after the lock-in period.',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned bottom bar that pays the security deposit for the currently selected
/// plan. Replaces the per-card pay button so the primary CTA stays reachable
/// without scrolling. Only rendered on the plans view for a payable selection.
class _PayBottomBar extends StatelessWidget {
  const _PayBottomBar({
    required this.plan,
    required this.busy,
    required this.onPay,
  });

  final SecurityDepositPlan plan;
  final bool busy;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size10,
        SizeConfig.size12,
        SizeConfig.size12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EE))),
        boxShadow: [
          BoxShadow(
              color: Color(0x14001120), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: busy ? null : onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              disabledBackgroundColor:
                  AppColors.primaryColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        'Pay Security Deposit  ₹${_rupees(plan.depositAmount)}',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.plan, required this.controller});

  final SecurityDepositPlan plan;
  final SecurityDepositController controller;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    // Per-card phase offset so neighbouring cards don't pulse in lockstep.
    _phase = (widget.plan.id.hashCode.abs() % 1000) / 1000.0;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Ambient animated gradient "splash" — soft radial blobs of brand blue,
  /// cyan and refund-green drifting and pulsing behind the card content
  /// (clipped to the card). Falls back to a single static frame when the OS
  /// has "reduce motion" on.
  Widget _splashLayer() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final colors = <Color>[
      AppColors.primaryColor,
      const Color(0xFF22D3EE), // cyan
      const Color(0xFF059669), // refund green
    ];
    if (reduceMotion) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _SplashPainter(t: 0, phase: _phase, colors: colors),
        ),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter:
              _SplashPainter(t: _anim.value, phase: _phase, colors: colors),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final controller = widget.controller;
    final zeroDeposit = plan.depositAmount <= 0;
    final firstDayText = plan.firstDayFreeUnlimited
        ? plan.firstDayFreeText
        : (plan.firstDayFreeLimit != null
            ? 'First ${plan.firstDayFreeLimit} free'
            : plan.firstDayFreeText);

    return Obx(() {
      // Payable cards are selectable — the pinned bottom bar pays for the
      // selected one. Zero-deposit cards are informational and never selected.
      final selected = !zeroDeposit &&
          controller.selectedPlan.value?.id == plan.id;
      return GestureDetector(
        onTap: zeroDeposit ? null : () => controller.selectPlan(plan),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primaryColor : const Color(0xFFE6E8EE),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14001120), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient animated gradient wash behind the content.
          Positioned.fill(child: _splashLayer()),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan identity — category eyebrow + name.
          if (plan.uiCategoryGroup.isNotEmpty) ...[
            CustomText(
              plan.uiCategoryGroup.toUpperCase(),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
              letterSpacing: 0.8,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SizeConfig.size4),
          ],
          CustomText(
            plan.name,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size12),
          // Price + refund guarantee — the card's signature pairing: the
          // deposit amount alongside the "returns to you" badge.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      zeroDeposit ? '₹0' : '₹${_rupees(plan.depositAmount)}',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                    CustomText(
                      'Security deposit',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                      letterSpacing: 0.3,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!zeroDeposit) const _RefundableBadge(),
            ],
          ),
          if (firstDayText.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _Pill(icon: Icons.card_giftcard_rounded, text: firstDayText),
          ],
          // if (plan.baseMetric.isNotEmpty) ...[
          //   SizedBox(height: SizeConfig.size8),
          //   _InfoLine(label: 'Billed per', value: plan.baseMetric),
          // ],
          // if (plan.activationCondition.isNotEmpty) ...[
          //   SizedBox(height: SizeConfig.size6),
          //   _InfoLine(label: 'Activation', value: plan.activationCondition),
          // ],
          Row(
            children: [
              Expanded(
                child: _InfoLine(
                  label: 'Refund lock',
                  value: 'After ${plan.refundAfterMonths} months',
                ),
              ),
              if (plan.termsAndConditions.isNotEmpty) ...[
                SizedBox(width: SizeConfig.size8),
                _InfoChipButton(
                  icon: Icons.description_outlined,
                  label: 'T&C',
                  onTap: () => _showInfoDialog(
                    context,
                    titleIcon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    points: plan.termsAndConditions,
                  ),
                ),
              ],
            ],
          ),
          if (plan.why.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            // "Why a security deposit is necessary" — the reasons shown inline
            // in their own bordered block so they read as a distinct, reassuring
            // section in the card.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 16, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size6),
                      Expanded(
                        child: CustomText(
                          'Why Security Deposit Necessary',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  _TermsBlock(
                    terms: plan.why,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: SizeConfig.size14),
          if (zeroDeposit)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                'No deposit required',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryTextColor,
              ),
            )
          else
            // Payable plans no longer carry an inline pay button — the pinned
            // bottom bar pays for the selected plan. This is just the selection
            // affordance (tap anywhere on the card to select it).
            _buildSelectionRow(selected),
              ],
            ),
          ),
        ],
      ),
        ),
      );
    });
  }

  /// Bottom-of-card selection affordance shown on payable plans in place of the
  /// old inline pay button — reflects whether this card is the one the pinned
  /// "Pay Security Deposit" bar will charge.
  Widget _buildSelectionRow(bool selected) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size12,
        horizontal: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor.withValues(alpha: 0.06)
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryColor : const Color(0xFFE6E8EE),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color:
                selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size8),
          CustomText(
            selected ? 'Selected' : 'Tap to select',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  /// Generic info dialog listing [points] as bullet points under a titled
  /// header — used by the "T&C" chip next to the Refund lock line.
  void _showInfoDialog(
    BuildContext context, {
    required IconData titleIcon,
    required String title,
    required List<String> points,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(titleIcon, size: 20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                title,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: _TermsBlock(terms: points),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: CustomText(
              'Got it',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the plan card's ambient gradient "splash": three soft radial
/// colour blobs that drift and gently pulse. [t] is the animation progress
/// (0→1, looped), [phase] a per-card offset so cards animate out of sync.
/// Kept subtle (low alpha, fading to transparent) so the card content stays
/// fully legible over it.
class _SplashPainter extends CustomPainter {
  _SplashPainter({required this.t, required this.phase, required this.colors});

  final double t;
  final double phase;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final base = 2 * math.pi * (t + phase);
    // (anchorX, anchorY, driftX, driftY, radiusFactor, phaseOffset)
    _blob(canvas, size, 0.86, 0.10, 0.06, 0.05, 0.60, colors[0], base + 0.0);
    _blob(canvas, size, 0.10, 0.88, 0.05, 0.06, 0.52, colors[2], base + 2.1);
    _blob(canvas, size, 0.98, 0.92, 0.05, 0.05, 0.44, colors[1], base + 4.2);
  }

  void _blob(
    Canvas canvas,
    Size size,
    double ax,
    double ay,
    double dx,
    double dy,
    double radiusFactor,
    Color color,
    double angle,
  ) {
    final center = Offset(
      (ax + dx * math.sin(angle)) * size.width,
      (ay + dy * math.cos(angle)) * size.height,
    );
    final pulse = 0.85 + 0.15 * math.sin(angle * 1.3);
    final radius = radiusFactor * size.width * pulse;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.t != t || old.phase != phase;
}

/// The card's signature: a green "100% Refundable" stamp with a circular
/// `autorenew` glyph — the deposit money that loops back to the seller.
class _RefundableBadge extends StatelessWidget {
  const _RefundableBadge();

  static const _green = Color(0xFF047857);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.autorenew_rounded, size: 13, color: _green),
          const SizedBox(width: 4),
          CustomText(
            '100% Refundable',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _green,
          ),
        ],
      ),
    );
  }
}

/// Small pill button (icon + [label]) shown to the right of an info line —
/// e.g. the "T&C" trigger next to the Refund lock line.
class _InfoChipButton extends StatelessWidget {
  const _InfoChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVE (HELD) DEPOSIT
// ─────────────────────────────────────────────
class _ActiveDepositView extends StatelessWidget {
  const _ActiveDepositView({required this.controller});

  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    final deposit = controller.currentDeposit.value!;
    final plan = deposit.plan;
    final planName = plan?.name ?? AppStrings.activeContribution.tr;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1B5C), Color(0xFF5E2BA8), Color(0xFFB2308C)],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x4D2B1B5C), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        size: 16, color: Color(0xFFFFD9B0)),
                    const SizedBox(width: 6),
                    CustomText(
                      'SECURITY DEPOSIT',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    const Spacer(),
                    _StatusPill(status: deposit.status),
                  ],
                ),
                const SizedBox(height: 26),
                CustomText(
                  planName,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: '₹',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFE6B0),
                            ),
                          ),
                          TextSpan(
                            text: _rupees(deposit.paidAmount),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (deposit.heldAt.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            AppStrings.sinceLabel.tr,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 1.4,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            _formatDate(deposit.heldAt),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ],
                      ),
                  ],
                ),
                // Refer & earn — surface the savings when a referral discount
                // was applied at initiate (base struck-through + amount saved).
                if (deposit.discountAmount > 0) ...[
                  const SizedBox(height: 12),
                  _ReferralSavingsChip(
                    baseAmount: deposit.baseAmount > 0
                        ? deposit.baseAmount
                        : deposit.depositAmount,
                    discountAmount: deposit.discountAmount,
                    percent: deposit.referralDiscountPercent,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size14),
          _InfoCard(
            icon: Icons.lock_clock_rounded,
            title: 'Refund eligibility',
            children: [
              _InfoLine(
                label: 'Refundable on',
                value: deposit.refundEligibleAt.isNotEmpty
                    ? _formatDate(deposit.refundEligibleAt)
                    : 'After ${deposit.refundAfterMonths} months',
              ),
            ],
          ),
          if (plan != null && plan.termsAndConditions.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _InfoCard(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              children: [_TermsBlock(terms: plan.termsAndConditions)],
            ),
          ],
          SizedBox(height: SizeConfig.size16),
          Obx(() {
            final busy = controller.isProcessing.value;
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : () => controller.requestRefund(
                          onLocked: (eligibleAt) => _showLockedDialog(
                            context,
                            _formatDate(eligibleAt),
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : CustomText(
                        'Request Refund',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String eligibleDate) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          'Refund not available yet',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          'This deposit is refundable on or after $eligibleDate.',
          fontSize: 13,
          color: AppColors.secondaryTextColor,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: CustomText(
              'OK',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        status.isEmpty ? AppStrings.activeStatusLabel.tr : status.toUpperCase(),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Refer-&-earn savings stamp on the active-deposit hero card. Shows the
/// pre-discount base struck-through and the rupee amount saved via the
/// referral, mirroring docs §8 ("show base_amount vs final_amount").
class _ReferralSavingsChip extends StatelessWidget {
  const _ReferralSavingsChip({
    required this.baseAmount,
    required this.discountAmount,
    required this.percent,
  });

  final int baseAmount; // paise
  final int discountAmount; // paise
  final int percent;

  @override
  Widget build(BuildContext context) {
    final savedLabel = '₹${_rupees(discountAmount)}';
    final percentLabel = percent > 0 ? ' ($percent% off)' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_rounded,
              size: 14, color: Color(0xFF6EE7B7)),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₹${_rupees(baseAmount)} ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  TextSpan(
                    text: 'Referral saved $savedLabel$percentLabel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
          right: 10,
          top: 6,
          bottom: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: CustomText(
              text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsBlock extends StatelessWidget {
  const _TermsBlock({required this.terms});
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.secondaryTextColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: terms
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        t,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c,
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              CustomText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              message.isEmpty ? AppStrings.somethingWentWrong.tr : message,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.size16),
            OutlinedButton(
              onPressed: onRetry,
              child: CustomText(
                'Retry',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber "test environment" strip — shown when the backend reports
/// `mode == 'test'`.
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
        border: Border.all(color: const Color(0xFFE6B84A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: Color(0xFFB8860B)),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              AppStrings.testModeBanner.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A6500),
            ),
          ),
        ],
      ),
    );
  }
}
