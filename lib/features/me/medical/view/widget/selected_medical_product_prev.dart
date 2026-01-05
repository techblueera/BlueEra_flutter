import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../auth/controller/medical_model_controller.dart';
import '../../../auth/model/medical_admin_product_details.dart';

class SelectedMedicalProductPrev extends StatelessWidget {
  const SelectedMedicalProductPrev({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalModelController());

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: const CommonBackAppBar(
        // title: "Sub Category Cooking Essentials",
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.medicalProductDetails.length,
              itemBuilder: (context, index) {
                return  ProductCard(productData:controller.medicalProductDetails[index],);
              },
            ),
          ),
          /// Publish Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: CustomBtn(
              onTap: () {

              },
              title: "Publish 10 Product, 25 Varient",
            ),
          ),
        ],
      ),
    );
  }
}
class ProductCard extends StatelessWidget {
  const ProductCard({super.key,required this.productData});
  final MedicalProductDetailsModel productData;
  @override
  Widget build(BuildContext context) {
    final controller = getOrPut<MedicalModelController>(
          () => MedicalModelController(),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                // margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade300,
                              ),
                              child: Image.asset(
                                AppImageAssets.dummy_resume,
                                fit: BoxFit.contain,
                              ),
                            ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               CustomText(
                                "Pharma Franchise For OTC Product",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mainTextColor
                              ),
                              const VariantRow(),
                              const VariantRow(),
                              const VariantRow(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 2,
                left: 2,
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
              )
            ],
          ),
          SizedBox(height: SizeConfig.size10,),
          Align(
            alignment: Alignment.centerRight,
            child: Row(mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.add, size: 22
                ,color: AppColors.primaryColor,
                ),
                SizedBox(width: 6,),
                const CustomText(
                    "Add More Varient",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,fontSize: 12
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class VariantRow extends StatelessWidget {
  const VariantRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.blackLite
              )
            ),
          ),
          SizedBox(width: 4,),
          const CustomText(
            "100GM",
          fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor
          ),
          const SizedBox(width: 10),
          const CustomText(
            "₹1999",
              fontSize: 10,
              fontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 10),
          const CustomText(
            "Selling-₹1500",
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor
          ),
          const Spacer(),
          Icon(Icons.edit, size: 16),
        ],
      ),
    );
  }
}