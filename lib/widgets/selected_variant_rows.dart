import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One picked variant, as the review rows need to see it.
class SelectedVariantRow {
  const SelectedVariantRow({
    required this.id,
    required this.title,
    this.mrp,
    this.sellingPrice,
  });

  final String id;

  /// "500 g", "10 tablet" — whatever the merchant recognises the pack by.
  final String title;

  /// Pre-formatted: grocery reads `pricing[0]`, medical resolves the row for
  /// its own pincode, and the caller knows which.
  final String? mrp;
  final String? sellingPrice;
}

/// The picked variants of one product, with a price pen and a remove on each —
/// what the merchant is about to publish, and nothing else.
///
/// This is the review half of the food-style flow: the picker sheet answers
/// "which packs do I stock", these rows answer "at what price". Listing the
/// whole catalogue here instead (the old behaviour) made the review step a
/// second, differently-shaped picker, and it never showed which of those rows
/// were actually in the cart.
///
/// [rowsBuilder] runs inside an [Obx], so it must read the controller's
/// observables directly rather than being handed a snapshot.
class SelectedVariantList extends StatelessWidget {
  const SelectedVariantList({
    super.key,
    required this.rowsBuilder,
    required this.onEdit,
    required this.onRemove,
    this.emptyLabel = 'No packs picked yet',
  });

  final List<SelectedVariantRow> Function() rowsBuilder;
  final void Function(String variantId) onEdit;
  final void Function(String variantId) onRemove;

  /// Shown when nothing is picked — the card still has to say something, and
  /// "empty" is a state the merchant can get to by removing the last row.
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = rowsBuilder();
      if (rows.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
          child: CustomText(
            emptyLabel,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map(_row).toList(),
      );
    });
  }

  Widget _row(SelectedVariantRow row) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        children: [
          // Title / MRP / selling share whatever's left, so the two trailing
          // actions always land flush at the row's end.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: CustomText(
                    row.title,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 2.0,
                  height: SizeConfig.size16,
                  color: AppColors.greyLite,
                ),
                const SizedBox(width: 6),
                Flexible(
                  // Labelled, like the selling price beside it. An unlabelled
                  // figure between the pack size and the selling price is just
                  // a number the merchant has to guess at, and guessing wrong
                  // here means publishing the wrong price.
                  child: CustomText(
                    'MRP: ${row.mrp ?? '-'}',
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 2.0,
                  height: SizeConfig.size16,
                  color: AppColors.greyLite,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: CustomText(
                    'Selling: ${row.sellingPrice ?? '-'}',
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onEdit(row.id),
            child: LocalAssets(
              imagePath: AppIconAssets.pen_line,
              imgColor: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          // Removing the last pack of a product drops the product from the
          // cart entirely — the controllers keep those two in step.
          InkWell(
            onTap: () => onRemove(row.id),
            child: Icon(
              Icons.close,
              size: SizeConfig.size18,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add packs" / "3 packs • edit" — the button that opens the variant picker
/// from a review card.
///
/// The review screen used to double as a picker (a checkbox against every
/// catalogue variant). Now there is one picker, reached from here as well as
/// from the product card, so a pack the merchant forgot is one tap away
/// without a second control that behaves almost-but-not-quite the same.
class PickVariantsButton extends StatelessWidget {
  const PickVariantsButton({
    super.key,
    required this.count,
    required this.onTap,
    this.addLabel = 'Add packs',
  });

  final int count;
  final VoidCallback onTap;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(count > 0 ? Icons.edit_outlined : Icons.add,
                size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              count > 0 ? '$count picked' : addLabel,
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
