import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen_v2.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Auto-playing carousel pinned to the top of the merchant "Order" tab.
///
/// Four slides, all sharing one compact card style:
///   • Contribution      → opens the contribution screen (reactive to plan)
///   • Add bank / UPI     → opens the payment-settings screen
///   • Add product/serv   → switches the host's own Products/Service tab
///   • Refer & earn       → opens the referral screen
///
/// Every slide is the same [_ActionCard] — light pastel gradient, hairline
/// tinted border, dark-ink title, accent medallion + chevron — so the deck
/// reads as a single family at one consistent height and full width; only the
/// accent hue changes per card.
///
/// The deck auto-advances every few seconds, pauses while the user is
/// swiping, and is summarised by an animated dot indicator. Auto-advance is
/// suppressed when the platform has reduced-motion enabled.
class OrderActionsCarousel extends StatefulWidget {
  const OrderActionsCarousel({
    super.key,
    required this.onAddCatalog,
    required this.catalogIcon,
    required this.catalogTitle,
    required this.catalogSubtitle,
  });

  /// Switches the host screen's TabController to its Products / Service tab.
  final VoidCallback onAddCatalog;

  /// Icon + copy for the "Add product" / "Add service" card — supplied by the
  /// host since the wording differs between product and service businesses.
  final IconData catalogIcon;
  final String catalogTitle;
  final String catalogSubtitle;

  @override
  State<OrderActionsCarousel> createState() => _OrderActionsCarouselState();
}

class _OrderActionsCarouselState extends State<OrderActionsCarousel> {
  // Compact deck height: the action cards fill it, and the contribution card
  // is scaled down to fit, so all slides read as one consistent, small height.
  static const double _viewportHeight = 70;
  static const Duration _interval = Duration(seconds: 4);

  /// Number of slides currently in the deck. Dynamic because the "Contribute"
  /// card is dropped once the security-deposit / go-live gate is satisfied.
  /// Recomputed in [_buildDeck]; defaults to the full deck.
  int _slideCount = 4;

  // Inset on each side of every slide so neighbouring cards show a clear gap
  // as the deck swipes between them (the PageView itself is edge-to-edge).
  static const double _slideGap = 6;

