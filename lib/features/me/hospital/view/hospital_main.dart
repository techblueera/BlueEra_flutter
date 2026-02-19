import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_home_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_update_screen.dart';
import 'package:BlueEra/features/me/hospital/view/no_hospital_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:get/get.dart';

class HospitalMain extends StatefulWidget {
  const HospitalMain({
    super.key,
  });

  @override
  State<HospitalMain> createState() => _HospitalMainState();
}

class _HospitalMainState extends State<HospitalMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final hospitalServiceAiController =
      getOrPut(() => HospitalServiceAiController());

  @override
  void initState() {
    hospitalServiceAiController.getHospitalFullDetailsController();
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
        body: Obx(() {
          return SafeArea(
            child: hospitalServiceAiController.hasHospitalCreated.value
                ? Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 4,
                        tabAlignment: TabAlignment.fill,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
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
                          HospitalHomeScreen(),
                          HospitalUpdateScreen(),
                          ComingSoon(),
                        ],
                      ))
                    ],
                  )
                : NoHospitalCreateScreen(),
          );
        }));
  }
}
