import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Home service providers near me — a flat list of nearby earn-profiles from
/// `earn-service/earn-profiles?profileType=homeService`. Mirrors the home made
/// food screen.
class HomeServiceDiscoverScreen extends StatefulWidget {
  const HomeServiceDiscoverScreen({super.key});

  @override
  State<HomeServiceDiscoverScreen> createState() => _HomeServiceDiscoverScreenState();
}

class _HomeServiceDiscoverScreenState extends State<HomeServiceDiscoverScreen> {
  static const String _profileType = 'homeService';

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/young-handyman-installing-kitchen-cabinet_155003-37938.jpg?w=1380",
    "https://img.freepik.com/free-photo/medium-shot-woman-cleaning-home_23-2150454566.jpg?w=1380",
    "https://img.freepik.com/free-photo/plumber-man-fixing-kitchen-sink_53876-27.jpg?w=1380",
  ];

  @override
  void dispose() {
    deleteIfRegistered<EarnProfilesDiscoverController>(tag: _profileType);
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: BannerCarousel(
                images: _bannerImages,
                onBack: () => Navigator.pop(context),
                statusBarHeight: statusBarHeight,
                backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
                bottomBorderSide: const BorderSide(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: EarnProfileStoreList(
              controller: controller,
              footerLabel: 'View Services',
              emptyMessage: 'No home service providers found nearby.',
              onStoreTap: (store) =>
                  Get.to(() => HomeMadeFoodStoreDetailsDiscoverScreen(store: store)),
            ),
          ),
        ),
      ),
    );
  }
}
