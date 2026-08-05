import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_list_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

class FinanceListingScreen extends StatefulWidget {
  final OnboardingCategoryModel? selectedCategory;

  const FinanceListingScreen({super.key, this.selectedCategory});

  @override
  State<FinanceListingScreen> createState() => _FinanceListingScreenState();
}

class _FinanceListingScreenState extends State<FinanceListingScreen> {
  final Rx<OnboardingCategoryModel?> _selectedCategory =
      Rx<OnboardingCategoryModel?>(null);

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/business-finance-employment-female-successful-entrepreneurs-concept_1258-93733.jpg?w=1380",
    "https://img.freepik.com/free-photo/financial-concept-with-wooden-cubes-calculator-coins_176474-8187.jpg?w=1380",
    "https://img.freepik.com/free-photo/arrangement-finance-elements-diagram_23-2148793749.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory.value =
        widget.selectedCategory ?? financeCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = financeCategories
        .map((c) => StickyCategory(
              id: c.slugId,
              name: c.name,
              imageUrl: c.icon,
            ))
        .toList();

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
                onBack: () => Navigator.pop(context),
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
                    () => StoreSearchScreen(config: StoreSearchConfig.finance())),
                categories: stickyCategories,
                selectedId: _selectedCategory.value?.slugId,
                onCategoryTap: (item) {
                  _selectedCategory.value =
                      financeCategories.firstWhere((c) => c.slugId == item.id);
                  setState(() {});
                },
                onBack: () => Navigator.pop(context),
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
          body: Obx(() => _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final selected = _selectedCategory.value;
    if (selected == null) {
      return const SizedBox.shrink();
    }
    return FinanceListScreen(
      categorySlugId: selected.slugId,
      key: Key(selected.slugId),
    );
  }
}
