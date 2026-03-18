import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_product_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_service_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class HomeMadeProductWidget extends StatelessWidget {
  const HomeMadeProductWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(AppStrings.homemadeProducts),
          SizedBox(height: SizeConfig.paddingXSL),
          MasonryGridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            itemCount: homeMadeItemsCategories.take(2).length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var categoryItem = homeMadeItemsCategories[index];
              return InkWell(
                onTap: () {
                  if (categoryItem.slugId == SERVICE) {
                    Get.to(() => HomeServiceScreen());
                  }else if (categoryItem.slugId == PRODUCT) {
                    Get.to(() => HomeMadeProductScreen());
                  }
                },
                child: CommonCardWidget(
                  bgColor: Colors.white,
                  borderColorColor:Color(0xffDDE2EE) ,
                  cardMargin: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LocalAssets(
                          imagePath: categoryItem.icon ?? '',
                          height: SizeConfig.size140,
                          width: double.maxFinite,
                          boxFix: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),
                      Container(
                        height: SizeConfig.size30,
                        alignment: Alignment.center,
                        child: CustomText(
                          categoryItem.name,
                          fontSize: SizeConfig.small11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
