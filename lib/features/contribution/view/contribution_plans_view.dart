import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Static UI for the new "Contribution Plan" bottom sheet body.
///
/// Renders the three contribution tiers (Basic / Popular / Premium) shown in
/// `assets/subscription_new_ui.png`. No API hookup yet — the values are
/// hardcoded so we can finalize the visual design before wiring data.
class ContributionPlansView extends StatelessWidget {
  /// When true, the primary CTA is pinned to the bottom of the available
  /// area and the cards scroll independently above it. Used when this view
  /// is embedded inside the persistent peek bottom sheet so the action
  /// button stays visible without scrolling.
  final bool pinCta;

  /// When true, renders a leading title row + close button at the top.
  /// Set false when the host (e.g. peek sheet header) already shows a title.
  final bool showHeader;

  const ContributionPlansView({
    super.key,
    this.pinCta = false,
    this.showHeader = true,
  });

  double _scaled(double base) {
    if (SizeConfig.isTablet) return base * 1.25;
    final factor = (SizeConfig.screenWidth / 390.0).clamp(0.85, 1.15);
    return base * factor;
  }

  @override
  Widget build(BuildContext context) {
    final cards = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ContributionPlanCard(
          tier: _ContributionTier.basic,
          price: '${AppConstants.rupeeSymbol}999',
          duration: '/Year',
          perk: 'Get Accrued - 300 Ride',
          extraLabel: 'Get 10% Extra',
          benefitNote: null,
          scaled: _scaled,
        ),
        SizedBox(height: SizeConfig.size12),
        _ContributionPlanCard(
          tier: _ContributionTier.popular,
          price: '${AppConstants.rupeeSymbol}2,999',
          duration: 'Life Time',
          perk: 'Get Accrued - 300 Ride',
          extraLabel: 'Get 20% Extra',
          benefitNote: 'Get 1.4 Time More Benefit Of Basic Plan',
          scaled: _scaled,
        ),
        SizedBox(height: SizeConfig.size12),
        _ContributionPlanCard(
          tier: _ContributionTier.premium,
          price: '${AppConstants.rupeeSymbol}9,999',
          duration: 'Life Time',
          perk: 'Get Accrued - 300 Ride',
          extraLabel: 'Get 100% Extra',
          benefitNote: 'Get 2 Time More Benefit Of Basic Plan',
          scaled: _scaled,
        ),
      ],
    );

    final cta = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      child: CustomBtn(
        title: 'Kindly Contribute Us',
        bgColor: AppColors.primaryColor,
        onTap: () {},
      ),
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
              'Contribution Plan',
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

    if (pinCta) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader) header,
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                showHeader ? 0 : SizeConfig.size14,
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
          if (showHeader) header,
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              showHeader ? 0 : SizeConfig.size14,
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
  final _ContributionTier tier;
  final String price;
  final String duration;
  final String perk;
  final String extraLabel;
  final String? benefitNote;
  final double Function(double) scaled;

  const _ContributionPlanCard({
    required this.tier,
    required this.price,
    required this.duration,
    required this.perk,
    required this.extraLabel,
    required this.benefitNote,
    required this.scaled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(tier);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBorder, width: 1),
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
                      price,
                      fontSize: scaled(22),
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: scaled(3)),
                      child: CustomText(
                        duration,
                        fontSize: scaled(13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(theme: theme, scaled: scaled),
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
                  perk,
                  fontSize: scaled(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Wrap(
            spacing: SizeConfig.size8,
            runSpacing: SizeConfig.size8,
            children: [
              _OutlinedPill(
                  text: extraLabel, theme: theme, scaled: scaled),
              _OutlinedPill(
                  text: 'Refundable*', theme: theme, scaled: scaled),
              _OutlinedPill(
                  text: 'Verified Profile', theme: theme, scaled: scaled),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _DashedDivider(color: theme.cardBorder),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Icon(Icons.block_rounded,
                  size: scaled(14), color: AppColors.secondaryTextColor),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                'No Hidden Charges,',
                fontSize: scaled(12),
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size6),
              Icon(Icons.block_rounded,
                  size: scaled(14), color: AppColors.red33),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                'No AutoPay',
                fontSize: scaled(12),
                fontWeight: FontWeight.w600,
                color: AppColors.red33,
              ),
              const Spacer(),
              CustomText(
                '*T&C',
                fontSize: scaled(10),
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
          if (benefitNote != null) ...[
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                Icon(Icons.check_box_rounded,
                    size: scaled(16), color: AppColors.green39),
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: scaled(12.5),
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor,
                      ),
                      children: [
                        const TextSpan(text: 'Get '),
                        TextSpan(
                          text: benefitNote!
                              .replaceFirst('Get ', '')
                              .split(' Benefit')[0],
                          style: TextStyle(
                            color: AppColors.green39,
                            fontWeight: FontWeight.w700,
                            fontSize: scaled(12.5),
                          ),
                        ),
                        TextSpan(
                          text:
                              ' Benefit${benefitNote!.split(' Benefit').length > 1 ? benefitNote!.split(' Benefit')[1] : ''}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final _TierTheme theme;
  final double Function(double) scaled;

  const _Badge({required this.theme, required this.scaled});

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
            theme.badgeLabel,
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
