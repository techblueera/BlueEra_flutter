import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/contribution/model/recharge_plan_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Contribution Plan" sheet body. Loads recharge plans from
/// `GET /recharge/plans` and lets the user pay via Razorpay
/// (`POST /recharge/initiate-order` → checkout → `POST /recharge/verify-payment`).
/// See `lib/docs/RECHARGE_FLUTTER_GUIDE.md`.
class ContributionPlansView extends StatefulWidget {
  /// When true, the primary CTA is pinned to the bottom of the available
  /// area and the cards scroll independently above it. Used when this view
  /// is embedded inside the persistent peek bottom sheet so the action
  /// button stays visible without scrolling.
  final bool pinCta;

  /// When true, renders a leading title row + close button at the top.
  /// Set false when the host (e.g. peek sheet header) already shows a title.
  final bool showHeader;

  /// Optional bucket filter passed to `GET /recharge/plans?entity_type=...`.
  /// Defaults to whatever `userProfessionGlobal` maps to.
  final String? entityType;

  const ContributionPlansView({
    super.key,
    this.pinCta = false,
    this.showHeader = true,
    this.entityType,
  });

  @override
  State<ContributionPlansView> createState() => _ContributionPlansViewState();
}

class _ContributionPlansViewState extends State<ContributionPlansView> {
  late final ContributionController _ctrl;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = getOrPut(() => ContributionController());
    _hydrateBuyerDetails();
    // Ensure the plans are loaded when the view mounts. This is cache-first:
    // fetchPlans serves the locally-stored catalog while it's fresh (< 24h)
    // and only hits the network on a miss/stale entry, so calling it on every
    // mount is cheap and covers the case where the controller was created
    // earlier (e.g. by the bottom-nav initState) but the plans hadn't landed.
    _ctrl.fetchPlans(entityType: widget.entityType);
  }

  void _hydrateBuyerDetails() {
    try {
      final viewCtrl = Get.find<ViewPersonalDetailsController>();
      final user = viewCtrl.personalProfileDetails.value.user;
      _ctrl.userName = user?.name ?? '';
      _ctrl.userEmail = user?.email ?? '';
      _ctrl.userPhone = user?.contactNo ?? userMobileGlobal;
    } catch (_) {
      _ctrl.userPhone = userMobileGlobal;
    }
  }

  double _scaled(double base) {
    if (SizeConfig.isTablet) return base * 1.25;
    final factor = (SizeConfig.screenWidth / 390.0).clamp(0.85, 1.15);
    return base * factor;
  }

  @override
  Widget build(BuildContext context) {
    final cards = Obx(() {
      final status = _ctrl.plansStatus.value;
      // Suppress the loader during the initial fetch — this view sits
      // inside the bottom-nav subscription peek sheet and a spinner here
      // surfaces as a stray "loader from the bottom navigation bar" on
      // app open. We render an empty placeholder while loading so plans
      // populate quietly once they land.
      if (status == Status.LOADING || status == Status.INITIAL) {
        return const SizedBox.shrink();
      }
      if (status == Status.ERROR) {
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size24),
          child: Column(
            children: [
              CustomText(
                _ctrl.plansError.value.isNotEmpty
                    ? _ctrl.plansError.value
                    : AppStrings.couldNotLoadPlans.tr,
                textAlign: TextAlign.center,
                color: AppColors.secondaryTextColor,
                fontSize: _scaled(14),
              ),
              SizedBox(height: SizeConfig.size10),
              TextButton(
                onPressed: () => _ctrl.fetchPlans(
                    entityType: widget.entityType, forceRefresh: true),
                child: Text(AppStrings.retry.tr),
              ),
            ],
          ),
        );
      }
      final plans = _ctrl.plans;
      if (plans.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
          child: Center(
            child: CustomText(
              AppStrings.noContributionPlansAvailable.tr,
              fontSize: _scaled(13),
              color: AppColors.secondaryTextColor,
            ),
          ),
        );
      }
      // Clamp selection to available range whenever the list reloads.
      if (_selectedIndex >= plans.length) _selectedIndex = 0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < plans.length; i++) ...[
            _ContributionPlanCard(
              plan: plans[i],
              tier: _tierFor(plans[i].tier, i),
              isSelected: i == _selectedIndex,
              onTap: () => setState(() => _selectedIndex = i),
              scaled: _scaled,
            ),
            if (i != plans.length - 1) SizedBox(height: SizeConfig.size12),
          ],
        ],
      );
    });

    final cta = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      child: Obx(() => CustomBtn(
            title: _ctrl.isPurchasing.value
                ? AppStrings.processingEllipsis.tr
                : AppStrings.kindlyContributeUs.tr,
            bgColor: AppColors.primaryColor,
            onTap: _ctrl.isPurchasing.value ? () {} : _onContributeTap,
          )),
    );

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size8,
        SizeConfig.size10,
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.contributionPlan.tr,
              fontSize: _scaled(18),
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close_rounded,
              size: _scaled(22),
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );

    if (widget.pinCta) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) header,
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                widget.showHeader ? 0 : SizeConfig.size14,
                SizeConfig.size16,
                SizeConfig.size12,
              ),
              child: cards,
            ),
          ),
          cta,
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) header,
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              widget.showHeader ? 0 : SizeConfig.size14,
              SizeConfig.size16,
              SizeConfig.size4,
            ),
            child: cards,
          ),
          cta,
        ],
      ),
    );
  }

  void _onContributeTap() {
    final plans = _ctrl.plans;
    if (plans.isEmpty) return;
    final plan = plans[_selectedIndex];
    _ctrl.purchase(plan);
  }

  /// Map server `tier` strings to the three visual themes the design covers.
  /// Falls back to position-based theming so plans like `advance` / `pro` /
  /// `proplus` still render with sensible colors.
  _ContributionTier _tierFor(String tier, int index) {
    switch (tier.toLowerCase()) {
      case 'basic':
        return _ContributionTier.basic;
      case 'popular':
        return _ContributionTier.popular;
      case 'advance':
      case 'pro':
      case 'proplus':
      case 'premium':
        return _ContributionTier.premium;
    }
    if (index == 0) return _ContributionTier.basic;
    if (index == 1) return _ContributionTier.popular;
    return _ContributionTier.premium;
  }
}

