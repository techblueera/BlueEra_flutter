import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';

class AllProfessionConsultantScreen extends StatefulWidget {
  final List<ProfessionTypeData> professionalConsultantCategories;
  final ProfessionTypeData? selectedProfessionConsultantData;

  const AllProfessionConsultantScreen(
      {super.key,
      required this.professionalConsultantCategories,
      this.selectedProfessionConsultantData});

  @override
  State<AllProfessionConsultantScreen> createState() =>
      _AllProfessionConsultantScreenState();
}

class _AllProfessionConsultantScreenState
    extends State<AllProfessionConsultantScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<ProfessionTypeData> _professionalConsultantCategories;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/business-people-casual-meeting_53876-101882.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-diverse-people-having-business-meeting_53876-25060.jpg?w=1380",
    "https://img.freepik.com/free-photo/side-view-woman-working-as-lawyer_23-2151202449.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    final selected = widget.selectedProfessionConsultantData;
    controller.selectedProfessionalConsultantData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    controller.fetchProfessionalConsultantServices();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.fetchProfessionalConsultantServices(isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._professionalConsultantCategories.map((c) => StickyCategory(
        id: c.tagId ?? '',
        name: c.name ?? '',
        imageUrl: getIndividualProfessionIcon(c.tagId).isNotEmpty
            ? getIndividualProfessionIcon(c.tagId)
            : c.imageUrl ?? '',
      )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor:
                        AppColors.blue5CAF.withValues(alpha: 0.1),
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
                    categories: stickyCategories,
                    selectedId: controller.selectedProfessionalConsultantData.value?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      if (item.id == 'ALL_OPTION') {
                        controller.selectedProfessionalConsultantData.value = null;
                      } else {
                        controller.selectedProfessionalConsultantData.value = OnboardingCategoryModel(
                          name: item.name,
                          slugId: item.id,
                          accountType: AppConstants.individual,
                        );
                      }
                      controller.fetchProfessionalConsultantServices();
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
              body: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: rightContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BookViaBlueEraPartnerBanner(onTap: () {}),
              HorizontalTabSelector<CategoryFilter>(
                tabs: controller.filters,
                selectedIndex:
                    controller.filters.indexOf(controller.selectedFilter.value),
                horizontalMargin: 0.0,
                verticalMargin: 0.0,
                onTabSelected: (index, _) {
                  final selectedEnum = controller.filters[index];
                  if (controller.selectedFilter.value == selectedEnum) return;
                  controller.selectedFilter.value = selectedEnum;
                },
                labelBuilder: (r) => r.localizedLabel,
                unSelectedBackgroundColor: AppColors.white,
              ),
              SizedBox(height: SizeConfig.size5),
              Expanded(
                child: Obx(() {
                  if (controller.isProfConServiceLoading.value &&
                      controller.professionalConsDataList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.professionalConsDataList.isEmpty) {
                    return Center(
                        child: EmptyStateWidget(message: AppStrings.noServicesFound.tr));
                  }

                  return ListView.builder(
                      itemCount: controller.professionalConsDataList.length +
                          (controller.isProfConServiceLoadingMore.value ? 1 : 0),
                      padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                      itemBuilder: (context, index) {
                        if (index == controller.professionalConsDataList.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return selfProfessionCard(
                            controller.professionalConsDataList[index]);
                      });
                }),
              )
            ],
          ),
        ));
  }

  Widget selfProfessionCard(ProfessionalConsData service) {

    // Price
    final priceData = service.pricing?.amount;
    final isRange = service.pricing?.type == 'range';

    String priceDisplay;
    if (isRange) {
      final min = priceData ?? 0;
      final max = priceData ?? 0;
      priceDisplay = "₹${formatIndianNumber(min)}-${formatIndianNumber(max)}";
    } else {
      priceDisplay = "₹${formatIndianNumber(priceData ?? 0)}";
    }

    Color badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    String badgeText = service.pricing?.type.toString().capitalizeFirst ?? '';

    return InkWell(
      onTap: (){
        Get.to(DiscoverProfessionalsViewScreen(professionalConsData:service ,));
      },
      child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedAvatarWidget(
                    imageUrl: service.userDetails?.profileImage ?? '',
                    size: SizeConfig.size40,
                    borderColor: Colors.white,
                    borderRadius: SizeConfig.size20,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.userDetails?.name ?? AppStrings.unknownUser.tr,
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      // SizedBox(height: SizeConfig.size6),
                      CustomText(
                        service.basicDetails?.shortTagline ?? 'N/A',
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.mainTextColor,
                      ),
                      // CommonRatingRow(
                      //   rating: double.tryParse(service.rating.toString()) ?? 0.0,
                      //   reviews: service.reviewCount ?? 0,
                      //   distance: '${service.distance ?? 0} KM',
                      // )
                    ],
                  )),
                  // Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),

              SizedBox(height: SizeConfig.size6),

              // ─── Gallery Photos / Profile Picture ───
              if (service.gallery?.signedUrls?.isNotEmpty == true) ...[
                StoreLivePhotoWidget(
                  livePhotos: service.gallery!.signedUrls!,
                  natureOfBusiness: service.userDetails?.profession ?? 'Consultant',
                  height: 200,
                  onViewFullScreen: ({
                    required int index,
                    required List<String> storeImage,
                    required String natureOfBusiness,
                  }) {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: natureOfBusiness,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: storeImage,
                        initialIndex: index,
                      ),
                    );
                  },
                ),
                SizedBox(height: SizeConfig.size6),
              ] else if ((service.userDetails?.profileImage ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: service.userDetails?.profession ?? 'Consultant',
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: [service.userDetails!.profileImage!],
                        initialIndex: 0,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: service.userDetails!.profileImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      memCacheHeight: 600,
                      placeholder: (_, __) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),
                      errorWidget: (_, __, ___) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
              ],

              /*  (service.certificates != null &&
                      (service.certificates?.isNotEmpty ?? false))
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          SizedBox(height: SizeConfig.size6),
                          ...List.generate(
                            service.certificates?.take(2).length ?? 0,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 6.0, right: 8.0),
                                    width: 4.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryTextColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      service.certificates?[index].title,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: SizeConfig.size6),
                        ])
                  : SizedBox(),*/

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    CustomText(
                      "${service.pricing?.consultationMode??"N/A"}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.green00,
                    ),
                    // CustomText(
                    //   timingMap["start"]!,
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   overflow: TextOverflow.ellipsis,
                    //   color: AppColors.secondaryTextColor,
                    //   maxLines: 1,
                    // ),
                    // CustomText(
                    //   ' | ',
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   color: AppColors.secondaryTextColor,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // CustomText(
                    //   "${AppStrings.close.tr}: ",
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   overflow: TextOverflow.ellipsis,
                    //   color: AppColors.redB4,
                    //   maxLines: 1,
                    // ),
                    // CustomText(
                    //   timingMap["end"]!,
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   color: AppColors.grayText,
                    //   overflow: TextOverflow.ellipsis,
                    //   maxLines: 1,
                    // ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.size8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    priceDisplay,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: badgeColor,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size4,
                      vertical: SizeConfig.size2,
                    ),
                    child: CustomText(
                      badgeText,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      final targetUserId = service.userId ?? '';
                      if (targetUserId.isEmpty) return;
                      final chatViewController = getOrPut(() => ChatViewController());

                      chatViewController.checkChatConnectionAndOpenChat(

                          userId:  service.userId??""

                      );
                      // Get.to(() => PersonalChatScreen(
                      //       conversationId: '',
                      //       userId: targetUserId,
                      //       profileImage:
                      //           service.userDetails?.profileImage ?? '',
                      //       name: service.userDetails?.name ?? '',
                      //       type: AppConstants.personal_Chat_Type,
                      //       isInitialMessage: true,
                      //     ));
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_outlined,
                              size: 14, color: AppColors.white),
                          const SizedBox(width: 4),
                          CustomText(
                            'Enquire',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  void showFullProfessionDetails(
    ProfessionalConsData service, {
    // required Map<String, String> timingMap,
    required String priceDisplay,
    required String priceBadgeText,
    required Color priceBadgeColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),

                _header(context),

                const SizedBox(height: 4),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigate to details
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                imageUrl:
                                    service.basicDetails?.profilePhotoUrl ?? '',
                                width: SizeConfig.screenWidth,
                                height: SizeConfig.size150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.size150,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: SizeConfig.size150 / 2),
                              ),
                            ),
                            Positioned(
                                left: 20,
                                bottom: -(SizeConfig.size34),
                                child: Container(
                                  padding: EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle),
                                  child: CachedAvatarWidget(
                                    imageUrl:
                                        service.basicDetails?.profilePhotoUrl ??
                                            '',
                                    size: SizeConfig.size65,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size60,
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(
                                  service.basicDetails?.fullName ?? ' User',
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              width: SizeConfig.size8,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size3,
                                horizontal: SizeConfig.size10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: AppColors.secondaryTextColor,
                                    width: 0.5),
                              ),
                              child: CustomText(
                                  service.basicDetails?.professionalTitle,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: ExpandableText(
                          text: "${service.basicDetails?.shortTagline ?? ''}",
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Price
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        '${AppStrings.price.tr}: ',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        priceDisplay,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: priceBadgeColor,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size4,
                          vertical: SizeConfig.size2,
                        ),
                        child: CustomText(
                          priceBadgeText,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      )
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                /* // Timing
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.timingLabel,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            CustomText(
                              "${AppStrings.open.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.green00,
                            ),
                            CustomText(
                              timingMap["start"]!,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                            ),
                            CustomText(
                              ' | ',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            CustomText(
                              "${AppStrings.close.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.redB4,
                              maxLines: 1,
                            ),
                            CustomText(
                              timingMap["end"]!,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grayText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),*/

                SizedBox(height: SizeConfig.size15),

                // Service Description
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.serviceDescription,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.certificates != null &&
                              (service.certificates?.isNotEmpty ?? false))
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  SizedBox(height: SizeConfig.size6),
                                  ...List.generate(
                                    service.certificates?.take(2).length ?? 0,
                                    (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 6.0, right: 8.0),
                                            width: 4.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.secondaryTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              service
                                                  .certificates?[index].title,
                                              fontSize: SizeConfig.small,
                                              color:
                                                  AppColors.secondaryTextColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: SizeConfig.size6),
                                ])
                          : SizedBox(),
                      /* (service.service != null &&
                              service.service!.facilities != null &&
                              service.service!.facilities!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.service!.facilities!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 6.0, right: 8.0),
                                        width: 4.0,
                                        height: 4.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryTextColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          service.service!.facilities![index],
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomText(
                              'No Description available',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),*/
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Work Experience
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.workExperience,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.about?.totalExperience?.years != null &&
                              service.about?.totalExperience?.years != 0)
                          ? CustomText(
                              "${service.about?.totalExperience?.years ?? 0} ${AppStrings.yearsExp.tr}",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            )
                          : CustomText(
                              AppStrings.noExperienceLabel,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Expertise
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.portfolioLabel,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.portfolio != null &&
                              service.portfolio!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.portfolio!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(
                                                top: 6.0, right: 8.0),
                                            width: 4.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.secondaryTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              service.portfolio?[index]
                                                  .projectTitle,
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CustomText(
                                        service.portfolio?[index].description,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomText(
                              AppStrings.noDataLabel,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Gallery
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.gallery,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.gallery != null &&
                              service.gallery?.signedUrls != null &&
                              (service.gallery?.signedUrls?.isNotEmpty ??
                                  false))
                          ? Builder(builder: (context) {

                              // Split into rows of 4
                              final rows = <String>[];
                              rows.addAll(service.gallery?.signedUrls ?? []);
                              // for (int i = 0;
                              //     i < (service.gallery?.signedUrls?.length??0);
                              //     i += crossAxisCount) {
                              //   rows.add(
                              //     service.gallery?.signedUrls?.sublist(
                              //       i,
                              //       (i + crossAxisCount).clamp(0,
                              //           service.serviceMedia!.photos!.length),
                              //     ),
                              //   );
                              // }
                              return Wrap(
                                children: List.generate(rows.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                      child: CachedNetworkImage(
                                        imageUrl: rows[index],
                                        width: SizeConfig.size80,
                                        height: SizeConfig.size80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: SizeConfig.size80,
                                          height: SizeConfig.size80,
                                          color: Colors.grey[300],
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.person,
                                                size: SizeConfig.size80 / 2),
                                      ),
                                    ),
                                  );
                                }),
                              );
                              /*  return Column(
                                children:
                                    List.generate(rows.length, (rowIndex) {
                                  final rowItems = rows[rowIndex];
                                  logs("rowItems=== ${rowItems}");

                                  final isLastRow = rowIndex == rows.length - 1;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            isLastRow ? 0 : mainAxisSpacing),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: List.generate(
                                          crossAxisCount * 2 - 1, (i) {
                                        if (i.isEven) {
                                          final itemIndex = i ~/ 2;

                                          if (itemIndex < rowItems.length) {
                                            final photos = rowItems[itemIndex];

                                            return Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            10.0)),
                                                child: CachedNetworkImage(
                                                  imageUrl: photos,
                                                  width: SizeConfig.size80,
                                                  height: SizeConfig.size80,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: SizeConfig.size80,
                                                    height: SizeConfig.size80,
                                                    color: Colors.grey[300],
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.person,
                                                              size: SizeConfig
                                                                      .size80 /
                                                                  2),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return const Expanded(
                                                child: SizedBox.shrink());
                                          }
                                        } else {
                                          return SizedBox(
                                              width: SizeConfig.size8);
                                        }
                                      }),
                                    ),
                                  );
                                }),
                              );*/
                            })
                          : CustomText(
                              AppStrings.noPhotosAvailableMsg,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  onTap: () {},
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: AppStrings.requestBooking.tr,
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          const Expanded(
            child: CustomText(
              AppStrings.allVariants,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}
