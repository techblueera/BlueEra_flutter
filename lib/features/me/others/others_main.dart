import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/view/business_profile_full_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OthersMain extends StatefulWidget {
  const OthersMain({super.key});

  @override
  State<OthersMain> createState() => _OthersMainState();
}

class _OthersMainState extends State<OthersMain>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final controller = Get.put(BusinessProfileFullController());

  bool _hasWebsite = false;

  String get _websiteUrl {
    final contacts = controller.businessProfile.value?.contactUs;
    if (contacts == null) return '';
    for (final c in contacts) {
      final url = c.branch?.website ?? '';
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiCalling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ever(controller.businessProfile, (_) {
        if (!mounted) return;
        final newHasWebsite = _websiteUrl.isNotEmpty;
        if (newHasWebsite != _hasWebsite) {
          _hasWebsite = newHasWebsite;
          final currentIndex = _tabController.index;
          _tabController.dispose();
          _tabController = TabController(
            length: _hasWebsite ? 3 : 2,
            vsync: this,
            initialIndex: currentIndex.clamp(0, _hasWebsite ? 2 : 1),
          );
          setState(() {});
        }
      });
    });
  }

  Future<void> _apiCalling() async {
    await controller.getBusinessProfileFull();
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
      body: SafeArea(
        child: Column(
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
                const Tab(text: 'Others'),
                if (_hasWebsite) const Tab(text: 'Website'),
                const Tab(text: 'Statistics'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BusinessProfileFullScreen(),
                  if (_hasWebsite)
                    CommonWebView(
                      urlLink: _websiteUrl,
                      urlTitle: '',
                      hideAppBar: true,
                    ),
                  const Center(child: CustomText(AppStrings.comingSoon)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
