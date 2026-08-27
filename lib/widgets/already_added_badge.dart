import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// "Already added" — the corner badge on a catalogue product whose every
/// variant the merchant already stocks.
///
/// One definition for every me-section vertical (food, grocery, product,
/// medical, automotive, vehicle). They all ask the same question of their own
/// `stockedVariantIds` set and all need to answer it identically; a private
/// copy per feature is how the six of them would quietly drift apart.
///
/// Occupies the same corner the add button would, at the same size, so a rail
/// of cards keeps one alignment whichever state each card is in.
class AlreadyAddedBadge extends StatelessWidget {
  const AlreadyAddedBadge({super.key, this.label = 'Already added'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// "2 of 5 already added" — the PARTIAL case, which [AlreadyAddedBadge] cannot
/// show: that only appears once EVERY variant is stocked.
///
/// Without this the merchant opens the variant sheet, finds two rows greyed out
/// and no explanation on the card that sent them there. Renders nothing when
/// there is nothing to say — none stocked, or all of them (the badge has it).
class AlreadyAddedCountLine extends StatelessWidget {
  const AlreadyAddedCountLine({
    super.key,
    required this.stocked,
    required this.total,
  });

  final int stocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (stocked <= 0 || total <= 0 || stocked >= total) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: CustomText(
              '$stocked of $total already added',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
