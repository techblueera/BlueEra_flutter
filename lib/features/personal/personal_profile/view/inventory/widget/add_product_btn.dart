import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/food_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_constant.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import '../add_food/add_food_screen.dart';

class AddProductBtn extends StatelessWidget {
  const AddProductBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.only(bottom: 10),
      offset: const Offset(-24, 36),
      color: AppColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(10)),
      onSelected: (value) async {

        if (value.toUpperCase() == "ADD PRODUCT") {
          Get.toNamed(RouteHelper.getAddProductScreenRoute());
        }else if(value.toUpperCase() == "ADD SERVICE"){
          Get.toNamed(RouteHelper.getAddServicesScreenRoute());
        }else if(value.toUpperCase() =="ADD FOOD"){
          Get.to(()=> FoodUploadScreen());
          // Get.to(()=> FoodPage());
        }
      },
      icon: Container(
        height: SizeConfig.size30,
        margin: EdgeInsets.only(right: SizeConfig.size10, left:  SizeConfig.size10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryColor)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'Add Product',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
             Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryColor,
              size: 16,
            ),

          ],
        ),
      ),
      itemBuilder: (context) =>
          popupMenuInventoryItems(),
    );
  }
}
