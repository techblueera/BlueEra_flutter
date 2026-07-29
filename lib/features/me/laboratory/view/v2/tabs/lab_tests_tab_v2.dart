import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/create_your_own_packages_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/my_lab_packages_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/lab_category_screen.dart';

/// Tests tab — matches assets/img.png:
///   1. Popular Tests — PageView carousel of test cards + paging dots.
///   2. Our Tests    — 2×3 category grid; taps open [LabTestListScreen].
class LabTestsTabV2 extends StatefulWidget {
  final LabFullDetailsController controller;

  const LabTestsTabV2({super.key, required this.controller});

  @override
  State<LabTestsTabV2> createState() => _LabTestsTabV2State();
}

class _LabTestsTabV2State extends State<LabTestsTabV2> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _pageIndex = 0;
  late final LabTestController _testController;
  late final LabPackageController _packageController;

  /// Full lab-scoped test list — used purely to derive which of the six
  /// categories have any tests, so we can hide the empty ones. Kept
  /// separate from [LabTestController.tests] (which gets overwritten by
  /// per-category screens) and from [LabTestController.popularTests]
  /// (which is capped at 5).
  final LabTestRepo _testRepo = LabTestRepo();
  List<PathologyTest> _allTests = const <PathologyTest>[];
  bool _loadedAllTests = false;

  @override
  void initState() {
    super.initState();
    _testController = Get.isRegistered<LabTestController>()
        ? Get.find<LabTestController>()
        : Get.put(LabTestController(), permanent: true);
    _packageController = Get.isRegistered<LabPackageController>()
        ? Get.find<LabPackageController>()
        : Get.put(LabPackageController(), permanent: true);
    _testController.fetchPopularTests();
    _packageController.fetchMyPackages();
    _fetchAllTestsForFilter();
  }

  Future<void> _fetchAllTestsForFilter() async {
    try {
      final res = await _testRepo.getPathologyTests('');
      if (!mounted) return;
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        setState(() {
          _allTests = data
              .whereType<Map<String, dynamic>>()
              .map(PathologyTest.fromJson)
              .toList();
          _loadedAllTests = true;
        });
      } else {
        setState(() => _loadedAllTests = true);
      }
    } catch (_) {
      if (mounted) setState(() => _loadedAllTests = true);
    }
  }

  /// Which of the six `groupCategory` values actually have at least one
  /// test in this lab. Empty until the fetch resolves — callers should
  /// treat "not yet loaded" as "show everything" so nothing flashes off.
  Set<String> get _categoriesWithTests => _allTests
      .map((t) => t.groupCategory ?? '')
      .where((s) => s.isNotEmpty)
      .toSet();

  /// Six category tiles — same collection strings the previous
  /// [CategorySelector] used, so backend filtering stays identical.
  static const List<_CategoryEntry> _categories = [
    _CategoryEntry(
      label: 'Blood & Routine Tests',
      collection: 'Blood & Routine Tests',
      image: 'assets/category/medical/lab_blood_test_img.png',
    ),
    _CategoryEntry(
      label: 'Preventive & Wellness',
      collection: 'Preventive & Wellness Checkups',
      image: 'assets/category/medical/lab_wellness_img.png',
    ),
    _CategoryEntry(
      label: 'Women, Pregnancy & Child',
      collection: 'Women, Pregnancy & Child Health',
      image: 'assets/category/medical/lab_women_helth_img.png',
    ),
    _CategoryEntry(
      label: 'Diagnostics & Imaging',
      collection: 'Diagnostics & Imaging',
      image: 'assets/category/medical/lab_diagnostics_img.png',
    ),
    _CategoryEntry(
      label: 'Organ & System Health',
      collection: 'Organ & System Health',
      image: 'assets/category/medical/lab_organ_img.png',
    ),
    _CategoryEntry(
      label: 'Infection, Cancer & Immunity',
      collection: 'Infection, Cancer & Immunity',
      image: 'assets/category/medical/lab_infection_img.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Until the tests fetch resolves, show every category so tiles don't
    // flash off after the initial paint. Once loaded, hide categories
    // with zero tests.
    final visibleCategories = !_loadedAllTests
        ? _categories
        : _categories
            .where((c) => _categoriesWithTests.contains(c.collection))
            .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          // Contribution / Bank / Refer deck. No catalog card here: this tab IS
          // the add surface and carries its own add masthead, so a card pointing
          // at the screen you are already on would be noise.
          OrderActionsCarousel(),
          SizedBox(height: SizeConfig.size12),

          // Single Obx wraps the data-driven region so we can collapse the
          // whole thing to a single empty-state card (matches
          // assets/img_1.png) once both fetches resolve and both come back
          // empty — otherwise render the normal three-section stack.
          Obx(() {
            final packagesLoaded = !_packageController.isLoading.value;
            final everythingEmpty = _loadedAllTests &&
                packagesLoaded &&
                _allTests.isEmpty &&
                _packageController.myPackages.isEmpty;
            if (everythingEmpty) {
              return _emptyStateCard();
            }

            // Same preset filtering the packages section used to do inline —
            // matches on `packageType` with a legacy `name` fallback so
            // pre-migration rows still surface.
            final withPackages = _packageController.myPackages
                .map((p) => ((p.packageType ?? '').trim().isNotEmpty
                        ? p.packageType!
                        : p.name ?? '')
                    .trim())
                .where((s) => s.isNotEmpty)
                .toSet();
            final visiblePresets = LabPackageController.presetNames
                .where(withPackages.contains)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _productsBanner(
                  onAddTests: () => Get.to(
                      () => LabCategoryScreen(controller: widget.controller)),
                ),
                SizedBox(height: SizeConfig.size12),
                _PopularTestsSection(
                  testController: _testController,
                  pageController: _pageController,
                  currentPage: _pageIndex,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                ),
                SizedBox(height: SizeConfig.size12),
                if (visibleCategories.isNotEmpty) ...[
                  _OurTestsSection(
                    categories: visibleCategories,
                    controller: widget.controller,
                  ),
                  SizedBox(height: SizeConfig.size12),
                ],
                if (visiblePresets.isNotEmpty) ...[
                  _OurTestsPackagesSection(
                    presets: visiblePresets,
                    onAddMore: () =>
                        Get.to(() => const CreateYourOwnPackagesScreen()),
                    // Route by the preset value so the listing screen can
                    // apply the `/packages/me?packageType=...` filter (with
                    // a legacy `name` match fallback baked into the screen).
                    onTapPreset: (preset) => Get.to(
                      () => MyLabPackagesScreen(
                        title: preset,
                        packageType: preset,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),
                ],
              ],
            );
          }),
          SizedBox(height: kBottomNavigationBarHeight + 20),
        ],
      ),
    );
  }

  /// Empty-state card shown when the tab has no tests AND no packages
  /// (matches assets/img_1.png). Tapping "+ Add Now" opens the same add-
  /// tests flow as the top banner's chip.
  Widget _emptyStateCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size20,
        vertical: SizeConfig.size28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.emptyIcon,
            height: 100,
            width: 100,
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'No Tests Added Yet',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            'Add diagnostic tests to Laboratry.',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: () =>
                Get.to(() => LabCategoryScreen(controller: widget.controller)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    'Add Now',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryEntry {
  final String label;
  final String collection;
  final String image;

  const _CategoryEntry({
    required this.label,
    required this.collection,
    required this.image,
  });
}

// ─── Shared header + chip primitives ────────────────────────────────────

/// Vertical brand bar + bold title + one-line helper + trailing chip.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                subtitle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        trailing,
      ],
    );
  }
}

