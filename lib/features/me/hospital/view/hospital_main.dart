import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/hospital_home_screen_v2.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalMain extends StatefulWidget {
  const HospitalMain({super.key});

  @override
  State<HospitalMain> createState() => _HospitalMainState();
}

class _HospitalMainState extends State<HospitalMain>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final hospitalServiceAiController =
      getOrPut(() => HospitalServiceAiController());

  bool _hasWebsite = false;

  String get _websiteUrl =>
      hospitalServiceAiController
          .hospitalDataResModel
          ?.value
          .data
          ?.contacts
          ?.firstOrNull
          ?.branch
          ?.website ??
      '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    MeTabRegistry.register(_tabController);
    hospitalServiceAiController.getHospitalFullDetailsController();

    ever(hospitalServiceAiController.hospitalDataResModel!, (_) {
      final newHasWebsite = _websiteUrl.isNotEmpty;
      if (newHasWebsite != _hasWebsite) {
        _hasWebsite = newHasWebsite;
        final currentIndex = _tabController.index;
        MeTabRegistry.unregister(_tabController);
        _tabController.dispose();
        _tabController = TabController(
          length: _hasWebsite ? 3 : 2,
          vsync: this,
          initialIndex: currentIndex.clamp(0, _hasWebsite ? 2 : 1),
        );
        MeTabRegistry.register(_tabController);
        if (mounted) setState(() {});
      }
    });
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
      body: const HospitalHomeScreenV2(),
    );
  }
}
