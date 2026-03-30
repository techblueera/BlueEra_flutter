import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/features/me/social/controller/social_home_controller.dart';
import 'package:BlueEra/features/me/social/view/social_home_screen.dart';
import 'package:BlueEra/widgets/profile_avatar_widget.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialMainScreen extends StatefulWidget {
  const SocialMainScreen({
    super.key,
  });

  @override
  State<SocialMainScreen> createState() => _SocialMainScreenState();
}

class _SocialMainScreenState extends State<SocialMainScreen>
    with TickerProviderStateMixin, RouteAware {
  final _ctrl = Get.put(SocialHomeController());
  TabController? _tabController;
  bool _lastHasWebsite = false;

  @override
  void initState() {
    super.initState();
    _lastHasWebsite = _hasWebsite;
    _tabController = TabController(
      length: _lastHasWebsite ? 3 : 2,
      vsync: this,
    );
  }

  bool get _hasWebsite =>
      (_ctrl.profile.value?.data?.contact?.websiteUrl ?? '').isNotEmpty;

  String get _websiteUrl =>
      _ctrl.profile.value?.data?.contact?.websiteUrl ?? '';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          _ctrl.profile.value;
          _rebuildTabsIfNeeded();

          final hasWebsite = _lastHasWebsite;
          final tabCtrl = _tabController;
          if (tabCtrl == null) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
              const Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: ProfileAvatarWidget(),
              ),
              const SizedBox(width: 8),
              // --- Profile Avatar + Tab Bar ---
              Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.size8, left: 12, right: 12),
                child: Row(
                  children: [

                    // Tab Bar
                    Expanded(
                      child: TabBar(
                        controller: tabCtrl,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor:
                            AppColors.secondaryTextColor,
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 4,
                        tabAlignment: TabAlignment.fill,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(text: AppStrings.home.tr),
                          if (hasWebsite)
                            Tab(text: AppStrings.website.tr),
                          Tab(text: AppStrings.statistics.tr),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: tabCtrl,
                  children: [
                    SocialHomeScreen(),
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
          );
        }),
      ),
    );
  }
}
