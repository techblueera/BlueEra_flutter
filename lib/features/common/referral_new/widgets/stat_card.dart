import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Generic card for the Statics tab. Top row carries the title and an
/// optional "View Details" CTA; the body is composed of a left-column
/// emphasised metric and a right-column key/value list.
class ReferralStatCard extends StatelessWidget {
  final String title;
  final String? leftLabel;
  final String? leftValue;
  final List<ReferralStatRow> rows;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;

  const ReferralStatCard({
    super.key,
    required this.title,
    required this.rows,
    this.leftLabel,
    this.leftValue,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.bar_chart_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (actionLabel != null)
                InkWell(
                  onTap: onAction,
                  child: CustomText(
                    actionLabel!,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leftValue != null) ...[
                  Expanded(
                    child: Column(
                      children: [
                        CustomText(
                          leftValue!,
                          fontSize: SizeConfig.extraLarge22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                        if (leftLabel != null) ...[
                          const SizedBox(height: 4),
                          CustomText(
                            leftLabel!,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    color: AppColors.whiteE5,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
                Expanded(
                  flex: leftValue != null ? 1 : 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows
                        .map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      r.label,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                  CustomText(
                                    r.value,
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w600,
                                    color: r.valueColor ??
                                        AppColors.mainTextColor,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          if (secondaryActionLabel != null) ...[
            SizedBox(height: SizeConfig.paddingXSL),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSecondaryAction,
                icon: Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.primaryColor, size: 16),
                label: CustomText(
                  secondaryActionLabel!,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReferralStatRow {
  final String label;
  final String value;
  final Color? valueColor;
  const ReferralStatRow(this.label, this.value, {this.valueColor});
}
