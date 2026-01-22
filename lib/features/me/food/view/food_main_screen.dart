import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/view/food_category_screen.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:BlueEra/features/me/school/view/school_statics_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/school_not_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodMainScreen extends StatefulWidget {
  const FoodMainScreen({
    super.key,
  });

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  // final controller = Get.put(SchoolController());

  @override
  void initState() {
    // apiCalling();
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

/*
  apiCalling() async {
    try {
      if (schoolIDGlobal.isEmpty) {
        ResponseModel response = await SchoolRepo().getSchoolByUserIDRepo();
        if (response.isSuccess) {
          String? schoolID = response.response?.data['data'][0]['_id'];
          if (schoolID != null && schoolID.isNotEmpty) {
            await setSchoolID(schoolID);
          } else {
            await setSchoolID("");
          }
        }
      }
      await getSchoolID();
      setState(() {
        // Check if global ID was successfully populated
        controller.hasSchool.value = schoolIDGlobal.isNotEmpty;
      });
      await schoolAboutUsController.getSchoolByIdController();
    } on Exception catch (e) {
      // TODO
    }
  }
*/

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
            child:/* controller.hasSchool.value
                ? */Column(
              children: [
                SizedBox(
                  height: SizeConfig.size12,
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.mainTextColor,
                  unselectedLabelColor: AppColors.secondaryTextColor,
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
                        ComingSoon(),
                        FoodCategoryMenuScreen(),
                        ComingSoon(),
                      ],
                    ))
              ],
            )
          /*  : SchoolNotCreateScreen(controller: controller),*/
        ));
  }
}
