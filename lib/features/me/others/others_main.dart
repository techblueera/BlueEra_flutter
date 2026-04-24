import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/business/widgets/empty_website_tab.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
import 'package:BlueEra/features/me/others/view/business_profile_full_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OthersMain extends StatefulWidget {
  const OthersMain({super.key});

  @override
  State<OthersMain> createState() => _OthersMainState();
}

class _OthersMainState extends State<OthersMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  final controller = Get.put(BusinessProfileFullController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    MeTabRegistry.register(_tabController);
    _apiCalling();
  }

  Future<void> _apiCalling() async {
    await controller.getBusinessProfileFull();
  }

  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return BusinessProfileHeaderView(
                  details: details,
                  controller: viewBusinessDetailsController,
                );
              }),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final details = viewBusinessDetailsController
                    .businessProfileDetails.value?.data;
                return BusinessStats(details: details);
              }),
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
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.secondaryTextColor,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Home'),
                  Tab(text: 'Website'),
                  Tab(text: 'Statistics'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              BusinessProfileFullScreen(),
              const WebsiteTab(),
              const SubscriptionStatusView(),
            ],
          ),
        ),
      ),
    );
  }
}
