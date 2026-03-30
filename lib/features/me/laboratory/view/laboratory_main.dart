import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_full_details_screen.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/widgets/webview_common.dart';
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

  String get _websiteUrl {
    return _labDetailsController.details.value?.contactInfo?.websiteUrl ?? '';
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
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Obx(() {
          labServiceAiController.hasLabCreated.value;

          final hasWebsite = _lastHasWebsite;
          final tabCtrl = _tabController;
          if (tabCtrl == null) return const SizedBox.shrink();

          return SafeArea(
            child:Column(
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
                    if (hasWebsite)
                      Tab(text: AppStrings.website.tr),
                    Tab(text: AppStrings.statistics.tr),
                  ],
                ),
                Expanded(
                    child: TabBarView(
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
                    ))
              ],
            ),
          );
        }));
  }
}
