import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_category_screen.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_category_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
    Tab(text: 'Grocery & Veg'),
    Tab(text: 'Stationery'),
    Tab(text: 'Business Cards')
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          isLeading: !(widget.fromBottomNavBar??false),
          controller: searchController,
          searchHintText: AppStrings.searchHintText,
          onClearCallback: () => searchController.clear(),
          isSearch: true,
          buildCustomWidget: ()=> Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.paddingL,
                bottom: SizeConfig.paddingXSL
            ),
            child: InkWell(
              onTap:()=> Get.toNamed(RouteHelper.getGroceryCategoryScreenRoute()),
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
          bottomWidget: TabBar(
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
      body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              MyGroceryCategoryScreen(),
              Center(child: CustomText(AppStrings.comingSoon)),
              Center(child: CustomText(AppStrings.comingSoon))
            ]
          )
      ),
    );
  }
}
