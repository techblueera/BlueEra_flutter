import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/local_assets.dart';
import '../../controller/medical_model_controller.dart';
import '../../model/medical_admin_product_details.dart';
import 'add_product_common_dialog.dart';

class SelectedMedicalProductPrev extends StatelessWidget {
  const SelectedMedicalProductPrev({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalModelController());

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              "All Variant",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Icon(Icons.close, size: 20)),
          ],
        ),

        Expanded(
          child: Obx(() {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 12),
              itemCount: controller.selectedProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  productData: controller.selectedProducts[index],);
              },
            );
          }),
        ),


        Padding(
          padding: const EdgeInsets.all(12),
          child: CustomBtn(
            bgColor: AppColors.primaryColor,
            onTap: () {

            },
            title: "Post Product",
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.productData});

  final MedicalProductDetailsModel productData;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut<MedicalModelController>(() =>
        MedicalModelController());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade300,
                    ),
                    child: Image.network(
                      productData.image ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Obx(() {
                      final isSelected = controller.isSelected(productData);
                      return GestureDetector(
                        onTap: () => controller.toggleProduct(productData),
                        child: CircleAvatar(
                          backgroundColor: AppColors.blackMite,
                          radius: 16,
                          child: Container(
                            margin: EdgeInsets.all(6),
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.white),
                            ),
                            child: isSelected
                                ? const Icon(
                                Icons.check, size: 16, color: AppColors.white)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "${productData.name}",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      "${productData.description}",
                      fontSize: 12,
                      fontWeight: FontWeight.w400,

                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// VARIANT GRID (2 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productData.variants?.length ?? 0,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.4,
            ),
            itemBuilder: (_, i) =>
                VariantBox(variant: productData.variants![i],),
          ),

          const SizedBox(height: 10),

          /// ADD MORE VARIANT
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                AddProductCommonDialog.addVariant(
                  productId: productData.id ?? '',
                  context: context,

                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: AppColors.primaryColor, size: 22),
                  SizedBox(width: 6),
                  CustomText(
                    "Add More Variant",
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class VariantBox extends StatelessWidget {
  const VariantBox({super.key, required this.variant});

  final VariantModel variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Weight - ${variant.weight} gm",
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          "Selling- ₹${variant.inventories?.first.batches?.first
                              .sellingPrice}",
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 6),
                        CustomText(
                          "₹${variant.inventories?.first.batches?.first
                              .sellingPrice}",
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ],
                    ),

                    GestureDetector(
                      onTap: () {
                        AddProductCommonDialog.addVariant(
                          productId: variant.id ?? '',
                          context: context,
                          preVariantData: variant

                        );
                      },
                      child: LocalAssets(imagePath: AppIconAssets.pen_line

                        , height: 16, width: 16,),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

