import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variant_picker_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/selected_variant_rows.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddGroceryVariantScreen extends StatefulWidget {
  const AddGroceryVariantScreen({super.key});

  @override
  State<AddGroceryVariantScreen> createState() => _AddGroceryVariantScreenState();
}

class _AddGroceryVariantScreenState extends State<AddGroceryVariantScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=> Scaffold(
      appBar: CommonBackAppBar(),
      bottomNavigationBar: Container(
        color: AppColors.white,
        padding: EdgeInsets.all(SizeConfig.size15),
        child: SafeArea(
          child: Obx(() {
            final canSubmit = controller.canSubmitProducts;

            final int productCount = controller.selectedProductVariants.keys.length;
            final variantCount = controller.selectedProductVariants.values.fold(0, (sum, list) => sum + list.length);
            final isLoading = controller.isAddGroceryProductsLoading.value;

            return CustomBtn(
              onTap: canSubmit && !isLoading
                  ? () => controller.addGroceryProductNewVariant()
                  : null,
              isValidate: canSubmit,
              radius: SizeConfig.size8,
              bgColor: canSubmit ? AppColors.primaryColor : Colors.grey,
              title: AppStrings.groceryViewPublishProductsVariants.trParams({
                'productCount': '$productCount',
                'variantCount': '$variantCount',
              }),
              isLoading: isLoading,
            );
          }),
        ),
      ),
      body: AbsorbPointer(
        absorbing: controller.isAddGroceryProductsLoading.value,
        child: ListView.builder(
          itemCount: controller.selectedGroceries.length,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15
          ),
          itemBuilder: (BuildContext context, int index) {
            final groceryItem = controller.selectedGroceries[index];
            // List<Variants> groceryVariants = groceryItem.variants??[];
            return _selectedGroceryCard(groceryItem);
          },
        ),
      ),
    ));
  }

  /// The packs of [product] in the cart, in catalogue order.
  ///
  /// Read off the selection map rather than the product's own variant list:
  /// the map is what the publish payload is built from, so anything this
  /// screen shows is by definition something that will be sent.
  List<ProductVariants> _pickedVariants(GroceryProductData product) =>
      controller.selectedProductVariants[product.sId ?? ''] ??
      const <ProductVariants>[];

  ProductVariants? _variantById(GroceryProductData product, String id) =>
      (product.variants ?? const <ProductVariants>[])
          .firstWhereOrNull((v) => v.sId == id);

  Widget _selectedGroceryCard(GroceryProductData groceryItem){
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(
          bottom: SizeConfig.size12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:  (groceryItem.images!=null &&  groceryItem.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: groceryItem.images!.first.url??'',
                    fit: BoxFit.cover,
                    height: SizeConfig.size80,
                    width: SizeConfig.size80,
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
                      boxFix: BoxFit.fill,
                      height: SizeConfig.size80,
                      width: SizeConfig.size80
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// --- Product Title + picker ---
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                groceryItem.name,
                                fontSize: SizeConfig.medium,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            // One picker, reachable from here as well as from
                            // the product card. This screen used to be a
                            // second, differently-shaped picker (a checkbox
                            // against every catalogue variant) that never
                            // showed which rows were actually in the cart.
                            Obx(() => PickVariantsButton(
                                  count: controller
                                      .selectedVariantCount(groceryItem.sId),
                                  onTap: () => showGroceryVariantPickerSheet(
                                    context: context,
                                    product: groceryItem,
                                    controller: controller,
                                  ),
                                )),
                          ],
                        ),
                      ),

                      SizedBox(height: SizeConfig.size8),

                      /// --- Picked packs (the cart), with price + remove ---
                      SelectedVariantList(
                        rowsBuilder: () => _pickedVariants(groceryItem)
                            .map((v) => SelectedVariantRow(
                                  id: v.sId ?? '',
                                  title: (v.quantity?.trim().isNotEmpty ?? false)
                                      ? v.quantity!
                                      : (v.variantName ?? ''),
                                  mrp: v.pricing?.isNotEmpty == true
                                      ? '₹${v.pricing![0].mrp}'
                                      : null,
                                  sellingPrice: v.pricing?.isNotEmpty == true
                                      ? '₹${v.pricing![0].sellingPrice}'
                                      : null,
                                ))
                            .toList(),
                        onEdit: (id) {
                          final v = _variantById(groceryItem, id);
                          if (v == null) return;
                          controller.openEditVariantDialog(
                            context: context,
                            title: groceryItem.name ??
                                AppStrings.groceryViewEditVariant.tr,
                            variant: v,
                          );
                        },
                        onRemove: (id) {
                          final v = _variantById(groceryItem, id);
                          if (v == null) return;
                          controller.toggleVariantSelection(groceryItem, v);
                        },
                      )

                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: SizeConfig.size10),

          GestureDetector(
            onTap: () {
              controller.openAddVariantDialog(
                context: context,
                groceryItem: groceryItem,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  CupertinoIcons.add,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 6),
                CustomText(
                  AppStrings.groceryViewAddMoreVariant.tr,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.small,
                ),
              ],
            ),
          )

        ],
      ),
    );
  }

}
