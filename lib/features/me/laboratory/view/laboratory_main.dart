import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/lab_home_screen_v2.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaboratoryMain extends StatefulWidget {
  const LaboratoryMain({
    super.key,
  });

  @override
  State<LaboratoryMain> createState() => _LaboratoryMainState();
}

class _LaboratoryMainState extends State<LaboratoryMain>
    with TickerProviderStateMixin, RouteAware {
  TabController? _tabController;
  final labServiceAiController = getOrPut(() => LabServiceAiController());
  late final LabFullDetailsController _labDetailsController;
  bool _lastHasWebsite = false;
  Worker? _detailsWorker;

  @override
  void initState() {
    super.initState();

    // Register LabFullDetailsController early so we can listen to it
    if (!Get.isRegistered<LabFullDetailsController>()) {
      _labDetailsController =
          Get.put(LabFullDetailsController(), permanent: true);
    } else {
      _labDetailsController = Get.find<LabFullDetailsController>();
    }

    _lastHasWebsite = _hasWebsite;
    _tabController = TabController(
      length: _lastHasWebsite ? 3 : 2,
      vsync: this,
    );
    MeTabRegistry.register(_tabController!);

    // Listen for details changes to rebuild tabs when website status changes
    _detailsWorker = ever(_labDetailsController.details, (_) {
      _rebuildTabsIfNeeded();
    });

    apiCalling();
  }

  bool get _hasWebsite {
    return (_labDetailsController.details.value?.contactInfo?.websiteUrl ?? '')
        .isNotEmpty;
  }


  void _rebuildTabsIfNeeded() {
    final current = _hasWebsite;
    if (current != _lastHasWebsite) {
      _lastHasWebsite = current;
      final oldIndex = _tabController?.index ?? 0;
      if (_tabController != null) MeTabRegistry.unregister(_tabController!);
      _tabController?.dispose();
      final newLength = current ? 3 : 2;
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: oldIndex.clamp(0, newLength - 1),
      );
      MeTabRegistry.register(_tabController!);
      if (mounted) setState(() {});
    }
  }

  apiCalling() async {
    try {
      if (labIDGlobal.isEmpty) {
        ResponseModel response =
            await LabServiceRepo().getLabFullDetailsByIdRepo();
        if (response.isSuccess) {
          labIDGlobal = response.response?.data['data']['profile']['_id'];
          if (labIDGlobal.isNotEmpty) {
            await setLabID(labIDGlobal);
          } else {
            labIDGlobal = "";
            await setLabID("");
          }
        } else {
          labIDGlobal = "";
          await setLabID("");
        }
      }
      await getLabID();
      labServiceAiController.hasLabCreated.value = labIDGlobal.isNotEmpty;
      setState(() {});
    } on Exception {
      // TODO
    }
  }

  @override
  void dispose() {
    _detailsWorker?.dispose();
    if (_tabController != null) MeTabRegistry.unregister(_tabController!);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Obx(() {
          labServiceAiController.hasLabCreated.value;

          final tabCtrl = _tabController;
          if (tabCtrl == null) return const SizedBox.shrink();

          return SafeArea(
            child: BottomNavHideOnScroll(
              child: LabHomeScreenV2()/*NestedScrollView(
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
                      controller: tabCtrl,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppColors.primaryColor,
                      indicatorWeight: 4,
                      tabAlignment: TabAlignment.fill,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle:
                      const TextStyle(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(text: AppStrings.home.tr),
                        if (hasWebsite)
                          Tab(text: AppStrings.website.tr),
                        Tab(text: AppStrings.statistics.tr),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: tabCtrl,
                  children: [
                    LabFullDetailsScreen(),
                    if (hasWebsite)
                      CommonWebView(
                        urlLink: _websiteUrl,
                        urlTitle: '',
                        hideAppBar: true,
                      ),
                    ComingSoon(),
                  ],
                ),
              )*/,
            ),
          );
        }));
  }
}
