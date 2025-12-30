import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/view/school_home_screen.dart';
import 'package:BlueEra/features/me/school/view/school_statics_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_school_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../../../widgets/local_assets.dart';

class SchoolMain extends StatefulWidget {
  const SchoolMain({
    super.key,
  });

  @override
  State<SchoolMain> createState() => _SchoolMainState();
}

class _SchoolMainState extends State<SchoolMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.size12,
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.mainTextColor,
                unselectedLabelColor:AppColors.secondaryTextColor,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 4,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: AppConstants.OpenSans),
                tabs: [
                  Tab(text: "Home"),
                  Tab(text: "Update"),
                  Tab(text: "Statics"),
                ],
              ),
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                children: [
                  SchoolHomeScreen(),
                  SchoolUpdateScreen(),
                  SchoolStaticsScreen(),
                ],
              ))
            ],
          ),
        ));
  }
}
