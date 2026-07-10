import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_enquiry_sheet.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
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
  final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  final storeController = getOrPut(() => StoreController());

  List<PathologyTest> _tests = [];
  bool _isLoading = true;

  /// Resolved from the lab's full-details payload — the pathology-tests
  /// endpoint now keys on `LaboratoryProfile._id`, not the business/user
  /// id passed into the screen.
  String? _laboratoryId;

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
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.storeDetail,
      );
    }
    _fetchAll();
  }

  /// Loads the visited business profile first (its `user_id` is the key
  /// the lab-service full-details endpoint expects), then resolves the
  /// `LaboratoryProfile._id` and fetches this lab's tests.
  Future<void> _fetchAll() async {
    final id = widget.businessId;
    if (id.isNotEmpty) {
      await viewBusinessDetailsController.viewBusinessProfileById(id);
    }
    await _fetchTests();
  }

  Future<void> _fetchTests() async {
    try {
      // Resolve the LaboratoryProfile._id first — the backend now keys
      // /pathology-tests/laboratory/:labId on the lab profile id, not
      // the business id.
      final labId = await _resolveLaboratoryId();
      if (labId == null || labId.isEmpty) return;
      _laboratoryId = labId;

      final res = await LabTestRepo().getPathologyTestsByLab(
        labId,
        '', // empty collection → return every test for this lab
      );
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final tests = data.map((e) => PathologyTest.fromJson(e)).toList();
        if (mounted) setState(() => _tests = tests);
      }
    } catch (e) {
      debugPrint('LabDetailScreen fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _resolveLaboratoryId() async {
    final userId = viewBusinessDetailsController.visitedBusinessProfileDetails?.data?.userId;
    if (userId == null || userId.isEmpty) return null;
    try {
      final res = await LabFullDetailsRepo().getFullDetailsByUserId(userId);
      if (!res.isSuccess) return null;
      final data = res.response?.data?['data'];
      if (data is Map) {
        final profile = data['profile'];
        if (profile is Map) return profile['_id']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('LabDetailScreen resolve labId error: $e');
      return null;
    }
  }

  Future<void> _refresh() async {
    await viewBusinessDetailsController.viewBusinessProfileById(widget.businessId);
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
      bottomNavigationBar: Obx(() {
        viewBusinessDetailsController.profileVersion.value;
        final bar = _buildEnquiryBottomBar(
          viewBusinessDetailsController.visitedBusinessProfileDetails?.data,
        );
        return bar ?? const SizedBox.shrink();
      }),
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
                final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                return Padding(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  child: VisitBusinessCommonHeader(
                    details: details,
                    // Share the lab via its typed deep link so the recipient
                    // lands back on this detail screen (not the generic
                    // profile preview). Uses the same business-profile id the
                    // screen hydrates from.
                    shareLink: labsDeepLink(businessId: widget.businessId),
                    onRated: () => viewBusinessDetailsController.viewBusinessProfileById(
                      widget.businessId,
                      silent: true,
                    ),
                    onFollowChanged: () => viewBusinessDetailsController.viewBusinessProfileById(
                      widget.businessId,
                      silent: true,
                    ),
                  ),
                );
              }),
              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: VisitBusinessStatsCard(
                    details: viewBusinessDetailsController.visitedBusinessProfileDetails?.data,
                  ),
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
                final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: BusinessContactMapCard(
                    businessProfileDetails: details,
                    showEditButton: false,
                  ),
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
  // Cards mirror the `_TestCard` design used in `LabTestListScreen`:
  // soft pastel background, title + parameter subtitle, divider,
  // report-timing + price badges, and a home-collection footer with a
  // trailing chevron. Customer view, so no edit/delete affordances.
  Widget _buildPopularTests() {
    final displayList = _tests.take(5).toList();
    // Card width is ~86% of screen so the next card peeks in — signals
    // the row is horizontally scrollable without needing paging dots.
    final cardWidth = MediaQuery.of(context).size.width * 0.86;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceHomeTitleWidget(title: 'Popular Tests'),
            SizedBox(height: SizeConfig.size12),
            // IntrinsicHeight lets the row auto-size to the tallest
            // card — avoids the empty space a fixed height leaves when
            // content is short.
            IntrinsicHeight(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < displayList.length; i++) ...[
                      if (i > 0) SizedBox(width: SizeConfig.size12),
                      SizedBox(
                        width: cardWidth,
                        child: _popularTestCard(displayList[i], i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularTestCard(PathologyTest test, int index) {
    // `testParameters` is a mixed list — API can return String IDs or
    // full [TestParameter] objects. Prefer the object names; fall back
    // to description so the subtitle line is never empty.
    final paramNames = (test.testParameters ?? const [])
        .whereType<TestParameter>()
        .map((p) => p.name ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final subtitle = paramNames.isNotEmpty ? paramNames : (test.description ?? '');

    return Container(
      decoration: BoxDecoration(
        color: LabSoftCardColor.forIndex(index),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(
            () => LabTestListScreen(
              collection: test.collection ?? '',
              title: test.collection ?? test.testName ?? '',
              labId: _laboratoryId ?? widget.businessId,
              showAddButton: false,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size14,
                  SizeConfig.size14,
                  SizeConfig.size14,
                  SizeConfig.size10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      test.testName ?? '',
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size16,
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
                      color: Color(0xFFDDE2EE),
                      thickness: 0.5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _reportTimingBadge(test)),
                        SizedBox(width: SizeConfig.size8),
                        _priceBadge(test),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size14,
                  0,
                  SizeConfig.size14,
                  SizeConfig.size14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomText(
                                AppStrings.labHomeSampleAvailable.tr,
                                fontSize: 12,
                                color: Colors.black54,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
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

  Widget _reportTimingBadge(PathologyTest test) {
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

  Widget _priceBadge(PathologyTest test) {
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

  // ─── Test Categories ────────────────────────────────────────────────
  // Mirrors `_OurTestsSection` on the owner-side Lab Tests tab: tinted
  // container, brand-bar section header, and a 3-column grid of
  // hero-image tiles. Which categories render is driven by the tests'
  // `groupCategory` — only categories the lab actually offers show up.
  Widget _buildTestCategories() {
    final present = <String>{
      for (final t in _tests)
        if ((t.collection ?? '').isNotEmpty) t.collection!,
    };
    final active = _categoryConfig.where((c) => present.contains(c.collection)).toList();

    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categorySectionHeader(
              title: 'Test Category',
              subtitle: 'Tap a category to view tests',
            ),
            SizedBox(height: SizeConfig.size12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: active.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: SizeConfig.size10,
                    mainAxisSpacing: SizeConfig.size10,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (_, i) => _testCategoryCard(active[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySectionHeader({
    required String title,
    required String subtitle,
  }) {
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
      ],
    );
  }

  Widget _testCategoryCard(_LabCategoryConfig item) {
    return InkWell(
      onTap: () => Get.to(
        () => LabTestListScreen(
          collection: item.collection,
          title: item.label,
          labId: _laboratoryId ?? widget.businessId,
          showAddButton: false,
        ),
      ),
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
                child: Image.asset(item.image, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CustomText(
                  item.label,
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

  // ─── Enquiry CTA ────────────────────────────────────────────────────
  // Bottom-pinned "Send Enquiry" button — routes to
  // [LabEnquirySheet.open] which hits `/laboratory-enquiries`. Hidden
  // when the visited profile is the logged-in user's own lab so owners
  // don't enquire on themselves (mirrors the pharmacy detail screen).
  Widget? _buildEnquiryBottomBar(BusinessProfileDetails? profile) {
    final ownerId = (profile?.userId ?? '').trim();
    if (ownerId.isEmpty) return null;
    if (ownerId == userId) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        child: PositiveCustomBtn(
          onTap: () => _openInquirySheet(profile),
          title: AppStrings.inquiry.tr,
        ),
      ),
    );
  }

  void _openInquirySheet(BusinessProfileDetails? profile) {
    // Route uses LaboratoryProfile._id (resolved by _fetchTests). If the
    // lab profile hasn't been resolved yet, block with a snackbar rather
    // than post an enquiry the backend will reject.
    final labId = (_laboratoryId ?? '').trim();
    final ownerId = (profile?.userId ?? '').trim();
    if (labId.isEmpty || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    // Prefer the lab's actual catalog for the Tests chip pool so the
    // customer picks a real bookable test; falls back to the sheet's
    // built-in defaults when the catalog is empty.
    final catalogTestNames =
        _tests.map((t) => (t.testName ?? '').trim()).where((s) => s.isNotEmpty).toSet().toList();

    LabEnquirySheet.open(
      context,
      listing: LabEnquiryListing(
        laboratoryId: labId,
        ownerId: ownerId,
        labName: (profile?.businessName ?? 'Laboratory').trim(),
        labImage: profile?.logo,
        location: profile?.cityStatePincode,
      ),
      tests: catalogTestNames.isEmpty ? null : catalogTestNames,
    );
  }

  // ─── Live Photos ────────────────────────────────────────────────────
  Widget _buildLivePhotosSection() {
    return Obx(() {
      if (viewBusinessDetailsController.isProfileLoading.value) {
        return const SizedBox.shrink();
      }
      final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
      final livePhotos = details?.livePhotos?.where((p) => p.trim().isNotEmpty).toList();
      if (livePhotos == null || livePhotos.isEmpty) {
        return const SizedBox.shrink();
      }
      final natureOfBusiness = details?.subCategoryDetails?.name ?? details?.natureOfBusiness ?? 'OTHER';
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
