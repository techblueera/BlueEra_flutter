import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/update_professionals_service.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsMainScreen extends StatefulWidget {
  const ProfessionalsMainScreen({
    super.key,
  });

  @override
  State<ProfessionalsMainScreen> createState() =>
      _ProfessionalsMainScreenState();
}

class _ProfessionalsMainScreenState extends State<ProfessionalsMainScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;

  // final controller = Get.put(BusinessProfileFullController());

  @override
  void initState() {
    // apiCalling();

    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

/*
  apiCalling() async {
    try {
      if (otherServiceIDGlobal.isEmpty) {
        ResponseModel response = await OtherRepo().getBusinessProfileRepo();
        if (response.isSuccess) {
          otherServiceIDGlobal = response.response?.data['data']['_id'];
          if (otherServiceIDGlobal.isNotEmpty) {
            await setOtherServiceID(otherServiceIDGlobal);
          } else {
            await setOtherServiceID("");
          }
        }
      }
      await getOtherServiceID();
      setState(() {
        controller.hasProfile.value = otherServiceIDGlobal.isNotEmpty;
      });
    } on Exception {
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
        child: /*controller.hasProfile.value
                ? */Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.secondaryTextColor,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 2,
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
              const TextStyle(fontWeight: FontWeight.w400),
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
                    UpdateProfessionalsServicesScreen(),
                    const Center(
                        child: CustomText(AppStrings.comingSoon)),
                  ],
                ))
          ],
        )
        /*  : OtherServiceNotCreateScreen(
                    controller: controller,
                  )*/,
      ),
      /*  body: Obx(() {
          return SafeArea(
            child: *//*controller.hasProfile.value
                ? *//*Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: AppColors.secondaryTextColor,
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 2,
                        tabAlignment: TabAlignment.fill,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w400),
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
                          UpdateProfessionalsServicesScreen(),
                          const Center(
                              child: CustomText(AppStrings.comingSoon)),
                        ],
                      ))
                    ],
                  )
              *//*  : OtherServiceNotCreateScreen(
                    controller: controller,
                  )*//*,
          );
        })*/);
  }
}
