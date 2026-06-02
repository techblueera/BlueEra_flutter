import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeMadeProductServiceScreen extends StatefulWidget {
  final bool isShowInGrid;

  const HomeMadeProductServiceScreen({super.key, this.isShowInGrid = false});

  @override
  State<HomeMadeProductServiceScreen> createState() => _HomeMadeProductServiceScreenState();
}

class _HomeMadeProductServiceScreenState extends State<HomeMadeProductServiceScreen> {
  static const String _profileType = 'homeMadeProduct';

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-table-full-delicious-food-composition_23-2149141353.jpg?w=1380",
    "https://img.freepik.com/free-photo/flat-lay-batch-cooking-composition_23-2148765597.jpg?w=1380",
    "https://img.freepik.com/free-photo/home-made-food-concept-with-salad_23-2148580246.jpg?w=1380",
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
              footerLabel: 'View Products',
              emptyMessage: 'No home made product sellers found nearby.',
              onStoreTap: (store) =>
                  Get.to(() => HomeMadeFoodStoreDetailsDiscoverScreen(store: store)),
            ),
          ),
        ),
      ),
    );
  }
}