enum _ContributionTier { basic, popular, premium }

class _TierTheme {
  final Color cardBg;
  final Color cardBorder;
  final Color badgeBg;
  final Color badgeText;
  final IconData badgeIcon;
  final String badgeLabel;
  final Color pillBg;
  final Color pillBorder;
  final Color pillText;

  const _TierTheme({
    required this.cardBg,
    required this.cardBorder,
    required this.badgeBg,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.pillBg,
    required this.pillBorder,
    required this.pillText,
  });
}

const _basicTheme = _TierTheme(
  cardBg: Color(0xFFE6F2FB),
  cardBorder: Color(0xFFCFE5F4),
  badgeBg: Color(0xFF3FB6E6),
  badgeText: Color(0xFFFFFFFF),
  badgeIcon: Icons.auto_awesome_rounded,
  badgeLabel: 'BASIC',
  pillBg: Color(0xFFF3FAFE),
  pillBorder: Color(0xFFCFE5F4),
  pillText: Color(0xFF1F2A37),
);

const _popularTheme = _TierTheme(
  cardBg: Color(0xFFFFF6DC),
  cardBorder: Color(0xFFF3E1A8),
  badgeBg: Color(0xFFF6B431),
  badgeText: Color(0xFFFFFFFF),
  badgeIcon: Icons.star_rounded,
  badgeLabel: 'POPULAR',
  pillBg: Color(0xFFFFFCEF),
  pillBorder: Color(0xFFF3E1A8),
  pillText: Color(0xFF1F2A37),
);

const _premiumTheme = _TierTheme(
  cardBg: Color(0xFFEFE6F8),
  cardBorder: Color(0xFFD8C8EC),
  badgeBg: Color(0xFF4B1F7A),
  badgeText: Color(0xFFFFFFFF),
  badgeIcon: Icons.workspace_premium_rounded,
  badgeLabel: 'PREMIUM',
  pillBg: Color(0xFFF7F2FC),
  pillBorder: Color(0xFFD8C8EC),
  pillText: Color(0xFF1F2A37),
);

_TierTheme _themeFor(_ContributionTier tier) {
  switch (tier) {
    case _ContributionTier.basic:
      return _basicTheme;
    case _ContributionTier.popular:
      return _popularTheme;
    case _ContributionTier.premium:
      return _premiumTheme;
  }
}

