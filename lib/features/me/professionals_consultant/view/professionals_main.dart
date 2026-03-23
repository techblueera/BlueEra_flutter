import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_service_not_create_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_home_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/update_professionals_service.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/profile_avatar_widget.dart';
import 'package:BlueEra/widgets/webview_common.dart';
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
    with TickerProviderStateMixin, RouteAware {
  final controller = Get.put(AiProfessionalsController());
  TabController? _tabController;
  bool _lastHasWebsite = false;

  @override
  void initState() {
    super.initState();
    controller.professionalsFullDetailsController();
    _lastHasWebsite = _hasWebsite;
    _tabController = TabController(
      length: _lastHasWebsite ? 3 : 2,
      vsync: this,
    );
  }

  bool get _hasWebsite {
    final url = controller.getProfessionalServiceRes?.value.data?.contact
            ?.website ??
        '';
    return url.isNotEmpty;
  }

  String get _websiteUrl =>
      controller.getProfessionalServiceRes?.value.data?.contact?.website ?? '';

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
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (!controller.hasProfile.value) {
          return SafeArea(
            child: ProfessionalServiceNotCreateScreen(
              controller: controller,
            ),
          );
        }

        // Access reactive data to trigger rebuild
        controller.getProfessionalServiceRes?.value;
        _rebuildTabsIfNeeded();

        final hasWebsite = _lastHasWebsite;
        final tabCtrl = _tabController;
        if (tabCtrl == null) return const SizedBox.shrink();

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: ProfileAvatarWidget(),
              ),
              const SizedBox(width: 8),
              SizedBox(height: SizeConfig.size8),
              TabBar(
                controller: tabCtrl,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.secondaryTextColor,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w400),
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
                    ProfessionalsHomeScreen(),
                    if (hasWebsite)
                      CommonWebView(
                        urlLink: _websiteUrl,
                        urlTitle: '',
                        hideAppBar: true,
                      ),
                    ComingSoon(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
