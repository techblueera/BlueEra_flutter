import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/view/add_lab_test_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

  @override
  void initState() {
    super.initState();
    _testController = Get.isRegistered<LabTestController>()
        ? Get.find<LabTestController>()
        : Get.put(LabTestController(), permanent: true);
    _testController.fetchPopularTests();
  }

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          _PopularTestsSection(
            testController: _testController,
            pageController: _pageController,
            currentPage: _pageIndex,
            onPageChanged: (i) => setState(() => _pageIndex = i),
          ),
          SizedBox(height: SizeConfig.size12),
          _OurTestsSection(
            categories: _categories,
            controller: widget.controller,
          ),
          SizedBox(height: kBottomNavigationBarHeight + 20),
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
  final IconData icon;
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
    final iconBadge = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
    final labelWidget = CustomText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryColor,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
            iconAtStart ? const EdgeInsets.fromLTRB(4, 4, 12, 4) : const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
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
              trailing: _ChipCta(
                label: 'View All',
                icon: Icons.arrow_forward_rounded,
                iconAtStart: false,
                onTap: () => Get.to(
                  () => const LabTestListScreen(
                    collection: '',
                    title: 'Popular Tests',
                  ),
                ),
              ),
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
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: popular.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size8),
                    child: _PopularTestCard(
                      test: popular[i],
                      backgroundColor: LabSoftCardColor.forIndex(i),
                    ),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size10),
              _PagingDots(count: popular.length, active: currentPage),
            ],
          ],
        ),
      );
    });
  }
}

class _PagingDots extends StatelessWidget {
  final int count;
  final int active;

  const _PagingDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: on ? AppColors.primaryColor : AppColors.primaryColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
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
    final subtitle = paramNames.isNotEmpty ? paramNames : (test.description ?? '');

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
                padding: EdgeInsets.fromLTRB(SizeConfig.size16, 0, SizeConfig.size16, SizeConfig.size16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
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
                        border: Border.all(color: Colors.blue.shade400, width: 1.5),
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
              text: "${test.estimatedReportHours ?? 0} ${AppStrings.labHoursWord.tr}",
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
              icon: Icons.add,
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
