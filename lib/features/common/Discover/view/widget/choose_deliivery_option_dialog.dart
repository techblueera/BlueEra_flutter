import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_rider/add_grocery_via_rider_category_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChooseDeliveryOptionDialog extends StatefulWidget {
  const ChooseDeliveryOptionDialog({super.key});

  @override
  State<ChooseDeliveryOptionDialog> createState() => _ChooseDeliveryOptionDialogState();
}

class _ChooseDeliveryOptionDialogState extends State<ChooseDeliveryOptionDialog> {
  String _selectedOptionId = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greenShade, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.chooseDeliveryOption.tr,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 10),

            // 2. Loop through the list to build options
            ...chooseDeliveryOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDeliveryOption(
                id: option['id']!,
                icon: option['icon']!,
                title: option['title']!,
                subtitle: option['subtitle']!,
              ),
            )).toList(),

            // const SizedBox(height: 10),
            //
            // // Footer (Buttons)
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: CustomBtn(
            //     onTap: _selectedOptionId.isNotEmpty
            //         ? () => Get.off(()=> ChooseDeliveryOptionsScreen(optionId: _selectedOptionId))
            //         : null,
            //     title: AppStrings.next,
            //     height: SizeConfig.size35,
            //     width: SizeConfig.size80,
            //     isValidate: _selectedOptionId.isNotEmpty,
            //   ),
            // )

          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String id,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    // bool isSelected = _selectedOptionId == id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: () {
          // setState(() {
            _selectedOptionId = id;
          // });
          if(_selectedOptionId == 'SELF'){
            navigateToGroceryStore();
            // Get.to(()=> SelfPickupStoreScreen());
          }else if(_selectedOptionId == 'RIDER'){
            Get.to(()=> AddGroceryViaRiderCategoryScreen());
            }
          // else{
          //   Get.to(()=> FranchiseHome(
          //       // onBackPressed: (){
          //       //   _selectedOptionId = 'RIDER';
          //       //   setState(() {});
          //       // }
          //   ));
          // }
          // Get.to(()=> ChooseDeliveryOptionsScreen(
          //     optionId: _selectedOptionId));
        },
        borderRadius: BorderRadius.circular(10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // color: isSelected ? AppColors.white : AppColors.whiteFE,
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              // color: isSelected ? AppColors.greenShade : AppColors.greyE5,
              // width: isSelected ? 1.5 : 1.0,
              color: AppColors.greyE5,
              width: 1.0,
            ),
            // boxShadow: isSelected ? [AppShadows.textFieldShadow] : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: LocalAssets(imagePath: icon, boxFix: BoxFit.contain),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      // color: isSelected ? AppColors.mainTextColor : AppColors.secondaryTextColor,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      subtitle,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              // if (isSelected)
              //   LocalAssets(
              //       imagePath: AppIconAssets.green_tick_icon,
              //       width: 20,
              //       height: 20,
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToGroceryStore() {
    Get.toNamed(
      RouteHelper.getGroceryStoresScreenRoute(),
    );
  }

}
