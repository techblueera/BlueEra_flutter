import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/other_service_business_search_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/service_business_card.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

class ServicesNearMeScreen extends StatefulWidget {
  final String? serviceCategoryName;
  final String? serviceCategory;

  const ServicesNearMeScreen({
    super.key,
    this.serviceCategoryName,
    this.serviceCategory,
  });

  @override
  State<ServicesNearMeScreen> createState() => _ServicesNearMeScreenState();
}

class _ServicesNearMeScreenState extends State<ServicesNearMeScreen> {
  final controller = getOrPut(() => OtherServiceBusinessSearchController());
  final AuthController _authController = Get.find<AuthController>();
  final RxInt _selectedIndex = 0.obs;

  List<CategoryData> get _categories => _authController.businessOnboardingServicesCategories;

  final List<String> _bannerImages = const [
    // A doctor, a tool rack and a salon — the three service kinds this screen
    // lists. Each URL was downloaded and viewed before committing; the freepik
    // links they replace served a businesswoman by an office block, an
    // "I LOVE YOU" greeting card and a gold geometric wallpaper pattern.
    "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=1380&q=80",
    "https://images.unsplash.com/photo-1530124566582-a618bc2615dc?w=1380&q=80",
    "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1380&q=80",
  ];

  String? get _initialCategoryId {
    if (widget.serviceCategory != null) return widget.serviceCategory;
    if (_categories.isNotEmpty) return _categories.first.tagId;
    return null;
  }

  @override
  void initState() {
    super.initState();

    if (widget.serviceCategory != null && _categories.isNotEmpty) {
      final idx = _categories.indexWhere((c) => c.tagId == widget.serviceCategory);
      if (idx >= 0) _selectedIndex.value = idx;
    }

    final cat = _initialCategoryId;
    if (cat != null && cat.isNotEmpty) {
      controller.fetchInitial(cat);
    }
  }

  void _onCategoryTap(CategoryData item, int index) {
    _selectedIndex.value = index;
    final tag = item.tagId ?? '';
    if (tag.isNotEmpty) controller.fetchInitial(tag);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final width = SizeConfig.screenWidth;
    double dynamicSize(double base) => base * (width / 390);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: BannerCarousel(
                images: _bannerImages,
                onBack: () => Get.back(),
                statusBarHeight: statusBarHeight,
                backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
                bottomBorderSide: const BorderSide(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                // The header paints a search bar; this is what it opens —
                // the shared store search, scoped to this vertical by its
                // StoreSearchConfig. Tapping a result opens that profile.
                onSearchTap: () => Get.to(
                    () => StoreSearchScreen(config: StoreSearchConfig.services())),
                categories: _categories
                    .map((c) => StickyCategory(
                          id: c.tagId ?? '',
                          name: c.name ?? '',
                          // The API's own artwork — see the note in
                          // products_store_discover_screen.dart.
                          imageUrl: c.imageUrl,
                        ))
                    .toList(),
                selectedId: _categories.isNotEmpty && _selectedIndex.value < _categories.length
                    ? _categories[_selectedIndex.value].tagId
                    : null,
                onCategoryTap: (item) {
                  final idx = _categories.indexWhere((c) => c.tagId == item.id);
                  if (idx >= 0) _onCategoryTap(_categories[idx], idx);
                  setState(() {});
                },
                onBack: () => Get.back(),
                expandedLabelColor: AppColors.white,
                backgroundGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.blue5CAF.withValues(alpha: 0.1),
                    AppColors.blue5CAF.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: _buildStoreContent(dynamicSize),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreContent(double Function(double) dynamicSize) {
    return Obx(() {
      // Full-screen loader is gated on BOTH flags so pagination can never
      // trigger it. `fetchMore` only flips `isLoadingMore` (see
      // [OtherServiceBusinessSearchController._fetch]) and leaves `isLoading`
      // false, and `profiles` is non-empty by the time paging kicks in — so
      // this branch is reachable exclusively on the very first load or on a
      // category switch, when `fetchInitial` clears the list and sets
      // `isLoading = true`.
      if (controller.isLoading.value && controller.profiles.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.profiles.isEmpty) {
        final categoryName = (_selectedIndex.value >= 0 && _selectedIndex.value < _categories.length)
            ? _categories[_selectedIndex.value].name ?? ''
            : '';
        return Center(
          child: EmptyStateWidget(
            message: AppStrings.noServicesFoundForCategory.trParams({'category': categoryName}),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.paddingXSL),
          Expanded(
            child: MasonryGridView.count(
              padding: EdgeInsets.only(
                left: SizeConfig.size12,
                right: SizeConfig.size12,
                bottom: SizeConfig.paddingL,
              ),
              crossAxisCount: 2,
              mainAxisSpacing: dynamicSize(12),
              crossAxisSpacing: dynamicSize(12),
              itemCount: controller.profiles.length,
              itemBuilder: (context, index) {
                final item = controller.profiles[index];
                return ServiceBusinessCard(item: item, index: index);
              },
            ),
          ),
          // The global ProgressDialog / ShimmerListView overlay is
          // suppressed for this endpoint (see
          // [OtherServiceBusinessSearchController._fetch]'s
          // `showProgress: false`), so this footer is the only loader
          // that renders during pagination. Kept outside the grid so it
          // doesn't take up a single tile's worth of space in one column.
          if (controller.isLoadingMore.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      );
    });
  }
}
