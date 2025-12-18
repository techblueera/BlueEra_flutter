import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_category_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_category_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_super_category_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const GroceryScreen({super.key, this.fromBottomNavBar});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController searchController = TextEditingController();
  final List<Tab> _tabs = [
    Tab(text: AppStrings.myStore.tr),
    Tab(text: AppStrings.statistics.tr),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(kToolbarHeight + 50),
      //   child: CommonBackAppBar(
      //     isLeading: !(widget.fromBottomNavBar??false),
      //     controller: searchController,
      //     searchHintText: AppStrings.searchHintText,
      //     onClearCallback: () => searchController.clear(),
      //     isSearch: true,
      //     buildCustomWidget: ()=> Padding(
      //       padding: EdgeInsets.only(
      //           right: SizeConfig.paddingL,
      //           bottom: SizeConfig.paddingXSL
      //       ),
      //       child: InkWell(
      //         onTap:()=> Get.toNamed(
      //             RouteHelper.getGroceryCategoryScreenRoute(),
      //             arguments: {ApiKeys.argOwnGrocery: true}
      //         ),
      //         child: Container(
      //           height: SizeConfig.size40,
      //           width: SizeConfig.size40,
      //           decoration: BoxDecoration(
      //             borderRadius: BorderRadius.circular(SizeConfig.size8),
      //             color: AppColors.primaryColor
      //           ),
      //           alignment: Alignment.center,
      //           padding: EdgeInsets.all(6.0),
      //           child: LocalAssets(imagePath: AppIconAssets.add),
      //         ),
      //       ),
      //     ),
      //     bottomWidget: TabBar(
      //       controller: _tabController,
      //       labelColor: AppColors.primaryColor,
      //       unselectedLabelColor: Colors.grey[600],
      //       indicatorColor: Colors.blue,
      //       indicatorWeight: 2,
      //       labelStyle: TextStyle(fontWeight: FontWeight.w600),
      //       tabs: _tabs,
      //     ),
      //   ),
      // ),
      body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  floating: true,   // appear on scroll up
                  snap: true,       // instantly snap down
                  pinned: false,    // don't keep the header fixed
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                    child: _buildHeader(context), // your header row
                  ),
                  expandedHeight: SizeConfig.size70,
                ),

                SliverPersistentHeader(
                  pinned: true,   // TabBar should always stay visible
                  delegate: TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Colors.blue,
                      indicatorWeight: 2,
                      labelStyle: TextStyle(fontWeight: FontWeight.w600),
                      tabs: _tabs,
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                MyGrocerySuperCategoryScreen(),
                Center(child: CustomText(AppStrings.comingSoon)),
                Center(child: CustomText(AppStrings.comingSoon))
              ]
            ),
          )
      ),
    );
  }

  Widget? _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (!(widget.fromBottomNavBar??false))
          IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: LocalAssets(
                imagePath: AppIconAssets.back_arrow,
                height: SizeConfig.paddingL,
                width: SizeConfig.paddingL,
                imgColor:  Colors.black,
              )),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left:
                (!(widget.fromBottomNavBar??false)) ? 0.0 : SizeConfig.size15),
            child: CommonSearchBar(
                controller: searchController,
                onClearCallback: ()=> searchController.clear(),
                hintText: AppStrings.searchHintText),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.paddingXSL,
          ),
          child: InkWell(
            onTap:() {

            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: SizeConfig.size40,
                  width: SizeConfig.size40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SizeConfig.size8),
                      color: AppColors.white,
                      border: Border.all(
                        color: AppColors.greyE5
                      ),
                     boxShadow: [AppShadows.textFieldShadow]
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(6.0),
                  child: LocalAssets(
                      imagePath: AppIconAssets.riderIcon,
                      imgColor: AppColors.black,
                  ),
                ),
                Positioned(
                   top: -(SizeConfig.size6),
                   right: -(SizeConfig.size6),
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 3.0,
                            offset: Offset(0, 1.5)
                          )
                      ]
                    ),
                    child: LocalAssets(
                        imagePath: AppIconAssets.add,
                        imgColor: AppColors.secondaryTextColor,
                      width: SizeConfig.size12,
                      height: SizeConfig.size12,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.paddingXSL,
              right: SizeConfig.paddingL
          ),
          child: InkWell(
            onTap:()=> Get.toNamed(
               RouteHelper.getGrocerySuperCategoryScreenRoute(),
               // arguments: {ApiKeys.argOwnGrocery: true}
            ),
            // onTap:()=> Get.toNamed(
            //     RouteHelper.getGroceryCategoryScreenRoute(),
            //     arguments: {ApiKeys.argOwnGrocery: true}
            // ),
            child: Container(
              height: SizeConfig.size40,
              width: SizeConfig.size40,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                  color: AppColors.primaryColor
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.all(6.0),
              child: LocalAssets(imagePath: AppIconAssets.add),
            ),
          ),
        ),
      ],
    );
  }
}
