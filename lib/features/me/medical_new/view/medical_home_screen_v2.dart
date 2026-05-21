import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_verfication.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_screen.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart' show ApiKeys;
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/my_medical_super_category_model.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_gallery/medical_gallery_list_screen.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Medical Home screen (v2) — redesigned to match IMG-3 reference.
class MedicalHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const MedicalHomeScreenV2({super.key, required this.businessId});

  @override
  State<MedicalHomeScreenV2> createState() => _MedicalHomeScreenV2State();
}

class _MedicalHomeScreenV2State extends State<MedicalHomeScreenV2> {
  MedicalHomeResponseModel? _data;
  bool _isLoading = true;
  bool _isGoLive = false;
  // Default landing tab unchanged: Overview. The previous code used index
  // `1` for Overview; after inserting `Inquiry` at index `0`, every other
  // tab shifts by `+1`, so Overview is now `2`.
  int _selectedTab = 2;

  late final MedicalGalleryController _galleryController;
  late final MedicalController _medicalController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab — same controller
  // the Connect screen uses, so socket-driven updates land on both.
  // Mirrors the wiring used by `HospitalHomeScreenV2`, `SchoolHomeScreenV2`
  // and the Order tab in `professionals_main.dart`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Pre-registered so the Flagged sub-tab inside `BusinessChatsList`
  // (`BusinessFlagChatList` → `Get.find<ChatFlagController>()`) doesn't
  // crash when this is the first screen the user touches. Mirrors the
  // top-level registration in `connect_main_page.dart`.
  // ignore: unused_field
  final ChatFlagController _chatFlagController =
      getOrPut(() => ChatFlagController());

  bool _productsFetched = false;

  static const _tabs = [
    'Inquiry',
    'Order',
    'Overview',
    'Products',
    'Post',
    'Statics'
  ];

  @override
  void initState() {
    super.initState();
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
  }

  void _ensureProductsLoaded() {
    if (_productsFetched) return;
    _productsFetched = true;
    _medicalController.fetchMyMedicalCategory();
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

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  _buildPatternBackground(),
                  Column(
                    children: [
                      _buildTopBar(),
                      _buildProfileRow(_data?.businessProfile),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: kBottomNavigationBarHeight + 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: SizeConfig.size10),
                              _buildTabsCard(),
                              SizedBox(height: SizeConfig.size12),
                              ..._buildTabContent(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab
  //   0 Inquiry, 1 Order, 2 Overview, 3 Products, 4 Post, 5 Statics
  //
  // Inquiry was inserted at index `0`; every other tab's case shifted
  // by `+1`. The legacy `Order` placeholder still surfaces stats (kept
  // identical to before — same `MedicalStatisticsScreen` body), just
  // at its new index `1` so the existing flow stays intact.
  // ─────────────────────────────────────────────
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildInquiryTab();
      case 2:
        return _buildOverviewSlivers();
      case 3:
        _ensureProductsLoaded();
        return _buildProductsTab();
      case 4:
        return _buildPostTab();
      case 1:
      case 5:
        return [MedicalStatisticsScreen(businessId: userId)];
      default:
        return [_buildComingSoon()];
    }
  }

  // ─────────────────────────────────────────────
  // INQUIRY TAB — incoming inquiries only (chats whose latest message
  // was authored by *someone else*). Mirrors `HospitalInquiryTabV2` /
  // `SchoolInquiryTabV2` and the Order tab in `professionals_main.dart`.
  //
  // `BusinessChatsList` ships an Expanded `ListView` internally, so
  // it must live inside a bounded box; we use a fraction of the
  // screen height to play nicely with the parent SingleChildScrollView.
  // ─────────────────────────────────────────────
  List<Widget> _buildInquiryTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    return [
      SizedBox(
        height: screenHeight * 0.75,
        child: BusinessChatsList(
          isForwardUI: false,
          excludeSenderId: userId,
        ),
      ),
    ];
  }

