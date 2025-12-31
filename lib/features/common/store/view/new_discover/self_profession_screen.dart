import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/store/controller/self_profession_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfProfessionScreen extends StatefulWidget {
  final List<IndividualProfileCategory> selfEmployedCategories;
  final IndividualProfileCategory selectedCategory;

  const SelfProfessionScreen({
    super.key,
    required this.selfEmployedCategories,
    required this.selectedCategory});

  @override
  State<SelfProfessionScreen> createState() => _SelfProfessionScreenState();
}

class _SelfProfessionScreenState extends State<SelfProfessionScreen> {
  late List<IndividualProfileCategory> selfEmployedCategories;
  final controller = getOrPut(() => SelfProfessionController());


  initState(){
    super.initState();
    selfEmployedCategories = widget.selfEmployedCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Column(
          children: [

            SizedBox(
              height: SizeConfig.paddingM,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8),
              child: InkWell(
                onTap: () {

                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 1.2),
                      boxShadow: [AppShadows.textFieldShadow]),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.franchiseIcon,
                        height: SizeConfig.size30,
                        width: SizeConfig.size30,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomText(
                          AppStrings.bookViaBlueEraPartner,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(
              height: SizeConfig.paddingXSL,
            ),

            Expanded(
              child: Row(
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(
                      child: rightContent()
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    return Container(
      width: 94,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: selfEmployedCategories.length,
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          var item = selfEmployedCategories[index];
          return Obx(()=> _categoryItem(
            item.icon,
            item.name,
            selected: controller.selectedSelfProfessionData.value.slugId
                == item.slugId,
            onTap: () {
              controller.selectedSelfProfessionData.value = item;
              controller.selectedTabIndex.value = 0;
              // log('new selection ${controller.selectedGroceryData.value}');
              //
              // /// api call
              // controller.fetchBoth();

            },
          ));
        },
      ),
    );
  }

  Widget _categoryItem(
      String icon,
      String label,
      {bool selected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 11 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.skyBlueE4,
                AppColors.skyBlueE4.withValues(alpha: 0.3),
              ],
            ),
            border: selected
                ? const Border(
                left: BorderSide(
                    color: AppColors.primaryColor,
                    width: 3,
                    style: BorderStyle.solid))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? null : AppColors.skyBlueE4),
                  padding: EdgeInsets.all(selected ? 0 : 6),
                  child: LocalAssets(
                    imagePath: icon,
                    // boxFix: BoxFit.cover,
                    height: 40,
                    width: 40,
                  )),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.black : AppColors.grayText,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget rightContent() {
    return Obx(()=> Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HorizontalTabSelector<CategoryFilter>(
            tabs: controller.filters,
            selectedIndex: controller.filters.indexOf(controller.selectedFilter.value),
            horizontalMargin: 0.0,
            onTabSelected: (index, _) {
              final selectedEnum = controller.filters[index];

              if (controller.filters == selectedEnum) return;

              controller.selectedFilter.value = selectedEnum;
              // controller.callApi();
            },
            labelBuilder: (r) => r.label,
            unSelectedBackgroundColor: AppColors.white,
          ),

          SizedBox(
            height: SizeConfig.size5,
          ),

          Expanded(
            child: ListView.builder(
                itemCount: 10,
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                itemBuilder: (context, index){
                  return CustomFormCard(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      margin: EdgeInsets.only(bottom: SizeConfig.size10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  // Your navigation logic
                                },
                                child: CachedAvatarWidget(
                                  imageUrl: 'https://picsum.photos/200',
                                  size: SizeConfig.size40,
                                  borderColor: Colors.white,
                                  borderRadius: SizeConfig.size20,
                                ),
                              ),
                              SizedBox(
                                width: SizeConfig.size6,
                              ),
                              Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CustomText(
                                          'Ramesh Kumar Shaw',
                                          fontSize: SizeConfig.small,
                                          color: AppColors.mainTextColor,
                                          fontWeight: FontWeight.w600
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size6,
                                      ),
                                      CommonRatingRow(
                                        rating: 4.8,
                                        reviews: 20,
                                        distance: '2.4KM',
                                      )
                                    ],
                                  )
                              ),
                              Icon(
                                Icons.more_vert,
                                color: AppColors.black,
                              )
                            ],
                          ),

                          SizedBox(
                            height: SizeConfig.size6,
                          ),

                          CustomText(
                              'Screen Replacernent, Battery Replacement, Water Damage Repair, Software Troub....',
                              fontSize: SizeConfig.extraSmall,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400
                          ),

                          SizedBox(
                            height: SizeConfig.size8,
                          ),

                          // if(serviceData.timings?.isNotEmpty ?? false)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                CustomText(
                                  "${AppStrings.open.tr} :",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.green00,

                                ),
                                CustomText(
                                  // "${serviceData.timings?[0].start}",
                                  "9:00 AM",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.secondaryTextColor,
                                  maxLines: 1,
                                ),
                                CustomText(
                                  ' | ',
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                CustomText(
                                  "${AppStrings.close} :",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.redB4,
                                  maxLines: 1,
                                ),
                                CustomText(
                                  // "${serviceData.timings?[0].end}",
                                  "9:00 PM",
                                  fontSize: SizeConfig.small,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.grayText,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: SizeConfig.size8,
                          ),

                          CustomText(
                            "₹1999-2999",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),

                        ],
                      )
                  );
                }
            ),
          )

        ],
      ),
    ));
  }

}