class _ContributionPlanCard extends StatelessWidget {
  final RechargePlan plan;
  final _ContributionTier tier;
  final bool isSelected;
  final VoidCallback onTap;
  final double Function(double) scaled;

  const _ContributionPlanCard({
    required this.plan,
    required this.tier,
    required this.isSelected,
    required this.onTap,
    required this.scaled,
  });

  String _formatRupees(int paise) {
    final rupees = paise / 100;
    // Whole rupees → no decimals; otherwise one decimal place.
    if (rupees == rupees.truncateToDouble()) {
      return rupees.toInt().toString();
    }
    return rupees.toStringAsFixed(2);
  }

  /// First perk line (the doc shows this is the headline like "25 Rides + 5 Bonus").
  String _headlinePerk() {
    if (plan.perks.isNotEmpty) return plan.perks.first;
    if (plan.perkValue > 0) {
      final type = plan.perkType.isEmpty ? AppStrings.perksLowercase.tr : plan.perkType;
      final base = '${plan.perkValue} ${type[0].toUpperCase()}${type.substring(1)}';
      if (plan.perkBonus > 0) return '$base + ${plan.perkBonus} ${AppStrings.bonusLabel.tr}';
      return base;
    }
    return plan.description ?? plan.name;
  }

  /// Localized label for the tier badge — falls back to the const theme
  /// label string only if no translation exists.
  String _tierLabelFor(_ContributionTier t) {
    switch (t) {
      case _ContributionTier.basic:
        return AppStrings.basicTier.tr;
      case _ContributionTier.popular:
        return AppStrings.popularTier.tr;
      case _ContributionTier.premium:
        return AppStrings.premiumTier.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(tier);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : theme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: SizeConfig.size6,
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${_formatRupees(plan.amount)}',
                        fontSize: scaled(22),
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      if (plan.taxPercent > 0)
                        Padding(
                          padding: EdgeInsets.only(bottom: scaled(3)),
                          child: CustomText(
                            '+ ${plan.taxPercent}${AppStrings.gstSuffix.tr}',
                            fontSize: scaled(12),
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                _Badge(
                  theme: theme,
                  scaled: scaled,
                  label: _tierLabelFor(tier),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: scaled(18), color: AppColors.mainTextColor),
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: CustomText(
                    _headlinePerk(),
                    fontSize: scaled(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            if (plan.perks.length > 1) ...[
              SizedBox(height: SizeConfig.size10),
              Wrap(
                spacing: SizeConfig.size8,
                runSpacing: SizeConfig.size8,
                children: [
                  for (final p in plan.perks.skip(1).take(3))
                    _OutlinedPill(text: p, theme: theme, scaled: scaled),
                ],
              ),
            ],
            SizedBox(height: SizeConfig.size10),
            _DashedDivider(color: theme.cardBorder),
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                Icon(Icons.block_rounded,
                    size: scaled(14), color: AppColors.secondaryTextColor),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  AppStrings.noHiddenCharges.tr,
                  fontSize: scaled(12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                Icon(Icons.block_rounded,
                    size: scaled(14), color: AppColors.red33),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  AppStrings.noAutoPay.tr,
                  fontSize: scaled(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.red33,
                ),
                const Spacer(),
                CustomText(
                  AppStrings.tcStar.tr,
                  fontSize: scaled(10),
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final _TierTheme theme;
  final String label;
  final double Function(double) scaled;

  const _Badge({
    required this.theme,
    required this.label,
    required this.scaled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: theme.badgeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(theme.badgeIcon, size: scaled(14), color: theme.badgeText),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            label.isNotEmpty ? label : theme.badgeLabel,
            fontSize: scaled(11),
            fontWeight: FontWeight.w700,
            color: theme.badgeText,
          ),
        ],
      ),
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  final String text;
  final _TierTheme theme;
  final double Function(double) scaled;

  const _OutlinedPill({
    required this.text,
    required this.theme,
    required this.scaled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: theme.pillBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.pillBorder, width: 1),
      ),
      child: CustomText(
        text,
        fontSize: scaled(11.5),
        fontWeight: FontWeight.w500,
        color: theme.pillText,
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

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
              color: color,
            ),
          ),
        );
      },
    );
  }
}