  final PageController _pageController = PageController();
  Timer? _timer;
  int _index = 0;
  bool _autoPlayStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "reduce motion" accessibility setting: no auto-advance.
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion && !_autoPlayStarted) {
      _autoPlayStarted = true;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % _slideCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoPlay() => _timer?.cancel();

  void _resumeAutoPlay() {
    if (_autoPlayStarted) _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Riders (bike / car / auto / goods) pay the security deposit via the
  /// onboarding gate; other individuals via the personal-profile go-live gate.
  bool get _isRiderRole =>
      userProfessionGlobal == BIKE_RIDER ||
      userProfessionGlobal == CAR_TAXI_DRIVER ||
      userProfessionGlobal == AUTO_TAXI ||
      userProfessionGlobal == GOODS_TAXI;

  /// Whether a security-deposit / go-live gate even applies to this user — used
  /// to decide whether to wrap the deck in an [Obx] (GetX forbids an Obx that
  /// reads no observable).
  bool get _hasDepositGate =>
      (_isRiderRole && Get.isRegistered<DeliveryPartnerController>()) ||
      (!isBusinessUser() && Get.isRegistered<ViewPersonalDetailsController>());

  /// True once the deposit gate is satisfied (paid, or no deposit required) —
  /// the "Contribute" card is then dropped from the deck. Mirrors the go-live
  /// check used across the me-screens:
  ///   • riders            → DeliveryPartnerController.isSecurityDepositPaid
  ///   • other individuals → ViewPersonalDetailsController.canGoLive
  /// Reads reactive controller state, so it must be evaluated inside an [Obx].
  bool get _depositGateSatisfied {
    if (_isRiderRole && Get.isRegistered<DeliveryPartnerController>()) {
      return Get.find<DeliveryPartnerController>().isSecurityDepositPaid;
    }
    if (!isBusinessUser() && Get.isRegistered<ViewPersonalDetailsController>()) {
      return Get.find<ViewPersonalDetailsController>().canGoLive;
    }
    // No deposit gate applies (e.g. a business account) → keep the card.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap in Obx when a gate applies, so the Contribute card disappears
    // the instant the deposit is paid. Businesses (no gate) render statically.
    if (_hasDepositGate) {
      return Obx(() => _buildDeck(hideContribution: _depositGateSatisfied));
    }
    return _buildDeck(hideContribution: false);
  }

  Widget _buildDeck({required bool hideContribution}) {
    // The Contribute card is dropped once the deposit gate is satisfied; the
    // other three always show.
    final slides = <Widget>[
      if (!hideContribution) _slide(_contributionCard()),
      _slide(_bankCard()),
      _slide(_catalogCard()),
      _slide(_referCard()),
    ];
    _slideCount = slides.length;
    // Keep the active page in range if the deck shrank (card removed).
    if (_index >= _slideCount) _index = _slideCount - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _viewportHeight,
          // Pause while the finger is down, resume once the swipe settles.
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _pauseAutoPlay();
              } else if (n is ScrollEndNotification) {
                _resumeAutoPlay();
              }
              return false;
            },
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _index = i),
              children: slides,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        _dotIndicator(),
      ],
    );
  }

  /// Action-card slide: fills the deck width (with a side gap) and the full
  /// viewport height so all three action cards are exactly the same size.
  Widget _slide(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _slideGap),
      child: SizedBox(width: double.infinity, height: double.infinity, child: child),
    );
  }

  // ── Dot indicator ─────────────────────────────────────────
  // Active dot stretches into a short pill; the rest stay as small dots.
  Widget _dotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slideCount, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Action cards ──────────────────────────────────────────
  // All four share the same silhouette; only the hue changes: lavender
  // (contribution), teal (payments), indigo (catalog), coral (referrals).

  /// Contribution card — reactive to [ContributionController]. Shows the
  /// active plan + perks left when the merchant has one, otherwise the
  /// "Contribute now" CTA. Registering the controller here fires its
  /// /recharge APIs only when the Order tab (and thus this deck) is built.
  Widget _contributionCard() {
    final controller = getOrPut(() => ContributionController());
    return Obx(() {
      final hasPlan = controller.hasActiveRecharge.value;
      final data = controller.currentRecharge.value;
      String title;
      String subtitle;
      if (hasPlan && data != null && data.isNotEmpty) {
        final plan =
            (data['rechargePlanId'] is Map) ? data['rechargePlanId'] as Map : const {};
        title = (plan['name'] ?? AppStrings.contributeNow.tr).toString();
        final total = _asInt(data['total_perks']);
        final remaining = _asInt(data['perks_remaining']);
        subtitle = total > 0 ? '$remaining/$total perks left' : 'Membership active';
      } else {
        title = AppStrings.contributeNow.tr;
        subtitle = AppStrings.toGetOrderVisibility.tr;
      }
      return _ActionCard(
        onTap: () => Get.to(() => const ContributionScreenV2()),
        background: const [Color(0xFFF3ECFF), Color(0xFFE2D0FB)],
        border: const Color(0xFF844CD5),
        accent: const [Color(0xFF6D3BD0), Color(0xFF4B2A8E)],
        chevronTint: const Color(0xFF6D3BD0),
        titleColor: const Color(0xFF2A1A4A),
        subtitleColor: const Color(0xFF6E5F8E),
        icon: Icons.workspace_premium_rounded,
        title: title,
        subtitle: subtitle,
      );
    });
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Widget _bankCard() {
    return _ActionCard(
      onTap: () => Get.to(() => PaymentSettingScreen()),
      background: const [Color(0xFFEAFBF7), Color(0xFFCDEFE9)],
      border: const Color(0xFF0F9488),
      accent: const [Color(0xFF0D9488), Color(0xFF0F766E)],
      chevronTint: const Color(0xFF0F766E),
      titleColor: const Color(0xFF10302C),
      subtitleColor: const Color(0xFF3E7C73),
      icon: Icons.account_balance_rounded,
      title: 'Add Bank / UPI',
      subtitle: AppStrings.connectBankAccount.tr,
    );
  }

  Widget _catalogCard() {
    return _ActionCard(
      onTap: widget.onAddCatalog,
      background: const [Color(0xFFEEF2FF), Color(0xFFD7DDFF)],
      border: const Color(0xFF6366F1),
      accent: const [Color(0xFF4F46E5), Color(0xFF4338CA)],
      chevronTint: const Color(0xFF4F46E5),
      titleColor: const Color(0xFF1E1B4B),
      subtitleColor: const Color(0xFF4B4FA6),
      icon: widget.catalogIcon,
      title: widget.catalogTitle,
      subtitle: widget.catalogSubtitle,
    );
  }

  Widget _referCard() {
    return _ActionCard(
      onTap: () => Get.to(() => ReferralPage()),
      background: const [Color(0xFFFFF1EC), Color(0xFFFFD9CE)],
      border: const Color(0xFFFF7A59),
      accent: const [Color(0xFFFF6D00), Color(0xFFFF2D55)],
      chevronTint: const Color(0xFFFF3D5E),
      titleColor: const Color(0xFF3A1A16),
      subtitleColor: const Color(0xFFA85A4E),
      icon: Icons.card_giftcard_rounded,
      title: AppStrings.referAndEarn.tr,
      subtitle: AppStrings.inviteToBlueEra.tr,
    );
  }
}

/// A single tappable pastel action card used inside [OrderActionsCarousel].
/// Mirrors the contribution card's light treatment (soft gradient, hairline
/// border, dark ink) so the deck reads as one cohesive family.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onTap,
    required this.background,
    required this.border,
    required this.accent,
    required this.chevronTint,
    required this.titleColor,
    required this.subtitleColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final List<Color> background;
  final Color border;
  final List<Color> accent;
  final Color chevronTint;
  final Color titleColor;
  final Color subtitleColor;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        // Same soft drop shadow the contribution card uses.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: background,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                // Filled accent medallion — same dark-on-light device the
                // contribution card uses for its premium badge.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: accent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.last.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 19, color: Colors.white),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      CustomText(
                        subtitle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chevronTint.withValues(alpha: 0.12),
                    border: Border.all(
                      color: chevronTint.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: chevronTint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
