import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical/widget/medical_variant_picker_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/selected_variant_rows.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMedicalVariantScreen extends StatefulWidget {
  const AddMedicalVariantScreen({super.key});

  @override
  State<AddMedicalVariantScreen> createState() =>
      _AddMedicalVariantScreenState();
}

class _AddMedicalVariantScreenState extends State<AddMedicalVariantScreen> {
  final controller = getOrPut(() => MedicalController());

  /// The `pricing[]` row this variant will be **published** with — this shop's
  /// pincode when the catalog has one, otherwise the first row.
  ///
  /// Same resolver `buildInventoryPayload` uses, on purpose: this screen is the
  /// last thing a merchant sees before hitting Publish, so it has to show the
  /// figures that are actually going to be sent.
  Pricing? _localPricing(VariantsData variant) =>
      controller.resolvePublishPricing(variant.pricing);

  /// The packs of [product] in the cart, in catalogue order.
  ///
  /// Read off the selection map rather than the product's own variant list:
  /// the map is what the publish payload is built from, so anything this
  /// screen shows is by definition something that will be sent.
  List<VariantsData> _pickedVariants(MedicalProductData product) =>
      controller.selectedProductVariants[product.sId ?? ''] ??
      const <VariantsData>[];

  VariantsData? _variantById(MedicalProductData product, String id) =>
      (product.variants ?? const <VariantsData>[])
          .firstWhereOrNull((v) => v.sId == id);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: CommonBackAppBar(),
          bottomNavigationBar: Container(
            color: AppColors.white,
            padding: EdgeInsets.all(SizeConfig.size15),
            child: SafeArea(child: GetBuilder<MedicalController>(
              builder: (controller) {
                return CustomBtn(
                  onTap: controller.canSubmitProducts
                      ? () {
                          controller.addMedicalProductNewVariant();
                        }
                      : null,
                  isValidate: controller.canSubmitProducts,
                  radius: SizeConfig.size8,
                  bgColor: controller.canSubmitProducts
                      ? AppColors.primaryColor
                      : Colors.grey,
                  title: AppStrings.medicalPublishProductsVariants.trParams({
                    'productCount':
                        '${controller.selectedMedicalProducts.length}',
                    // Variants, not map keys — `.length` on the map is the
                    // number of PRODUCTS, so the label read "3 products, 3
                    // variants" for a cart holding seven packs.
                    'variantCount': '${controller.selectedProductVariants.values.fold(0, (sum, list) => sum + list.length)}',
                  }),
                  isLoading: controller.isAddMedicalProductsLoading.value,
                );
              },
            )),
          ),
          body: AbsorbPointer(
            absorbing: controller.isAddMedicalProductsLoading.value,
            child: ListView.builder(
              itemCount: controller.selectedMedicalProducts.length,
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8, vertical: SizeConfig.size15),
              itemBuilder: (BuildContext context, int index) {
                final groceryItem = controller.selectedMedicalProducts[index];
                // List<Variants> groceryVariants = groceryItem.variants??[];
                return CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  margin: EdgeInsets.only(bottom: SizeConfig.size12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(SizeConfig.size10),
                        decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: (groceryItem.images != null &&
                                      groceryItem.images!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          groceryItem.images!.first.url ?? '',
                                      fit: BoxFit.cover,
                                      height: SizeConfig.size80,
                                      width: SizeConfig.size80,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          LocalAssets(
                                        imagePath:
                                            AppIconAssets.place_holder_image,
                                        boxFix: BoxFit.cover,
                                      ),
                                    )
                                  : LocalAssets(
                                      imagePath:
                                          AppIconAssets.place_holder_image,
                                      boxFix: BoxFit.fill,
                                      height: SizeConfig.size80,
                                      width: SizeConfig.size80),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// --- Product Title + picker ---
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: SizeConfig.size10),
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
                                        // One picker, reachable from here as
                                        // well as from the product card. This
                                        // screen used to be a second,
                                        // differently-shaped picker (a checkbox
                                        // against every catalogue variant) that
                                        // never showed which rows were actually
                                        // in the cart.
                                        Obx(() => PickVariantsButton(
                                              count: controller
                                                  .selectedVariantCount(
                                                      groceryItem.sId),
                                              onTap: () =>
                                                  showMedicalVariantPickerSheet(
                                                context: context,
                                                product: groceryItem,
                                                controller: controller,
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: SizeConfig.size8),

                                  /// --- Picked packs (the cart), with price
                                  /// and remove on each ---
                                  SelectedVariantList(
                                    rowsBuilder: () => _pickedVariants(
                                            groceryItem)
                                        .map((v) => SelectedVariantRow(
                                              id: v.sId ?? '',
                                              title: medicalPackLabel(v),
                                              mrp: _localPricing(v)?.mrp != null
                                                  ? controller.formatMoney(
                                                      _localPricing(v)!.mrp)
                                                  : null,
                                              sellingPrice: _localPricing(v)
                                                          ?.sellingPrice !=
                                                      null
                                                  ? controller.formatMoney(
                                                      _localPricing(v)!
                                                          .sellingPrice)
                                                  : null,
                                            ))
                                        .toList(),
                                    onEdit: (id) {
                                      final v = _variantById(groceryItem, id);
                                      if (v == null) return;
                                      controller.openEditVariantDialog(
                                        context: context,
                                        title: groceryItem.name ??
                                            AppStrings.medicalEditVariant.tr,
                                        variant: v,
                                      );
                                    },
                                    onRemove: (id) {
                                      final v = _variantById(groceryItem, id);
                                      if (v == null) return;
                                      controller.toggleVariantSelection(
                                          groceryItem, v);
                                    },
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (groceryItem.variants != null &&
                          groceryItem.variants!.isNotEmpty) ...[
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
                                AppStrings.medicalAddMoreVariant,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.small,
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ));
  }
}
