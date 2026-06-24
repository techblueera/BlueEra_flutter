import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/school/view/v2/school_home_screen_v2.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolMain extends StatefulWidget {
  const SchoolMain({
    super.key,
  });

  @override
  State<SchoolMain> createState() => _SchoolMainState();
}

class _SchoolMainState extends State<SchoolMain> with RouteAware {
  final schoolAboutUsController = Get.put(SchoolAboutUsController());
  final controller = Get.put(SchoolController());

  @override
  void initState() {
    apiCalling();
    super.initState();
  }

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
    } on Exception {
      // TODO
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
            child: SchoolHomeScreenV2()/*NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: CommonBackAppBar(
                        showElevation: 0,
                        isDrawerMenu: true,
                        isLeading: false,
                        isMore: true,
                        isProfile: false,
                        isNotification: !isGuestUser(),
                        bellIconNotEmpty: true,
                        isGuestLogout: isGuestUser(),
                        onNotificationTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteHelper.getNotificationScreenRoute(),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: SizeConfig.size12),
                  ),
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    primary: false,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 0,
                    collapsedHeight: 0,
                    expandedHeight: 0,
                    backgroundColor: AppColors.white,
                    surfaceTintColor: AppColors.white,
                    bottom: TabBar(
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
                        Tab(text: AppStrings.home.tr),
                        // Tab(text: AppStrings.update.tr),
                        Tab(text: AppStrings.statistics.tr),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    SchoolHomeScreen(),
                    SchoolStaticsScreen(),
                  ],
                ),
              ),*/
          ));
  }
}
