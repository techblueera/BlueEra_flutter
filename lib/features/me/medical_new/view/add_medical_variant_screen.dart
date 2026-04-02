import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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
                  title:
                      'Publish ${controller.selectedMedicalProducts.length} Products, '
                      '${controller.selectedProductVariants.length} Variants',
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
                                  /// --- Product Title ---
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: SizeConfig.size10),
                                    child: CustomText(
                                      groceryItem.name,
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.mainTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  SizedBox(height: SizeConfig.size8),

                                  /// --- Variant Column ---
                                  GetBuilder<MedicalController>(
                                    builder: (controller) {
                                      final groceryVariants =
                                          groceryItem.variants ?? [];

                                      return Column(
                                        children: List.generate(
                                            groceryVariants.length,
                                            (variantIndex) {
                                          final v =
                                              groceryVariants[variantIndex];

                                          return Padding(
                                            padding: EdgeInsets.zero,
                                            // padding: EdgeInsets.only(bottom: SizeConfig.size2),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  visualDensity: VisualDensity.compact,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  value: controller
                                                      .isVariantSelected(
                                                    groceryItem.sId!,
                                                    groceryItem
                                                        .variants![variantIndex]
                                                        .sId!,
                                                  ),
                                                  onChanged: (_) {
                                                    controller.toggleVariant(
                                                      groceryItem.sId!,
                                                      groceryItem.variants![
                                                          variantIndex],
                                                    );
                                                  },
                                                  checkColor: Colors.white,
                                                  activeColor:
                                                      AppColors.primaryColor,
                                                  side: const BorderSide(
                                                    color: AppColors
                                                        .secondaryTextColor,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: CustomText(
                                                    (v.weight != null || v.unit != null)
                                                        ? '${v.weight ?? '-'} ${v.unit ?? ''}'
                                                        : 'Weight not set',
                                                    fontSize: SizeConfig.small,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.mainTextColor,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  width: 2.0,
                                                  height: SizeConfig.size16,
                                                  color: AppColors.greyLite,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: CustomText(
                                                    (v.pricing != null && v.pricing!.isNotEmpty && v.pricing![0].mrp != null)
                                                        ? '₹${v.pricing![0].mrp!.toStringAsFixed(2)}'
                                                        : 'MRP not set',
                                                    fontSize: SizeConfig.small,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.mainTextColor,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  width: 2.0,
                                                  height: SizeConfig.size16,
                                                  color: AppColors.greyLite,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: CustomText(
                                                    (v.pricing != null && v.pricing!.isNotEmpty && v.pricing![0].sellingPrice != null)
                                                        ? '₹${v.pricing![0].sellingPrice!.toStringAsFixed(2)}'
                                                        : 'Price not set',
                                                    fontSize: SizeConfig.small,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.mainTextColor,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                InkWell(
                                                  onTap: () {
                                                    controller
                                                        .openEditVariantDialog(
                                                      context: context,
                                                      title: groceryItem.name ??
                                                          'Edit Variant',
                                                      variant:
                                                          groceryItem.variants![
                                                              variantIndex],
                                                    );
                                                  },
                                                  child: LocalAssets(
                                                    imagePath:
                                                        AppIconAssets.pen_line,
                                                    imgColor:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      );
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
                                "Add More Variant",
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
