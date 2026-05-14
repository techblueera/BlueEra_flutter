import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/lab_home_screen_v2.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaboratoryMain extends StatefulWidget {
  const LaboratoryMain({super.key});

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

    // Register LabFullDetailsController early so we can listen to it.
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

    // Rebuild the TabController whenever the website-status flips.
    _detailsWorker =
        ever(_labDetailsController.details, (_) => _rebuildTabsIfNeeded());

    _bootstrapLabId();
  }

  bool get _hasWebsite =>
      (_labDetailsController.details.value?.contactInfo?.websiteUrl ?? '')
          .isNotEmpty;

  void _rebuildTabsIfNeeded() {
    final current = _hasWebsite;
    if (current == _lastHasWebsite) return;

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

  Future<void> _bootstrapLabId() async {
    try {
      if (labIDGlobal.isEmpty) {
        final ResponseModel response =
            await LabServiceRepo().getLabFullDetailsByIdRepo();
        if (response.isSuccess) {
          final fetched =
              response.response?.data['data']?['profile']?['_id'] ?? '';
          labIDGlobal = fetched;
          await setLabID(fetched);
        } else {
          labIDGlobal = '';
          await setLabID('');
        }
      }
      await getLabID();
      labServiceAiController.hasLabCreated.value = labIDGlobal.isNotEmpty;
      if (mounted) setState(() {});
    } on Exception {
      // Silent failure — UI falls back to "no lab created" state.
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
        // Subscribe to the creation flag so this rebuilds when it flips.
        labServiceAiController.hasLabCreated.value;
        if (_tabController == null) return const SizedBox.shrink();

        return SafeArea(
          child: BottomNavHideOnScroll(
            child: LabHomeScreenV2(),
          ),
        );
      }),
    );
  }
}
