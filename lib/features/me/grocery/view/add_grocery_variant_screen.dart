import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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

                      /// --- Product Title ---
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: CustomText(
                          groceryItem.name,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: SizeConfig.size8),

                      /// --- Variant Column ---
                      Obx(() {
                        // Use the local variable that handles null with ?? []
                        final groceryVariants = groceryItem.variants ?? [];

                        return Column(
                          children: List.generate(groceryVariants.length, (variantIndex) {
                            final v = groceryVariants[variantIndex];

                            return Padding(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller.isVariantSelected(
                                      groceryItem.sId ?? '',
                                      v.sId ?? '',
                                    ),
                                    onChanged: (_) {
                                      controller.toggleVariant(
                                        groceryItem.sId ?? '',
                                        v,
                                      );
                                    },
                                    checkColor: Colors.white,
                                    activeColor: AppColors.primaryColor,
                                    side: const BorderSide(
                                      color: AppColors.secondaryTextColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  CustomText(
                                    '${v.quantity}',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    "₹${v.pricing?.isNotEmpty == true ? v.pricing![0].mrp : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    "Selling- ₹${v.pricing?.isNotEmpty == true ? v.pricing![0].sellingPrice : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      controller.openEditVariantDialog(
                                        context: context,
                                        title: groceryItem.name ?? AppStrings.groceryViewEditVariant.tr,
                                        variant: v,
                                      );
                                    },
                                    child: LocalAssets(
                                      imagePath: AppIconAssets.pen_line,
                                      imgColor: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      })

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