  List<Widget> _buildOverviewSlivers() {
    return [
      _buildBannerSection(_data?.businessProfile),
      SizedBox(height: SizeConfig.size12),
      _buildCreateOffersButton(),
      SizedBox(height: SizeConfig.size16),
      if ((_data?.inventorySummary?.popularProducts ?? []).isNotEmpty) ...[
        _buildBikesSection(_data!.inventorySummary!.popularProducts!),
        SizedBox(height: SizeConfig.size16),
      ],
      _buildLivePhotosSection(),
      SizedBox(height: SizeConfig.size16),
      _buildGallerySection(),
      SizedBox(height: SizeConfig.size16),
      _buildTestimonialsSection(),
      SizedBox(height: SizeConfig.size16),
      _buildContactSection(_data?.businessProfile),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  List<Widget> _buildProductsTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              AppStrings.medicalMyProductsTitle.tr,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute()),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: CustomText('Add More Product',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: SizeConfig.size10),
      _buildMyProductsInline(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  Widget _buildMyProductsInline() {
    return Obx(() {
      if (_medicalController.myMedicalCategoryLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size30),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final list = List<MyMedicalSuperCategoryModel>.from(
          _medicalController.myMedicalCategoryList);

      if (list.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
          child: Center(
            child: EmptyStateWidget(
              message: AppStrings.medicalHaveNotPostedProducts.tr,
              actionText: AppStrings.medicalAddProductsNow.tr,
              actionCallback: () =>
                  Get.toNamed(RouteHelper.getMedicalCategoryScreenRoute()),
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SizeConfig.size12,
          mainAxisSpacing: SizeConfig.size12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (_, i) => _myProductCategoryCard(list[i]),
      );
    });
  }

  Widget _myProductCategoryCard(MyMedicalSuperCategoryModel item) {
    final hasImage = item.image != null && item.image!.isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);
    final isSvg = hasImage && item.image!.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () => Get.toNamed(
        RouteHelper.getMyMedicalProductsScreenRoute(),
        arguments: {
          ApiKeys.argCategoryId: item.sId,
          ApiKeys.argCategoryName: item.name,
        },
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: _categoryImage(
                      hasImage: hasImage,
                      isNetwork: isNetwork,
                      isSvg: isSvg,
                      imagePath: item.image ?? ''),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      item.name ?? '',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText(
                            AppStrings.medicalViewProducts,
                            fontSize: 11,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  // ─────────────────────────────────────────────
  // POST TAB — embeds FeedScreen filtered to current user's posts.
  // Empty state surfaces a Create-Post CTA.
  // ─────────────────────────────────────────────
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
        label: CustomText('Create Post',
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
                'Create Post',
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

  // ─────────────────────────────────────────────
  // CREATE OFFERS BUTTON (overview tab)
  // ─────────────────────────────────────────────
  Widget _buildCreateOffersButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _onCreateOffer,
          icon: const Icon(Icons.local_offer_outlined,
              size: 18, color: Colors.white),
          label: CustomText('Create Your Offers',
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
    commonSnackBar(message: AppStrings.comingSoon);
  }

  // ─────────────────────────────────────────────
  // VERIFY TAB — shows verification status; tap to start the flow if pending
  // ─────────────────────────────────────────────
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

                ElevatedButton(onPressed: (){
                  Get.to(MedicalStatisticsScreen(businessId: userId));
                }, child: CustomText("Click me")),

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
                            : 'Profile not verified',
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
                      ? 'Your business is verified. Customers can trust your profile and contact you with confidence.'
                      : 'Verify your business to earn the verified badge, gain customer trust, and unlock enhanced visibility.',
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
                      label: CustomText('Start Verification',
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

  Widget _buildComingSoon() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 48, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size10),
            CustomText(AppStrings.comingSoon,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BACKGROUND
  // ─────────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        topInset + SizeConfig.size8,
        SizeConfig.size12,
        SizeConfig.size10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88FF), Color(0xFF0040A0)],
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
          child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
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
        height: SizeConfig.size36,
        width: SizeConfig.size36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.mainTextColor),
      ),
    );
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: () => setState(() => _isGoLive = !_isGoLive),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText('Go live',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    _isGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment:
                    _isGoLive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE ROW
  // ─────────────────────────────────────────────
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
              Positioned(
                right: -10,
                top: 6,
                child: Container(
                  height: SizeConfig.size30,
                  width: SizeConfig.size30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade600,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
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

  // ─────────────────────────────────────────────
  // TABS CARD (single white card with pills)
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == _selectedTab;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size16,
                        vertical: SizeConfig.size6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomText(
                      _tabs[i],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.mainTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BANNER (cover image)
  // ─────────────────────────────────────────────
  Widget _buildBannerSection(BusinessProfile? profile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
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
                CustomText('Add Your Banner Here',
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
                CustomText('Edit',
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
        AppStrings.editCoverPicture,
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
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: profile?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (e) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ─────────────────────────────────────────────
  // BIKES / POPULAR PRODUCTS
  // ─────────────────────────────────────────────
  Widget _buildBikesSection(List<PopularProduct> products) {
    final cardWidth = MediaQuery.of(context).size.width * 0.55;
    return _SectionCard(
      title: 'Bikes',
      trailingLabel: 'Update',
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
                    _spec(item.category?.name ?? 'Petrol'),
                    SizedBox(width: SizeConfig.size4),
                    _spec(item.variant?.unit ?? 'Sports'),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _priceCol('Ex Showroom Price', mrp ?? sellingPrice),
                    _priceCol('On Road Price', sellingPrice ?? mrp),
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
        CustomText('₹${value ?? '-'}',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESS LIVE PHOTOS (with floating edit FAB)
  // ─────────────────────────────────────────────
  Widget _buildLivePhotosSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SectionCard(
          title: 'Business Live Photos',
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
        return 'Road Side Image';
      case 1:
        return 'Reception/Counter';
      case 2:
        return 'Interior 1';
      case 3:
      default:
        return 'Interior 2';
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

  // ─────────────────────────────────────────────
  // GALLERY (2x2 grid)
  // ─────────────────────────────────────────────
  Widget _buildGallerySection() {
    return Obx(() {
      final all = <String>[];
      for (final entry in _galleryController.galleryList) {
        all.addAll(entry.imageUrls ?? []);
      }
      return _SectionCard(
        title: 'Gallery',
        trailingLabel: 'Add Photo',
        onTrailingTap: () => Get.to(() => MedicalGalleryListScreen()),
        child: all.isEmpty ? _galleryEmptyGuide() : _galleryGrid(all),
      );
    });
  }

  /// Empty-gallery guide — black & white preview image overlaid with
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
  ///   1 image  → full
  ///   2 images → side-by-side
  ///   3 images → 1 large left + 2 stacked right
  ///   4 images → 2×2
  ///   5+       → 2×2 with `+N` overlay on the 4th cell
  Widget _galleryGrid(List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
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

    // 1 image — full
    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }

    // 2 images — side by side
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

    // 3 images — 1 large left + 2 stacked right
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

    // 4+ images — 2x2 grid, with +N overlay on last cell when more
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

  // ─────────────────────────────────────────────
  // TESTIMONIALS
  // ─────────────────────────────────────────────
  Widget _buildTestimonialsSection() {
    final list = _data?.testimonials ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        children: [
          CustomText('Testimonials',
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
              child: CustomText('Reply',
                  fontSize: 12, color: AppColors.mainTextColor),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CONTACT US
  // ─────────────────────────────────────────────
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
          CustomText('Contact Us',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size12),
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

    Get.to(() => SelfEmployeeViewScreen(
          service: service,
          timingMap: const {},
          priceDisplay: '',
          priceBadgeText: '',
          priceBadgeColor: AppColors.primaryColor,
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

// ─────────────────────────────────────────────
// SHARED SECTION CARD WRAPPER
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// LIVE PHOTO SLOT
// ─────────────────────────────────────────────
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
                    appBarTitle: AppStrings.imageViewer,
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

/// Stacked-coin glyph used by the "Earn" pill in the gradient header — three
/// overlapping golden discs with a ₹ on the front coin to match the header
/// reference image.
class _CoinStackIcon extends StatelessWidget {
  final double size;
  const _CoinStackIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    final coinDiameter = size * 0.78;
    return SizedBox(
      width: size + 4,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _coin(coinDiameter, const Color(0xFFC9892B)),
          ),
          Positioned(
            left: 3,
            bottom: 4,
            child: _coin(coinDiameter, const Color(0xFFE0A53A)),
          ),
          Positioned(
            left: 6,
            bottom: 8,
            child: _coin(
              coinDiameter,
              const Color(0xFFF4C13B),
              child: const Text(
                '₹',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A4A0A),
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coin(double diameter, Color color, {Widget? child}) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.5),
      ),
      child: child,
    );
  }
}
