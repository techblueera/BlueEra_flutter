import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/medical_model_controller.dart';
import '../../../auth/model/medical_admin_product_details.dart';

class AllMedicalProductList extends StatelessWidget {
  const AllMedicalProductList({super.key, required this.productList});

  final List<MedicalProductDetailsModel> productList;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalModelController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 2;
        final crossSpacing = 10.0;
        final mainSpacing = 10.0;

        final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
        final itemWidth =
            (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

        final approximateItemHeight = SizeConfig.size240;

        final childAspectRatio = itemWidth / approximateItemHeight;

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: productList.length,
          itemBuilder: (context, index) {
            if (index >= productList.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final productData = productList[index];

            return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.white,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Product Image
                        SizedBox(
                          height: SizeConfig.size170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomImageSlideshow(
                              isLoading: false,
                              width: double.infinity,
                              height: SizeConfig.size170,
                              imagePaths: productData.images ?? [],
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.size5),

                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              CustomText(
                                productData.name,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.medium,
                                color: AppColors.mainTextColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: SizeConfig.size5),

                              // Price Row
                              // if (variants.isNotEmpty)
                              Row(
                                children: [
                                  CustomText(
                                    '₹${productData.variants?[0].pricing?[0].mrp}',
                                    fontWeight: FontWeight.w700,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.primaryColor,
                                    fontFamily: AppConstants.OpenSans,
                                  ),
                                  SizedBox(width: SizeConfig.size6),
                                  CustomText(
                                    ' ₹${productData.variants?[0].pricing?[0].sellingPrice}',
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.lineThrough,
                                    fontFamily: AppConstants.OpenSans,
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.size8),
                            ],
                          ),
                        )
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          controller.toggleProduct(productData);
                        },
                        child: Obx(() {
                          final isSelected = controller.isSelected(productData);

                          return Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.black.withOpacity(0.4),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              height: 16,
                              width: 16,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white),
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : null),
                              child: isSelected
                                  ? Center(
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ));
          },
        );
      },
    );
  }
}
