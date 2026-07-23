import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/rider_orders_details_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// The customer's rider-given rating, as shown on the rider's order cards.
///
/// This is the rider's read on who they are about to pick up, so it has to be
/// legible at a glance and honest about what it doesn't know: an unrated
/// customer (`0 / 0`, which is what the backend returns until riders start
/// voting) shows as "New", never as a zero-star score.
///
/// Collapses to nothing when [rating] is null — older payloads and non-ride
/// orders simply don't carry it.
class CustomerRatingBadge extends StatelessWidget {
  const CustomerRatingBadge({super.key, required this.rating, this.compact = false});

  final RatingSummary? rating;

  /// Drops the vote count, for rows that are already tight.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final r = rating;
    if (r == null) return const SizedBox.shrink();

    final rated = r.hasRatings;
    final color = rated ? const Color(0xFFFFA000) : AppColors.secondaryTextColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size6,
        vertical: SizeConfig.size2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rated ? Icons.star_rounded : Icons.person_outline_rounded,
              size: SizeConfig.size12, color: color),
          SizedBox(width: SizeConfig.size2),
          CustomText(
            rated ? r.average.toStringAsFixed(1) : 'New',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          if (rated && !compact) ...[
            SizedBox(width: SizeConfig.size2),
            CustomText(
              '(${r.count})',
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }
}