/// Brand-outlined chip with a solid circular icon badge — used for both
/// "View All →" (icon at end) and "+ Add Test" (icon at start).
class _ChipCta extends StatelessWidget {
  final String label;
  final String icon;
  final bool iconAtStart;
  final VoidCallback onTap;

  const _ChipCta({
    required this.label,
    required this.icon,
    required this.iconAtStart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBadge = LocalAssets(
        imagePath: icon, imgColor: AppColors.white, height: 14, width: 14);
    final labelWidget = CustomText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.white,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: iconAtStart
            ? const EdgeInsets.fromLTRB(4, 4, 12, 4)
            : const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconAtStart
              ? [iconBadge, SizedBox(width: SizeConfig.size6), labelWidget]
              : [labelWidget, SizedBox(width: SizeConfig.size6), iconBadge],
        ),
      ),
    );
  }
}

// ─── Section 1: Popular Tests ───────────────────────────────────────────

class _PopularTestsSection extends StatelessWidget {
  final LabTestController testController;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _PopularTestsSection({
    required this.testController,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final popular = testController.popularTests;
      final isLoading = testController.isLoadingPopular.value;

      return Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                title: 'Popular Tests',
                subtitle: 'Most Booked This Month',
                trailing: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.20),
                      width: 0.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => Get.to(
                      () => const LabTestListScreen(
                        collection: '',
                        title: 'Popular Tests',
                      ),
                    ),
                    child: CustomText(
                      "View All",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                // _ChipCta(
                //   label: 'View All',
                //   iconAtStart: false,
                //   onTap: () => Get.to(
                //     () => const LabTestListScreen(
                //       collection: '',
                //       title: 'Popular Tests',
                //     ),
                //   ),
                // ),
                ),
            SizedBox(height: SizeConfig.size12),
            if (isLoading && popular.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (popular.isEmpty)
              const _PopularEmptyCard()
            else ...[
              // Card content is ~180px; keep the PageView slot just tall
              // enough for the card plus a hair of breathing room so the
              // tinted background doesn't leave an empty strip below.
              SizedBox(
                height: 195,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: popular.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size8),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _PopularTestCard(
                        test: popular[i],
                        backgroundColor: LabSoftCardColor.forIndex(i),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PopularEmptyCard extends StatelessWidget {
  const _PopularEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: CustomText(
        'No tests added yet',
        fontSize: 13,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}

/// Same card design as [LabTestListScreen]'s `_TestCard` (ported from
/// the catalog screen) — soft pastel background, title + params, divider,
/// report-timing + price badges, home-sample bar with edit-pencil action.
/// Popular tests are always owner-side, so the whole card taps into
/// [AddLabTestScreen] and the trailing action shows an edit pencil.
class _PopularTestCard extends StatelessWidget {
  final PathologyTest test;
  final Color backgroundColor;

  const _PopularTestCard({
    required this.test,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // `testParameters` is a mixed list — API can return String IDs or full
    // [TestParameter] objects. Prefer object names; fall back to
    // description when only IDs are present so the card never looks empty.
    final paramNames = (test.testParameters ?? const [])
        .whereType<TestParameter>()
        .map((p) => p.name ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final subtitle =
        paramNames.isNotEmpty ? paramNames : (test.description ?? '');

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(
            () => AddLabTestScreen(
              testToEdit: test,
              collection: test.collection ?? '',
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      test.testName ?? '',
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size18,
                      color: Colors.black87,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    if (subtitle.isNotEmpty)
                      CustomText(
                        subtitle,
                        fontSize: SizeConfig.small,
                        color: Colors.black54,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Divider(
                      height: 20,
                      thickness: 0.5,
                      color: Color(0xFFDDE2EE),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _reportTimingBadge(),
                        _priceBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    SizeConfig.size16, 0, SizeConfig.size16, SizeConfig.size16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 8, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            CustomText(
                              AppStrings.labHomeSampleAvailable.tr,
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: Colors.blue.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTimingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: SizeConfig.small,
          ),
          children: [
            TextSpan(text: "${AppStrings.labReportsWithinPrefix.tr} "),
            TextSpan(
              text:
                  "${test.estimatedReportHours ?? 0} ${AppStrings.labHoursWord.tr}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: CustomText(
        "${AppStrings.labInrPrefix.tr}${test.customerPrice ?? 0}",
        fontWeight: FontWeight.bold,
        fontSize: SizeConfig.size14,
      ),
    );
  }
}

// ─── Section 2: Our Tests (2×3 grid) ────────────────────────────────────

class _OurTestsSection extends StatelessWidget {
  final List<_CategoryEntry> categories;
  final LabFullDetailsController controller;

  const _OurTestsSection({
    required this.categories,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Our Tests',
            subtitle: 'Tap a category to view tests',
            trailing: _ChipCta(
              label: 'Add Test',
              icon: AppIconAssets.add,
              iconAtStart: true,
              // Opens the linear category-picker list. LabCategoryScreen
              // is a bare Column today, so wrap it in a Scaffold + app bar
              // here — no in-place edit to LabCategoryScreen needed.
              onTap: () => Get.to(
                () => LabCategoryScreen(controller: controller),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: SizeConfig.size10,
                  mainAxisSpacing: SizeConfig.size10,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (_, i) => _CategoryTile(entry: categories[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _productsBanner({required VoidCallback onAddTests}) {
  // Faded test-tubes illustration (test_tab.png) as the card background,
  // with dark text + tinted icon badge + "+ Add Tests" CTA on top —
  // matches assets/img_1.png. The bg image is anchored to the right so
  // the illustration fills behind the CTA without crowding the title.
  return Container(
    // margin: EdgeInsets.only(right: SizeConfig.size20, top: SizeConfig.size4),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF4F9FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE6EEF7)),
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF2E8BE0), Color(0xFF7FD6CE)],
      ),
      image: DecorationImage(
        image: AssetImage(AppIconAssets.testTabBg),
        alignment: Alignment.centerRight,
        fit: BoxFit.cover,
        // Soften the illustration so it never fights the text on top.
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: 0.35),
          BlendMode.lighten,
        ),
      ),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: SizeConfig.size12,
      vertical: SizeConfig.size10,
    ),
    child: Row(
      children: [
        Container(
          width: SizeConfig.size36,
          height: SizeConfig.size36,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: LocalAssets(
              imagePath: AppIconAssets.laboratoryIcon,
              imgColor: AppColors.primaryColor,
              boxFix: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "Lab Tests",
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              CustomText(
                "Manage your lab Tests",
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        GestureDetector(
          onTap: onAddTests,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                    imagePath: AppIconAssets.add,
                    imgColor: AppColors.primaryColor,
                    height: 14,
                    width: 14),
                SizedBox(
                  width: 4,
                ),
                CustomText(
                  'Add Tests',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        )
      ],
    ),
  );
}

// ─── Section 3: Our Tests Packages (preset grid) ────────────────────────

/// "Our Tests Packages" — mirrors the "Our Tests" tile layout but shows
/// [LabPackageController.presetNames] filtered to the ones the current
/// lab actually has packages under. Taps open [MyLabPackagesScreen]
/// scoped by preset name; the "+ Add More" chip opens the create flow.
class _OurTestsPackagesSection extends StatelessWidget {
  final List<String> presets;
  final VoidCallback onAddMore;
  final void Function(String preset) onTapPreset;

  const _OurTestsPackagesSection({
    required this.presets,
    required this.onAddMore,
    required this.onTapPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Our Tests Packages',
            subtitle: 'Tap a category to view tests',
            trailing: _ChipCta(
              label: 'Add More',
              icon: AppIconAssets.add,
              iconAtStart: true,
              onTap: onAddMore,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: presets.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: SizeConfig.size10,
                  mainAxisSpacing: SizeConfig.size10,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (_, i) => _PackagePresetTile(
                  preset: presets[i],
                  onTap: () => onTapPreset(presets[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Preset tile — soft-blue hero with a tinted icon badge, label below.
/// Matches [_CategoryTile]'s shape so the two grids read as siblings.
class _PackagePresetTile extends StatelessWidget {
  final String preset;
  final VoidCallback onTap;

  const _PackagePresetTile({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: LocalAssets(
                    imagePath: _iconForPreset(preset),
                    height: 50,
                    width: 50,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CustomText(
                  preset,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SVG asset path for each preset in [LabPackageController.presetNames],
/// mirroring the mapping used by [CreateYourOwnPackagesScreen] so both
/// surfaces share the same iconography.
String _iconForPreset(String preset) {
  switch (preset) {
    case 'Basic Health Checkup':
      return AppIconAssets.basicHealthCampIcon;
    case 'Full Body Checkup':
      return AppIconAssets.fullBodycheckupIcon;
    case 'Executive Health Package':
      return AppIconAssets.healthPackageIcon;
    case 'Diabetes Package':
      return AppIconAssets.diabetesPackageIcon;
    case 'Thyroid Package':
      return AppIconAssets.thyroidPackageIcon;
    case 'Heart Check-up Package':
      return AppIconAssets.heartPacakgeIcon;
    case 'Senior Citizen Package':
      return AppIconAssets.seniorPackageIcon;
    case 'Men Health Package':
      return AppIconAssets.menhealthPackageIcon;
    default:
      return AppIconAssets.healthPackageIcon;
  }
}

/// Tinted-hero + white-footer category tile. Taps open the category
/// listing so the flow into [LabTestListScreen] stays identical.
class _CategoryTile extends StatelessWidget {
  final _CategoryEntry entry;

  const _CategoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(
        () => LabTestListScreen(
          collection: entry.collection,
          title: entry.label,
          // Read-only browse from the Our Tests grid — adding lives on
          // the "+ Add Test" chip / LabCategoryScreen flow instead.
          showAddButton: false,
        ),
      ),
      // borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        // clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(entry.image, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CustomText(
                  entry.label,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
