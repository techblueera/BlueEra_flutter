import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_service_not_create_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_home_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/update_professionals_service.dart';
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

  final controller = Get.put(AiProfessionalsController());

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    controller.professionalsFullDetailsController();
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
          child: controller.hasProfile.value
              ? Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: AppColors.secondaryTextColor,
                      indicatorColor: AppColors.primaryColor,
                      indicatorWeight: 2,
                      tabAlignment: TabAlignment.fill,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w400),
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
                        ProfessionalsHomeScreen(),
                        UpdateProfessionalsServicesScreen(),
                        const Center(child: CustomText(AppStrings.comingSoon)),
                      ],
                    ))
                  ],
                )
              : ProfessionalServiceNotCreateScreen(
                  controller: controller,
                ),
        );
      }),

    );
  }
}
