import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variant_picker_sheet.dart';
import 'package:BlueEra/widgets/already_added_badge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/product_select_plus_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared grocery product card whose "+" opens the variant picker, used by
/// both the products-selection grid ([GroceryProductsSelectionScreen]) and the
/// "Quick Upload" rails ([GrocerySuperCategoryScreen]) so the two stay
/// pixel-identical.
///
/// Pass [width] when the card lives in a horizontal rail (bounded-height
/// ListView) and leave it null when a grid controls the width. The Add button
/// is wrapped in its own [Obx] so selection changes update it even when the
/// host list isn't itself observing [GroceryController.selectedGroceries].
class GroceryProductSelectCard extends StatelessWidget {
  final GroceryProductData product;
  final GroceryController controller;
  final double? width;

  const GroceryProductSelectCard({
    super.key,
    required this.product,
    required this.controller,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final variant =
        (product.variants?.isNotEmpty ?? false) ? product.variants!.first : null;
    final price = controller.getPriceDetails(variant?.pricing);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  padding: EdgeInsets.only(top: 4.0),
                  height: SizeConfig.size140,
                  width: double.infinity,
                  child: (product.images?.isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: product.images!.first.url ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => LocalAssets(
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
              // Top-right add toggle (replaces the old full-width "Add").
              // Boolean selection → shows a check when added.
              Positioned(
                top: SizeConfig.size8,
                right: SizeConfig.size8,
                child: Obx(() {
                  // Every variant of this product is already in the store's own
                  // inventory, so adding it again would publish a duplicate row
                  // for the same catalogue variant — a second price for one
                  // item on the merchant's own shelf. Say so on the card
                  // instead of offering a "+" that opens a sheet with nothing
                  // tickable in it.
                  if (controller.isProductFullyStocked(product)) {
                    return const AlreadyAddedBadge();
                  }
                  // The "+" opens the variant picker rather than selecting the
                  // whole product: a store stocking only the 500 g pack had no
                  // way to say so, and publishing all of them was the default.
                  final count = controller.selectedVariantCount(product.sId);
                  return ProductSelectPlusButton(
                    added: count > 0,
                    count: count > 0 ? count : null,
                    onTap: () => showGroceryVariantPickerSheet(
                      context: context,
                      product: product,
                      controller: controller,
                    ),
                  );
                }),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 8.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${product.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (variant?.isVegetarian != null) ...[
                      FoodTypeIndicator(
                          isVegetarian: variant?.isVegetarian ?? false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                width: 0.5, color: AppColors.greyE5)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: CustomText(
                          '${variant?.quantity ?? ''}',
                          fontSize: 11,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: "${price.sellingRange}",
                  mrp: "${price.mrpRange}",
                  discount: "${price.discountRange}",
                ),
                // The partly-stocked case. The corner badge only appears once
                // EVERY variant is stocked, so without this a product the
                // merchant has half-added looks untouched.
                Obx(() => AlreadyAddedCountLine(
                      stocked: controller.stockedVariantCount(product),
                      total: product.variants?.length ?? 0,
                    )),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }
}
