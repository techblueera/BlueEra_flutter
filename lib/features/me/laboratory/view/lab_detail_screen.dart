import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Customer-facing lab profile — mirrors [MedicalPharmacyDetailScreen]:
/// shared header + stats, a horizontal Popular Tests carousel using the
/// same 140-wide product card silhouette, a 3-column categories grid with
/// the same product-category card silhouette (test-count instead of
/// product-count), live photos, and the unified contact + map card.
///
/// Data comes straight from [LabTestRepo] scoped to `businessId` so the
/// shared [LabTestController] state (used by the owner's Lab Tests tab)
/// isn't polluted while browsing a visited lab.
class LabDetailScreen extends StatefulWidget {
  final String businessId;

  const LabDetailScreen({super.key, required this.businessId});

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  final viewBusinessDetailsController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  final storeController = getOrPut(() => StoreController());

  List<PathologyTest> _tests = [];
  bool _isLoading = true;

  // ── Categories mirror `lab_tests_tab_v2.dart` so the customer tap
  // flow lands on the same `LabTestListScreen(collection, labId)` route.
  static const List<_LabCategoryConfig> _categoryConfig = [
    _LabCategoryConfig(
      label: 'Blood & Routine Tests',
      collection: 'Blood & Routine Tests',
      image: 'assets/category/medical/lab_blood_test_img.png',
    ),
    _LabCategoryConfig(
      label: 'Preventive & Wellness',
      collection: 'Preventive & Wellness Checkups',
      image: 'assets/category/medical/lab_wellness_img.png',
    ),
    _LabCategoryConfig(
      label: 'Women, Pregnancy & Child',
      collection: 'Women, Pregnancy & Child Health',
      image: 'assets/category/medical/lab_women_helth_img.png',
    ),
    _LabCategoryConfig(
      label: 'Diagnostics & Imaging',
      collection: 'Diagnostics & Imaging',
      image: 'assets/category/medical/lab_diagnostics_img.png',
    ),
    _LabCategoryConfig(
      label: 'Organ & System Health',
      collection: 'Organ & System Health',
      image: 'assets/category/medical/lab_organ_img.png',
    ),
    _LabCategoryConfig(
      label: 'Infection, Cancer & Immunity',
      collection: 'Infection, Cancer & Immunity',
      image: 'assets/category/medical/lab_infection_img.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final id = widget.businessId;
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.storeDetail,
      );
    }
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    try {
      final res = await LabTestRepo().getPathologyTestsByLab(
        widget.businessId,
        '', // empty collection → return every test for this lab
      );
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final tests =
            data.map((e) => PathologyTest.fromJson(e)).toList();
        if (mounted) setState(() => _tests = tests);
      }
    } catch (e) {
      debugPrint('LabDetailScreen fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    viewBusinessDetailsController.viewBusinessProfileById(widget.businessId);
    await _fetchTests();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CommonBackAppBar(title: 'Laboratory'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared profile header — banner, logo, rating, follow/share.
              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return buildBusinessHeaderSkeleton();
                }
                final details = viewBusinessDetailsController
                    .visitedBusinessProfileDetails
                    ?.data;
                return VisitBusinessCommonHeader(
                  details: details,
                  onRated: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                  onFollowChanged: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                );
              }),
              SizedBox(height: SizeConfig.size10),

              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                return VisitBusinessStatsCard(
                  details: viewBusinessDetailsController
                      .visitedBusinessProfileDetails
                      ?.data,
                );
              }),
              SizedBox(height: SizeConfig.size10),

              if (_tests.isNotEmpty) ...[
                _buildPopularTests(),
                SizedBox(height: SizeConfig.size10),
              ],

              if (_tests.isNotEmpty) ...[
                _buildTestCategories(),
                SizedBox(height: SizeConfig.size10),
              ],

              _buildLivePhotosSection(),

              Obx(() {
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return const SizedBox.shrink();
                }
                final details = viewBusinessDetailsController
                    .visitedBusinessProfileDetails
                    ?.data;
                return BusinessContactMapCard(
                  businessProfileDetails: details,
                  showEditButton: false,
                );
              }),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Popular Tests ──────────────────────────────────────────────────
  // Same layout as `_buildPopularProducts` on the pharmacy detail screen:
  // a horizontal ListView of 140-wide cards with image + name + price.
  Widget _buildPopularTests() {
    // Trim to the same 5-item preview the medical screen uses; more can
    // be surfaced later behind a "View All" chip if you need it.
    final displayList = _tests.take(5).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Popular Tests'),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayList.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) => _popularTestCard(displayList[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularTestCard(PathologyTest test) {
    final image = _imageForCollection(test.collection);
    final price = test.customerPrice;
    final tat = test.estimatedReportHours;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            child: image != null
                ? Image.asset(image, fit: BoxFit.contain)
                : Icon(
                    Icons.biotech_outlined,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    test.testName ?? 'Laboratory',
                    fontSize: 11,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (price != null)
                        CustomText(
                          '${AppStrings.labInrPrefix.tr}$price',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainTextColor,
                        ),
                      if (tat != null) ...[
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          '${tat}h',
                          fontSize: 9,
                          color: AppColors.green00,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Test Categories ────────────────────────────────────────────────
  // Same layout as `_buildMedicalProductCategories`: 3-column GridView,
  // static category tiles with image + label + count.
  Widget _buildTestCategories() {
    // Count tests per collection so each tile shows how many tests the
    // lab offers under that category — mirrors "$productCount products".
    final counts = <String, int>{};
    for (final t in _tests) {
      final key = t.collection ?? '';
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final active = _categoryConfig
        .map((c) => (config: c, count: counts[c.collection] ?? 0))
        .where((e) => e.count > 0)
        .toList();

    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Test Categories'),
            SizedBox(height: SizeConfig.size12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: active.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final entry = active[index];
                return _testCategoryCard(entry.config, entry.count);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _testCategoryCard(_LabCategoryConfig item, int testCount) {
    return InkWell(
      onTap: () => Get.to(
        () => LabTestListScreen(
          collection: item.collection,
          title: item.label,
          labId: widget.businessId,
          showAddButton: false,
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item.image,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              item.label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              color: Colors.blueGrey.shade700,
            ),
            const SizedBox(height: 2),
            CustomText(
              '$testCount Tests',
              fontSize: 9,
              color: AppColors.green00,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Live Photos ────────────────────────────────────────────────────
  Widget _buildLivePhotosSection() {
    return Obx(() {
      if (viewBusinessDetailsController.isProfileLoading.value) {
        return const SizedBox.shrink();
      }
      final details =
          viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
      final livePhotos = details?.livePhotos
          ?.where((p) => p.trim().isNotEmpty)
          .toList();
      if (livePhotos == null || livePhotos.isEmpty) {
        return const SizedBox.shrink();
      }
      final natureOfBusiness = details?.subCategoryDetails?.name ??
          details?.natureOfBusiness ??
          'OTHER';
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: CommonCardWidget(
          padding: 10,
          cardMargin: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.groceryViewLivePhotos.tr,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 10),
              StoreLivePhotoWidget(
                livePhotos: livePhotos,
                natureOfBusiness: natureOfBusiness,
                onViewFullScreen: ({
                  required int index,
                  required List<String> storeImage,
                  required String natureOfBusiness,
                }) {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: details?.businessName ?? '',
                      subTitle: natureOfBusiness,
                      imageUrls: storeImage,
                      initialIndex: index,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Map a test's `collection` to the same PNG the categories grid uses,
  /// so the Popular Tests card image reads as a mini category badge when
  /// the API doesn't return a per-test image.
  String? _imageForCollection(String? collection) {
    if (collection == null || collection.isEmpty) return null;
    for (final c in _categoryConfig) {
      if (c.collection == collection) return c.image;
    }
    return null;
  }
}

class _LabCategoryConfig {
  final String label;
  final String collection;
  final String image;

  const _LabCategoryConfig({
    required this.label,
    required this.collection,
    required this.image,
  });
}
