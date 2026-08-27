import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/already_added_badge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One row in a [VariantPickerSheet] — a catalogue variant as the picker needs
/// to see it, with the vertical's own model already flattened away.
class VariantPickerRow {
  const VariantPickerRow({
    required this.id,
    required this.title,
    this.sellingPrice,
    this.mrp,
    this.isStocked = false,
    this.isSelected = false,
  });

  final String id;

  /// What the merchant recognises the variant by — "500 g", "10 tablet".
  final String title;

  /// Pre-formatted, because every vertical formats money its own way (grocery
  /// reads `pricing[0]`, medical resolves the row for its own pincode).
  final String? sellingPrice;
  final String? mrp;

  /// Already in this merchant's own inventory — locked, not tickable.
  final bool isStocked;

  final bool isSelected;
}

/// Variant selection sheet, shared by the verticals that publish catalogue
/// variants into their own inventory (grocery, medical — food has its own,
/// older copy carrying dish-specific chrome).
///
/// Two things it exists to do:
///
/// 1. **Pick variants, not products.** Selecting a whole product publishes
///    every pack size it has; the merchant almost never stocks all of them.
/// 2. **Refuse a duplicate.** A variant the merchant already stocks is shown
///    as a settled state rather than a control — ticking it again would
///    publish a second inventory record against one catalogue variant, which
///    is a duplicate row and a second price for one item.
///
/// Every tick commits straight through [onToggle]; there is no "Save" step, so
/// the floating cart on the screen underneath counts live. [rowsBuilder] is
/// called inside an [Obx], so it must read the controller's observables
/// directly rather than being handed a snapshot.
class VariantPickerSheet extends StatelessWidget {
  const VariantPickerSheet({
    super.key,
    required this.productName,
    required this.rowsBuilder,
    required this.onToggle,
    required this.stockedNote,
    this.imageUrl,
    this.description,
    this.onAddMore,
    this.addMoreLabel = 'Add More Variant',
    this.emptyLabel = 'No variants yet',
  });

  final String productName;
  final String? imageUrl;
  final String? description;

  /// Re-read on every rebuild — see the class doc.
  final List<VariantPickerRow> Function() rowsBuilder;

  final void Function(String variantId) onToggle;

  /// The sentence under a locked row. Vertical-specific on purpose: "your
  /// store" and "your menu" are different places to the merchant reading it.
  final String stockedNote;

  final VoidCallback? onAddMore;
  final String addMoreLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Obx(() {
          final rows = rowsBuilder();
          final selectedCount = rows.where((r) => r.isSelected).length;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(selectedCount),
                _productInfo(),
                const Divider(),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CustomText(
                      emptyLabel,
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  )
                else
                  ...rows.map(_variantRow),
                if (onAddMore != null) _addMoreButton(),
                const SizedBox(height: 16),
                PositiveCustomBtn(
                  onTap: () => Get.back(),
                  title: selectedCount > 0
                      ? 'Done  •  $selectedCount in cart'
                      : 'Done',
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _header(int selectedCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CustomText(
              'All Variants',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  '$selectedCount in cart',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _productInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 60,
            width: 60,
            child: (imageUrl?.isNotEmpty ?? false)
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                : LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                productName,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                CustomText(
                  description!,
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _variantRow(VariantPickerRow row) {
    return InkWell(
      onTap: row.isStocked ? null : () => onToggle(row.id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          // Tinted rather than white, so a stocked row reads as settled
          // instead of merely unticked.
          color: row.isStocked ? AppColors.fillColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: row.isStocked
                ? AppColors.greyE5
                : (row.isSelected ? AppColors.primaryColor : AppColors.greyE5),
            width: row.isSelected && !row.isStocked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (row.isStocked)
              // A tick in a circle, not a checkbox: this is a STATE, not a
              // control, and a ticked checkbox invites a tap to untick it.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 22,
                  color: Colors.green.shade600,
                ),
              )
            else
              Checkbox(
                value: row.isSelected,
                side: BorderSide(
                  color:
                      row.isSelected ? AppColors.primaryColor : AppColors.greyE5,
                  width: 1.5,
                ),
                activeColor: AppColors.primaryColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => onToggle(row.id),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          row.title,
                          fontSize: 16,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (row.isStocked) ...[
                        const SizedBox(width: 8),
                        const AlreadyAddedChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          'Selling: ${row.sellingPrice ?? '-'}',
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          height: 15, width: 1.5, color: Colors.grey.shade300),
                      const SizedBox(width: 8),
                      // The label stays upright; only the figure is struck
                      // through, so "MRP" reads as a heading rather than as
                      // something that has been cancelled.
                      CustomText(
                        'MRP: ',
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                      CustomText(
                        row.mrp ?? '-',
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ],
                  ),
                  if (row.isStocked) ...[
                    const SizedBox(height: 6),
                    _stockedNote(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The sentence under a locked row.
  ///
  /// The chip labels the row; this says what to do about it, because the
  /// merchant's next question is "then where do I change its price?" and the
  /// answer is their own Products tab, not this sheet.
  Widget _stockedNote() {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 12, color: Colors.green.shade700),
        const SizedBox(width: 4),
        Expanded(
          child: CustomText(
            stockedNote,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.green.shade700,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _addMoreButton() {
    return InkWell(
      onTap: onAddMore,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.add, color: AppColors.primaryColor),
            CustomText(addMoreLabel, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}
