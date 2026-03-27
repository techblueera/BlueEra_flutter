import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class FinancialSectors extends StatelessWidget {
  const FinancialSectors({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            child: titleWidget(AppStrings.financialSectors),
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:18.0),
            child: SizedBox(
              height: SizeConfig.size124,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                primary: false,
                itemCount: financeCategories.length,
                scrollDirection: Axis.horizontal,
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var categoryItem = financeCategories[index];
                  return InkWell(
                    onTap: () {
                      commonSnackBar(message: "Coming Soon...");
                    },
                    child: Container(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      margin: EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        // color: AppColors.white,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xffE7F3FF),          // Ending color (adjust to your preference)

                            AppColors.white,           // Starting color
                          ],
                          stops: [0.0, 1.0],           // Optional: defines where each color sits
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [AppShadows.textFieldShadow],
                        border: Border.all(color:Color(0xffDDE2EE), width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          LocalAssets(
                            imagePath: categoryItem.icon ?? '',
                            height: SizeConfig.size60,
                            width: SizeConfig.size80,
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
                  // return CommonServiceCard(
                  //   service: categoryItem,
                  //   getName: (item) => item.name,
                  //   getIcon: (item) => item.icon ?? '',
                  //   iconHeight: SizeConfig.size60,
                  //   margin: EdgeInsets.only(right: 6),
                  //   onTap: (item) {
                  //     commonSnackBar(message: "Coming Soon...");
                  //   },
                  // );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
