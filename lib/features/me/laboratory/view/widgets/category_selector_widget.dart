import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/widgets/lab_category_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top-level lab category grid shown on the lab profile/tests tab.
///
/// Only categories the lab has actually added tests under are rendered —
/// the same filter [LabTestsTabV2] uses on the Tests tab. See there for
/// the reasoning behind the `_loadedAllTests` gate.
class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key, this.labID});

  final String? labID;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  static const List<_LabCategory> _categories = [
    _LabCategory(
      title: 'blood_routine',
      collection: 'Blood & Routine Tests',
      image: 'assets/category/medical/lab_blood_test_img.png',
    ),
    _LabCategory(
      title: 'preventive_wellness',
      collection: 'Preventive & Wellness Checkups',
      image: 'assets/category/medical/lab_wellness_img.png',
    ),
    _LabCategory(
      title: 'women_pregnancy',
      collection: 'Women, Pregnancy & Child Health',
      image: 'assets/category/medical/lab_women_helth_img.png',
    ),
    _LabCategory(
      title: 'diagnostics_imaging',
      collection: 'Diagnostics & Imaging',
      image: 'assets/category/medical/lab_diagnostics_img.png',
    ),
    _LabCategory(
      title: 'organ_system',
      collection: 'Organ & System Health',
      image: 'assets/category/medical/lab_organ_img.png',
    ),
    _LabCategory(
      title: 'infection_immunity',
      collection: 'Infection, Cancer & Immunity',
      image: 'assets/category/medical/lab_infection_img.png',
    ),
  ];

  /// Full lab-scoped test list — used purely to derive which of the six
  /// categories have any tests, so we can hide the empty ones. Mirrors the
  /// same filter [LabTestsTabV2] applies to its "Our Tests" grid so both
  /// surfaces show the same visible categories.
  final LabTestRepo _testRepo = LabTestRepo();
  List<PathologyTest> _allTests = const <PathologyTest>[];
  bool _loadedAllTests = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    // Until the tests fetch resolves, show every category so tiles don't
    // flash off after the initial paint. Once loaded, hide categories
    // with zero tests.
    final visible = !_loadedAllTests
        ? _categories
        : _categories
            .where((c) => _categoriesWithTests.contains(c.collection))
            .toList();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                AppStrings.labUpdateYourTest.tr,
                fontWeight: FontWeight.w700,
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  Get.to(
                    () => LabCategoryScreen(
                      controller: Get.find<LabFullDetailsController>(),
                    ),
                  );
                },
                child: CustomText(
                  AppStrings.viewAll.tr,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (visible.isEmpty)
            const SizedBox.shrink()
          else
            // Explicit zero padding — without it, GridView.builder inherits
            // MediaQuery safe-area padding from an ancestor scroll view and
            // renders a visible gap between the header row and the first
            // tile row.
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SizeConfig.size12,
                mainAxisSpacing: SizeConfig.size12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) =>
                  _buildCategoryTile(visible[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(_LabCategory category) {
    return InkWell(
      onTap: () => Get.to(
        LabTestListScreen(
          collection: category.collection,
          title: category.title,
          labId: widget.labID,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(category.image, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CustomText(
                  category.title,
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

class _LabCategory {
  final String title;
  final String collection;
  final String image;

  const _LabCategory({
    required this.title,
    required this.collection,
    required this.image,
  });
}
