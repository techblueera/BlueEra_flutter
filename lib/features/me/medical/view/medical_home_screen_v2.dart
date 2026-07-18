import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart' show ApiKeys;
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_verfication.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
// The medical business-products endpoint ships grocery's exact response shape
// (docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so the Top Selling rail
// reuses grocery's grouping helper, card and variants sheet.
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/model/my_medical_super_category_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical/view/medical_gallery/medical_gallery_list_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_inquiry_tab_v2.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/gradient_add_button.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../business/widgets/profile_share_banner.dart';

/// Medical Home screen (v2) â€” redesigned to match IMG-3 reference.
class MedicalHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const MedicalHomeScreenV2({super.key, required this.businessId});

  @override
  State<MedicalHomeScreenV2> createState() => _MedicalHomeScreenV2State();
}

class _MedicalHomeScreenV2State extends State<MedicalHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;
  // Lands on the first tab (Inquiry, index 0) on open.
  late final TabController _tabController;

  late final MedicalGalleryController _galleryController;
  late final MedicalController _medicalController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab â€” same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`
  // and the Order tab in `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` â†’ `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  List<String> _tabs = [
    AppStrings.inquiry.tr,
    // AppStrings.orders.tr,
    AppStrings.overview.tr,
    AppStrings.products.tr,
    AppStrings.posts.tr,
    AppStrings.stats.tr,
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabs.length, initialIndex: 0, vsync: this)
          ..addListener(_handleTabChange);
    registerMeTabBackHandler(_tabController);
    _galleryController = Get.put(MedicalGalleryController());
    _medicalController = getOrPut(() => MedicalController());
    // Hydrate the business chat list so the Inquiry tab has data ready
    // when the user switches to it. Mirrors what `HospitalHomeScreenV2`,
    // `SchoolHomeScreenV2` and `professionals_main.dart` do.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    _fetchData();
    // The once-a-day "add your medicines" nudge. Owner-only: this screen is
    // also reachable via RouteConstant.medicalHomeScreen with an arbitrary
    // businessId, and prompting someone to stock a pharmacy that isn't theirs
    // would be nonsense. No livePhotoGate â€” medical never pops the live-photo
    // sheet, so there's nothing to collide with.
    if (widget.businessId == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAddProductPromptIfNeeded(
          context: context,
          spec: const AddProductPromptSpec(
            titleKey: AppStrings.addPromptTitleMedical,
            ctaKey: AppStrings.addProduct,
            icon: Icons.medication_outlined,
          ),
          onAddProduct: () => _tabController.animateTo(2),
        );
      });
    }
  }

  /// Per-tab API dispatcher. Nothing but the profile fetch runs on landing —
  /// every other tab's data is pulled the first time that tab is opened, and
  /// each `*IfNeeded()` no-ops while its data is still loaded and fresh, so
  /// hopping between tabs (or leaving and coming back) doesn't refetch.
  ///
  /// Tabs: 0 Inquiry, 1 Overview, 2 Products, 3 Posts, 4 Stats.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        // Inquiry — the chat list is hydrated once in initState.
        break;
      case 1:
        // Overview — reads the profile fetched by _fetchData() plus the
        // permanent ViewBusinessDetailsController. Nothing of its own.
        break;
      case 2:
        _ensureProductsLoaded();
        break;
      case 3:
        // Post — FeedScreen owns its own fetch on mount.
        break;
      case 4:
        // Stats — ProfileStatisticsScreen owns its own data.
        break;
    }
  }

  /// Products tab: Top Selling + category-with-inventory, both behind the
  /// controller's freshness guard.
  void _ensureProductsLoaded() {
    _medicalController.fetchMedicalProductsTabDataIfNeeded(
      businessId: widget.businessId,
    );
  }

  Future<void> _fetchData() async {
    try {
      final res = await MedicalRepo()
          .fetchMedicalProfileFd(businessId: widget.businessId);
      if (res.isSuccess && res.response?.data != null) {
        final data = res.response?.data['data'] ?? res.response?.data;
        if (data != null && data is Map<String, dynamic>) {
          setState(() => _data = MedicalHomeResponseModel.fromJson(data));
          _populateGalleryFromResponse(data['gallery']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching medical profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateGalleryFromResponse(dynamic galleryJson) {
    if (galleryJson == null || galleryJson is! List || galleryJson.isEmpty) {
      return;
    }
    if (_galleryController.galleryList.isNotEmpty) return;

    try {
      for (final item in galleryJson) {
        if (item is Map<String, dynamic>) {
          final entry = OtherServiceGalleryData.fromJson(item);
          if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty) {
            _galleryController.galleryList.add(entry);
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing gallery from home response: $e");
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUILD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Fires the newly-opened tab's fetch. Guarded on `indexIsChanging` so a
  /// swipe only dispatches once it settles, not for every tab it passes over.
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchForTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Wraps a tab's content list in a scrollable body for the [TabBarView].
  Widget _tabScroll(List<Widget> children) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  HomeTabScaffold(
                    controller: _tabController,
                    tabLabels: _tabs,
                    topBarHeight: topBarHeight,
                    topBar: Column(
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopBar(),
                        // _buildProfileRow(_data?.businessProfile),
                      ],
                    ),
                    // Top bar (status inset + ~56) + the profile row (~74).
                    // Sized with headroom so the profile row's two text lines
                    // don't overflow the fixed header height (was +120 → 6px
                    // overflow).
                    // topBarHeight: MediaQuery.of(context).padding.top + 132,
                    tabViews: [
                      _tabScroll([
                        MedicalInquiryTabV2(
                          onAddProducts: () => _tabController.animateTo(2),
                        ),
                      ]),
                      // ProfileStatisticsScreen(userId: userId),
                      _tabScroll(_buildOverviewSlivers()),
                      _tabScroll(_buildProductsTab()),
                      _tabScroll(_buildPostTab()),
                      ProfileStatisticsScreen(userId: userId),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TAB CONTENT â€” switches body by _selectedTab
  //   0 Inquiry, 1 Order, 2 Overview, 3 Products, 4 Post, 5 Statics
  //
  // Inquiry was inserted at index `0`; every other tab's case shifted
  // by `+1`. The legacy `Order` placeholder still surfaces stats (kept
  // identical to before â€” same `ProfileStatisticsScreen` body), just
  // at its new index `1` so the existing flow stays intact.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // INQUIRY TAB â€” incoming inquiries only (chats whose latest message
  // was authored by *someone else*). Mirrors `HospitalInquiryTabV2` /
  // `SchoolInquiryTabV2` and the Order tab in `professionals_main.dart`.
  //
  // `BusinessChatsList` ships an Expanded `ListView` internally, so
  // it must live inside a bounded box; we use a fraction of the
  // screen height to play nicely with the parent SingleChildScrollView.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Widget> _buildOverviewSlivers() {
    return [
      _buildBannerSection(_data?.businessProfile),
      // SizedBox(height: SizeConfig.size8),
      // _buildCreateOffersButton(),
      SizedBox(height: SizeConfig.size12),
      // if ((_data?.inventorySummary?.popularProducts ?? []).isNotEmpty) ...[
      // _buildBikesSection(_data!.inventorySummary!.popularProducts!),
      // SizedBox(height: SizeConfig.size16),
      // ],
      _buildLivePhotosSection(),
      SizedBox(height: SizeConfig.size12),
      _buildGallerySection(),
      SizedBox(height: SizeConfig.size12),
      _buildTestimonialsSection(),
      // SizedBox(height: SizeConfig.size12),
      _buildContactSection(_data?.businessProfile),
      SizedBox(height: SizeConfig.size12),
      Obx(() => Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: WebsiteOverviewCard(
              websiteUrl: _businessController
                  .businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => _businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          )),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: const ProfileShareBanner(),
      ),
      // ── QR Code (mirrors the hospital overview QR card) ──
      Obx(() {
        final details = _businessController.businessProfileDetails.value?.data;
        if (details == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: BusinessQrCodeWidget(
            data: details,
            // Encode the medical deep link so scanning opens the pharmacy
            // directly (`/app/medical/<ownerUserId>` →
            // MedicalPharmacyDetailScreen) instead of the generic profile
            // share-preview. Mirrors the hospital/grocery QR overrides.
            deepLinkOverride:
                medicalBusinessDeepLink(medicalBusinessId: details.userId),
          ),
        );
      }),
      SizedBox(height: SizeConfig.size12),
    ];
  }

  // PRODUCTS TAB — "Add Product" CTA, the Top Selling rail, then the
  // category-with-inventory card. Mirrors `GroceryHomeScreenV2._buildProductsTab()`.
  List<Widget> _buildProductsTab() {
    return [
      GradientAddButton(
        label: AppStrings.addProduct.tr,
        onTap: () =>
            Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute()),
        margin:
            EdgeInsets.only(top: SizeConfig.size10, right: SizeConfig.size12),
      ),
      SizedBox(height: SizeConfig.size16),
      _buildTopSellingSection(),
      _buildMyProductsInline(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  /// Top Selling rail — store-wide products from
  /// `medical-service/inventory/business-products`.
  ///
  /// The endpoint ships grocery's exact response shape on purpose (see
  /// docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so this reuses
  /// grocery's grouping helper and card rather than cloning both.
  ///
  /// Hides entirely when the list is empty — no empty state, matching grocery
  /// and what the guide's §3 tells the backend to expect.
  Widget _buildTopSellingSection() {
    return Obx(() {
      final isLoading = _medicalController
              .fetchMedicalBusinessProductsResponse.value.status ==
          Status.INITIAL;
      final products = _medicalController.medicalBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      // One row per variant comes back, so the same product repeats — group by
      // product id: one card each, tapping opens its variants sheet.
      final grouped = groupBusinessProductsByProduct(products.toList());
      final previewGroups =
          grouped.length > MedicalController.medicalBusinessProductsPreviewLimit
              ? grouped
                  .take(MedicalController.medicalBusinessProductsPreviewLimit)
                  .toList()
              : grouped;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(right: SizeConfig.size12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topSellingSectionHeader(),
                SizedBox(height: SizeConfig.size12),
                SizedBox(
                  height: 225,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : ListView.builder(
                          itemCount: previewGroups.length,
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final group = previewGroups[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              // Align keeps the horizontal ListView's tight
                              // height constraint from stretching the card.
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: 160,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => showGroceryVariantsSheet(
                                      context: context,
                                      productName:
                                          group.product.product?.name ?? '',
                                      productImageUrl:
                                          group.product.productImageUrlOnly,
                                      variants: group.variants,
                                    ),
                                    child: GroceryTopSellingProductCard(
                                      product: group.product,
                                      variants: group.variants,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size16),
        ],
      );
    });
  }

  /// No "View All" CTA: medical has no all-top-selling screen yet (grocery's
  /// chip opens `AllTopSellingGroceryProductsScreen`), so the rail caps at its
  /// preview limit.
  Widget _topSellingSectionHeader() {
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
                AppStrings.topSelling.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.customersFavoritesThisMonth.tr,
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

  /// Category-with-inventory card — the same white shell + accent-bar header +
  /// CTA chip + card grid as `GroceryHomeScreenV2._buildCategoryWithInventorySection()`.
  Widget _buildMyProductsInline() {
    return Obx(() {
      final isLoading = _medicalController.myMedicalCategoryLoading.value;
      // Show exactly what the with-inventory endpoint returns — no level
      // filtering, same as grocery. (The response is already the merchant's
      // inventory categories; here they come back as level 0, and filtering
      // those out left the grid empty.)
      final list = List<MyMedicalSuperCategoryModel>.from(
          _medicalController.myMedicalCategoryList);

      return Container(
        // White-bordered shell wrapping header + grid, matching grocery.
        margin: EdgeInsets.only(right: SizeConfig.size12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categorySectionHeader(),
            SizedBox(height: SizeConfig.size16),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size30),
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (list.isEmpty)
              // Categories keep their empty state (grocery does the same) —
              // unlike Top Selling, an empty catalog is the merchant's cue to
              // add stock, so hiding the section would hide the CTA with it.
              Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
                child: Center(
                  child: EmptyStateWidget(
                    message: AppStrings.medicalHaveNotPostedProducts.tr,
                    actionText: AppStrings.medicalAddProductsNow.tr,
                    actionCallback: () =>  Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute()),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: SizeConfig.size4),
                    itemCount: list.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: SizeConfig.size12,
                      mainAxisSpacing: SizeConfig.size12,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (_, i) => _myProductCategoryCard(list[i]),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  /// Accent bar + title + helper + CTA chip — grocery's `_categorySectionHeader`.
  Widget _categorySectionHeader() {
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
                AppStrings.medicalMyProductsTitle.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.tapCategoryToManageInventory.tr,
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
        _addProductCta(),
      ],
    );
  }

  /// Solid primary `+` badge anchoring a brand-outlined chip — grocery's
  /// `_addGroceryCta`.
  Widget _addProductCta() {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
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
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              AppStrings.addProduct.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Two-tone storefront card — same shell as grocery's `_groceryCategoryCard`:
  // a tinted hero zone (contain image, nothing crops) over a crisp white footer
  // with the name and a small filled brand chevron. Keeps medical's SVG-aware
  // [_categoryImage] for the hero so vector category icons still render.
  //
  // Tapping goes straight to the variant screen for this category — no products
  // list in between. That screen fetches the category's products and flattens
  // every variant into one grid.
  Widget _myProductCategoryCard(MyMedicalSuperCategoryModel item) {
    final hasImage = item.image != null && item.image!.isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);
    final isSvg = hasImage && item.image!.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () => Get.toNamed(
        RouteHelper.getMyMedicalVariantScreenRoute(),
        arguments: {
          ApiKeys.argCategoryId: item.sId,
          ApiKeys.argCategoryName: item.name,
          ApiKeys.argIsShowInGrid: true,
        },
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.10),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: _categoryImage(
                        hasImage: hasImage,
                        isNetwork: isNetwork,
                        isSvg: isSvg,
                        imagePath: item.image ?? '',
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEF1F4), width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10,
                  vertical: SizeConfig.size10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomText(
                        item.name ?? '',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
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

  Widget _categoryImage({
    required bool hasImage,
    required bool isNetwork,
    required bool isSvg,
    required String imagePath,
  }) {
    const double size = 56;
    if (!hasImage) {
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        height: size,
        width: size,
        boxFix: BoxFit.contain,
      );
    }
    if (isNetwork && isSvg) {
      return SvgPicture.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox(
            width: size,
            height: size,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (_, __, ___) =>
            Icon(Icons.broken_image, size: size, color: Colors.grey),
      );
    }
    return LocalAssets(
        imagePath: imagePath,
        height: size,
        width: size,
        boxFix: BoxFit.contain);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // POST TAB â€” embeds FeedScreen filtered to current user's posts.
  // Empty state surfaces a Create-Post CTA.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: _createPostCta(),
      ),
      SizedBox(height: SizeConfig.size12),
      FeedScreen(
        key: const ValueKey('medical_v2_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  Widget _createPostCta() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: CustomText(AppStrings.createPost.tr,
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  /// Dialog with the same post-creation entries as the global app bar:
  /// Lekha, Poll, Symbol, and Job (business only). Routes to existing flows.
  Future<void> _showCreatePostDialog() async {
    final isBusiness = isBusinessUser();
    final entries = <_PostMenuEntry>[
      _PostMenuEntry(
        type: PostCreationMenu.message,
        label: AppStrings.lekha.tr,
        iconAsset: AppIconAssets.message_post,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.symbol,
        label: AppStrings.symbol.tr,
        iconAsset: 'assets/icons/add_symbol_color.png',
      ),
      _PostMenuEntry(
        type: PostCreationMenu.poll,
        label: AppStrings.poll.tr,
        iconAsset: AppIconAssets.qa_ask_questionOutlinedIcon,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.reel,
        label: 'Reel',
        iconAsset: AppIconAssets.video_outline,
      ),
      if (isBusiness)
        _PostMenuEntry(
          type: PostCreationMenu.jobPost,
          label: AppStrings.jobPost.tr,
          iconAsset: AppIconAssets.uilSuitcaseOutlinedIcon,
        ),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.createPost.tr,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size12),
              for (var i = 0; i < entries.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handlePostMenu(entries[i].type);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                        horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(
                            imagePath: entries[i].iconAsset,
                            height: 24,
                            width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostMenu(PostCreationMenu type) {
    switch (type) {
      case PostCreationMenu.message:
      case PostCreationMenu.poll:
      case PostCreationMenu.reel:
        postVia(context, type);
        break;
      case PostCreationMenu.jobPost:
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(), arguments: {
          'isEditMode': false,
          'jobId': '',
          'createJobVia': 'business',
        });
        break;
      case PostCreationMenu.symbol:
        Get.to(() => AddChatSymbolScreen());
        break;
    }
  }

  // CREATE OFFERS BUTTON (overview tab)
  Widget _buildCreateOffersButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _onCreateOffer,
          icon: const Icon(Icons.local_offer_outlined,
              size: 18, color: Colors.white),
          label: CustomText(AppStrings.createYourOffers.tr,
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _onCreateOffer() {
    commonSnackBar(message: AppStrings.comingSoon.tr);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VERIFY TAB â€” shows verification status; tap to start the flow if pending
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ignore: unused_element
  List<Widget> _buildVerifyTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details =
              _businessController.businessProfileDetails.value?.data;
          final isVerified = details?.businessIsVerified ?? false;

          return Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Get.to(ProfileStatisticsScreen(userId: userId));
                    },
                    child: CustomText(AppStrings.clickMe.tr)),
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.gpp_maybe_outlined,
                      color: isVerified ? AppColors.green00 : AppColors.redLite,
                      size: 28,
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CustomText(
                        isVerified
                            ? AppStrings.verifiedProfile.tr
                            : AppStrings.profileNotVerified.tr,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    BusinessVerifyNowButton(details: details),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                CustomText(
                  isVerified
                      ? AppStrings.profileVerifiedHint.tr
                      : AppStrings.profileNotVerifiedHint.tr,
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 4,
                ),
                if (!isVerified) ...[
                  SizedBox(height: SizeConfig.size12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => BusinessVerification()),
                      icon: const Icon(Icons.verified_outlined,
                          size: 18, color: Colors.white),
                      label: CustomText(AppStrings.startVerification.tr,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    // Glassmorphic header — mirrors GroceryHomeScreenV2: a frosted translucent
    // white bar (over the pattern background) with a hairline white border and
    // an outer shadow, instead of the old solid blue gradient.
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can ellipsize
                // instead of pushing the row past its width.
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                    icon: Icons.notifications_none, onTap: _openNotifications),
                SizedBox(width: SizeConfig.size6),
                _goLivePill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        onTap: handleGoLiveTap,
      ),
    );
  }

  /// Drive the Go-Live toggle. Turning ON opens the shop-availability
  /// (set-time) form directly — no permission gate. The form persists the
  /// hours and goes live via the backend, popping back `true` on success.
  /// Turning OFF just flips the local toggle.
  Future<void> handleGoLiveTap() async {
    // The pill reflects the schedule-driven auto open/close state; tapping
    // opens the shop-status control — first run routes to the weekly hours
    // editor, thereafter the status sheet (with the today-only override).
    await _businessController.openAvailabilityControl();
  }

  // PROFILE ROW
  Widget _buildProfileRow(BusinessProfile? profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Obx(() {
                final logo =
                    _businessController.imagePath?.value ?? profile?.logo ?? '';
                return Container(
                  height: SizeConfig.size40,
                  width: SizeConfig.size40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _logoFallback(),
                        )
                      : _logoFallback(),
                );
              }),
              // Positioned(
              //   right: -10,
              //   top: 6,
              //   child: Container(
              //     height: SizeConfig.size30,
              //     width: SizeConfig.size30,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: Colors.red.shade600,
              //       border: Border.all(color: Colors.white, width: 2),
              //     ),
              //   ),
              // ),
            ],
          ),
          SizedBox(width: SizeConfig.size20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        profile?.businessName ?? '',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomText('+1',
                          fontSize: 11, color: AppColors.secondaryTextColor),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                CustomText(
                  profile?.typeOfBusiness ?? '',
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Obx(() => BusinessVerifyNowButton(
                details: _businessController.businessProfileDetails.value?.data,
              )),
          SizedBox(width: SizeConfig.size10),
          IconButton(
            onPressed: _previewProfileAsVisitor,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.storefront,
            size: 20, color: AppColors.secondaryTextColor),
      );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TABS CARD (single white card with pills)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BANNER (cover image)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBannerSection(BusinessProfile? profile) {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size12),
      child: Obx(() {
        final cover = _businessController.coverImage?.value ?? '';
        final hasBanner = cover.isNotEmpty;

        return GestureDetector(
          onTap: () => _onEditCover(profile),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.hardEdge,
              child: hasBanner
                  ? _filledBannerContent(cover)
                  : _emptyBannerContent(),
            ),
          ),
        );
      }),
    );
  }

  Widget _emptyBannerContent() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: SizeConfig.size12,
            bottom: SizeConfig.size12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined,
                    size: 20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText(AppStrings.otherAddYourBannerHere.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filledBannerContent(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade100),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
        Positioned(
          right: SizeConfig.size10,
          bottom: SizeConfig.size10,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                CustomText(AppStrings.edit,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onEditCover(BusinessProfile? profile) async {
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture.tr,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      _businessController.coverImage?.value = newPath;
      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage =
          await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed.tr);
        return;
      }
      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: profile?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (e) {
      commonSnackBar(message: AppStrings.updatePictureFailed.tr);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BIKES / POPULAR PRODUCTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBikesSection(List<PopularProduct> products) {
    final cardWidth = MediaQuery.of(context).size.width * 0.55;
    return _SectionCard(
      title: AppStrings.bikesTitle.tr,
      trailingLabel: AppStrings.update.tr,
      onTrailingTap: () {},
      child: SizedBox(
        height: cardWidth * 1.05,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
          itemCount: products.length,
          separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
          itemBuilder: (_, i) => _bikeCard(products[i], cardWidth),
        ),
      ),
    );
  }

  Widget _bikeCard(PopularProduct item, double width) {
    final productName = item.product?.name ?? item.variant?.variantName ?? '';
    final description = item.product?.description ?? '';
    final imageUrl = item.product?.images?.firstOrNull?.url ??
        item.variant?.images?.firstOrNull?.url;
    final mrp = item.batches?.mrp ?? item.variant?.pricing?.firstOrNull?.mrp;
    final sellingPrice = item.batches?.sellingPrice ??
        item.variant?.pricing?.firstOrNull?.sellingPrice;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_outlined, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.image_outlined, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(productName,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 2),
                if (description.isNotEmpty)
                  CustomText(description,
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    _spec(item.category?.name ?? AppStrings.petrolFallback.tr),
                    SizedBox(width: SizeConfig.size4),
                    _spec(item.variant?.unit ?? AppStrings.sportsFallback.tr),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _priceCol(
                        AppStrings.exShowroomPrice.tr, mrp ?? sellingPrice),
                    _priceCol(AppStrings.onRoadPrice.tr, sellingPrice ?? mrp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _spec(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(text, fontSize: 9, color: AppColors.secondaryTextColor),
    );
  }

  Widget _priceCol(String label, num? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 9, color: AppColors.secondaryTextColor),
        CustomText('â‚¹${value ?? '-'}',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUSINESS LIVE PHOTOS (with floating edit FAB)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLivePhotosSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SectionCard(
          title: AppStrings.businessLivePhotos.tr,
          child: GetBuilder<ViewBusinessDetailsController>(
            id: 'livePhotos',
            builder: (_) {
              final photos = _businessController
                      .businessProfileDetails.value?.data?.livePhotos ??
                  [];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, index) {
                  final hasPhoto =
                      index < photos.length && photos[index].isNotEmpty;
                  return _LivePhotoSlot(
                    index: index,
                    photoUrl: hasPhoto ? photos[index] : null,
                    label: _slotLabel(index),
                    placeholderImage: _slotPlaceholder(index),
                    allPhotos: photos,
                    controller: _businessController,
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          top: SizeConfig.size60,
          child: Container(
            height: SizeConfig.size40,
            width: SizeConfig.size40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }

  String _slotLabel(int index) {
    switch (index) {
      case 0:
        return AppStrings.slotRoadSideImage.tr;
      case 1:
        return AppStrings.slotReceptionCounter.tr;
      case 2:
        return AppStrings.slotInteriorOne.tr;
      case 3:
      default:
        return AppStrings.slotInteriorTwo.tr;
    }
  }

  String _slotPlaceholder(int index) {
    switch (index) {
      case 0:
        return AppImageAssets.storefrontExterior;
      case 1:
        return AppImageAssets.billingCounterReceptionArea;
      case 2:
        return AppImageAssets.interiorInsideShop;
      case 3:
      default:
        return AppImageAssets.productServiceDisplay;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // GALLERY (2x2 grid)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildGallerySection() {
    return Obx(() {
      final all = <String>[];
      for (final entry in _galleryController.galleryList) {
        all.addAll(entry.imageUrls ?? []);
      }
      return _SectionCard(
        title: AppStrings.gallery.tr,
        trailingLabel: AppStrings.addPhoto.tr,
        onTrailingTap: () => Get.to(() => MedicalGalleryListScreen()),
        child: all.isEmpty ? _galleryEmptyGuide() : _galleryGrid(all),
      );
    });
  }

  /// Empty-gallery guide â€” black & white preview image overlaid with
  /// add-photo CTA so the user understands what the section will look like.
  Widget _galleryEmptyGuide() {
    return GestureDetector(
      onTap: () => Get.to(() => MedicalGalleryListScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.asset(
                  'assets/images/other_gallery.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(AppStrings.medicalAddPhotos.tr,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WhatsApp-style preview:
  ///   1 image  â†’ full
  ///   2 images â†’ side-by-side
  ///   3 images â†’ 1 large left + 2 stacked right
  ///   4 images â†’ 2Ã—2
  ///   5+       â†’ 2Ã—2 with `+N` overlay on the 4th cell
  Widget _galleryGrid(List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer.tr,
            appBarTitle: AppStrings.imageViewer.tr,
            imageUrls: images,
            initialIndex: i,
          ),
        );

    Widget tile(int i, {bool overlay = false}) => GestureDetector(
          onTap: () => open(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(display[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        )),
                if (overlay && extra > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );

    // 1 image â€” full
    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }

    // 2 images â€” side by side
    if (display.length == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(child: tile(1)),
        ]),
      );
    }

    // 3 images â€” 1 large left + 2 stacked right
    if (display.length == 3) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]),
      );
    }

    // 4+ images â€” 2x2 grid, with +N overlay on last cell when more
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: gap),
              Expanded(child: tile(3, overlay: extra > 0)),
            ]),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TESTIMONIALS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTestimonialsSection() {
    final list = _data?.testimonials ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        children: [
          CustomText(AppStrings.testimonialsTitle.tr,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size12),
          Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _testimonialCard(list.first),
          ),
        ],
      ),
    );
  }

  Widget _testimonialCard(dynamic raw) {
    final m = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final text =
        (m['testimonial'] ?? m['text'] ?? m['message'] ?? '').toString();
    final name = (m['name'] ?? m['author'] ?? '').toString();
    final role = (m['role'] ?? m['designation'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, color: AppColors.primaryColor, size: 18),
            SizedBox(width: SizeConfig.size6),
            Expanded(
              child: CustomText(text,
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    CustomText('-$name',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  if (role.isNotEmpty)
                    CustomText(role,
                        fontSize: 11, color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16, vertical: SizeConfig.size4),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: CustomText(AppStrings.reply.tr,
                  fontSize: 12, color: AppColors.mainTextColor),
            ),
          ],
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CONTACT US
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildContactSection(BusinessProfile? profile) {
    if (profile == null) return const SizedBox.shrink();
    final loc = profile.businessLocation;
    final phone = profile.businessNumber?.formattedMobile;
    final owner = profile.ownerDetails?.firstOrNull;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(AppStrings.contactUsTitle.tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
                SizedBox(height: SizeConfig.size12),
                if (profile.logo != null && profile.logo!.isNotEmpty)
                  Container(
                    width: SizeConfig.size60,
                    height: SizeConfig.size60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                      image: DecorationImage(
                        image: NetworkImage(profile.logo!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: SizeConfig.size10),
                CustomText(profile.businessName ?? '',
                    fontSize: 15, fontWeight: FontWeight.w700),
                if (profile.businessDescription?.isNotEmpty ?? false) ...[
                  SizedBox(height: SizeConfig.size4),
                  CustomText(profile.businessDescription!,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                Divider(height: SizeConfig.size20),
                if (profile.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.website_click, profile.websiteUrl!,
                      AppColors.primaryColor),
                if (owner?.name?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.principal, owner!.name!, Colors.grey[700]!),
                if (owner?.email?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.email, owner!.email!,
                      AppColors.secondaryTextColor),
                if (phone != null)
                  _contactItem(AppIconAssets.phone_outline, phone,
                      AppColors.secondaryTextColor),
                if (profile.address?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.location_new, profile.address!,
                      Colors.grey[700]!),
              ],
            ),
          ),
          if (loc?.lat != null && loc?.lon != null) ...[
            SizedBox(height: SizeConfig.size12),
            BusinessLocationWidget(
              locationText: "",
              latitude: loc!.lat!,
              longitude: loc.lon!,
              businessName: profile.businessName ?? "",
              padding: 0,
              isTitleShow: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalAssets(
              imagePath: icon, imgColor: iconColor, height: 16, width: 16),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(label,
                fontSize: 12,
                color: AppColors.mainTextColor,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Opens the Discover-style profile preview so the owner can see the
  /// public profile the way other users discover it on the Discover screen.
  void _previewProfileAsVisitor() {
    final profile = _data?.businessProfile;
    final coverFromCtrl = _businessController.coverImage?.value ?? '';
    final logoFromCtrl = _businessController.imagePath?.value ?? '';

    // Collect gallery image URLs from the gallery controller (same source the
    // overview Gallery section uses).
    final galleryPhotos = <String>[];
    for (final entry in _galleryController.galleryList) {
      galleryPhotos.addAll(entry.imageUrls ?? []);
    }

    final service = ServiceData()
      ..id = profile?.id ?? widget.businessId
      ..name = profile?.businessName
      ..profileImage = (coverFromCtrl.isNotEmpty
          ? coverFromCtrl
          : (logoFromCtrl.isNotEmpty ? logoFromCtrl : (profile?.logo ?? '')))
      ..bio = profile?.businessDescription
      ..address = profile?.address
      ..rating = profile?.avgRating
      ..reviewCount = int.tryParse(profile?.totalRatings ?? '') ?? 0
      ..category = profile?.typeOfBusiness
      ..serviceMedia = ServiceMedia(photos: galleryPhotos);

    Get.to(() => SelfEmployeeViewDiscoverScreen(
          service: service,
          isSelfPreview: true,
        ));
  }
}

class _PostMenuEntry {
  final PostCreationMenu type;
  final String label;
  final String iconAsset;

  const _PostMenuEntry({
    required this.type,
    required this.label,
    required this.iconAsset,
  });
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SHARED SECTION CARD WRAPPER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
                if (trailingLabel != null)
                  GestureDetector(
                    onTap: onTrailingTap,
                    child: CustomText(trailingLabel!,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor),
                  ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            child,
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LIVE PHOTO SLOT
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LivePhotoSlot extends StatefulWidget {
  final int index;
  final String? photoUrl;
  final String label;
  final String placeholderImage;
  final List<String> allPhotos;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.photoUrl,
    required this.label,
    required this.placeholderImage,
    required this.allPhotos,
    required this.controller,
  });

  @override
  State<_LivePhotoSlot> createState() => _LivePhotoSlotState();
}

class _LivePhotoSlotState extends State<_LivePhotoSlot> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              if (hasPhoto) {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: AppStrings.imageViewer.tr,
                    subTitle: '',
                    imageUrls: widget.allPhotos,
                    initialIndex: widget.index,
                  ),
                );
              } else {
                final imgStr = await PhotoPickerService.pickFromCamera(
                  context,
                  cropAspectRatio: CropAspectRatio(width: 1, height: 1),
                );
                if (imgStr != null) {
                  setState(() => _isLoading = true);
                  await widget.controller
                      .saveBusinessImages(imgStr, widget.controller);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => _placeholderError(),
                    )
                  : _blurredPlaceholder(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: CustomText(
                widget.label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (!hasPhoto && !_isLoading)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 18,
                    width: 18,
                    imgColor: Colors.white,
                  ),
                ),
              ),
            ),
          if (hasPhoto && !_isLoading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () async {
                  setState(() => _isLoading = true);
                  final data = {ApiKeys.image_url: widget.photoUrl};
                  await widget.controller.deleteLiveStoreImage(data);
                  widget
                      .controller.businessProfileDetails.value?.data?.livePhotos
                      ?.removeAt(widget.index);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blurredPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.placeholderImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
