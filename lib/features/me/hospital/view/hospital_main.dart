import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_home_screen.dart';
import 'package:BlueEra/features/me/hospital/view/no_hospital_create_screen.dart';
import 'package:BlueEra/widgets/webview_common.dart';
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
    with TickerProviderStateMixin, RouteAware {
  TabController? _tabController;
  final hospitalServiceAiController =
      getOrPut(() => HospitalServiceAiController());
  bool _lastHasWebsite = false;
  Worker? _dataWorker;

  @override
  void initState() {
    super.initState();

    _lastHasWebsite = _hasWebsite;
    _tabController = TabController(
      length: _lastHasWebsite ? 3 : 2,
      vsync: this,
    );

    // Listen for hospital data changes to rebuild tabs when website status changes
    _dataWorker =
        ever(hospitalServiceAiController.hospitalDataResModel!, (_) {
      _rebuildTabsIfNeeded();
    });

    apiCalling();
  }

  bool get _hasWebsite {
    final contacts =
        hospitalServiceAiController.hospitalDataResModel?.value.data?.contacts;
    if (contacts == null || contacts.isEmpty) return false;
    final website = contacts.first.branch?.website ?? '';
    return website.isNotEmpty;
  }

  String get _websiteUrl {
    final contacts =
        hospitalServiceAiController.hospitalDataResModel?.value.data?.contacts;
    if (contacts == null || contacts.isEmpty) return '';
    return contacts.first.branch?.website ?? '';
  }

  void _rebuildTabsIfNeeded() {
    final current = _hasWebsite;
    if (current != _lastHasWebsite) {
      _lastHasWebsite = current;
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      final newLength = current ? 3 : 2;
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: oldIndex.clamp(0, newLength - 1),
      );
      if (mounted) setState(() {});
    }
  }

  apiCalling() async {
    try {
      await hospitalServiceAiController.getHospitalFullDetailsController();
      setState(() {});
    } on Exception {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _dataWorker?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Obx(() {
          hospitalServiceAiController.hasHospitalCreated.value;

          final hasWebsite = _lastHasWebsite;
          final tabCtrl = _tabController;
          if (tabCtrl == null) return const SizedBox.shrink();

          return SafeArea(
            child: hospitalServiceAiController.hasHospitalCreated.value
                ? Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      TabBar(
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
                          if (hasWebsite) Tab(text: AppStrings.website.tr),
                          Tab(text: AppStrings.statistics.tr),
                        ],
                      ),
                      Expanded(
                          child: TabBarView(
                        controller: tabCtrl,
                        children: [
                          HospitalHomeScreen(),
                          if (hasWebsite)
                            CommonWebView(
                              urlLink: _websiteUrl,
                              urlTitle: '',
                              hideAppBar: true,
                            ),
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
