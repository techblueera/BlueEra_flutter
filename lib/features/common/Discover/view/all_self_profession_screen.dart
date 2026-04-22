import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─── AllSelfProfessionScreen ───
class AllSelfProfessionScreen extends StatefulWidget {
  final List<ProfessionTypeData> selfEmployedCategories;
  final ProfessionTypeData? selectedSelfProfessionData;

  const AllSelfProfessionScreen({
    super.key,
    required this.selfEmployedCategories,
    this.selectedSelfProfessionData,
  });

  @override
  State<AllSelfProfessionScreen> createState() =>
      _AllSelfProfessionScreenState();
}

class _AllSelfProfessionScreenState extends State<AllSelfProfessionScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<ProfessionTypeData> _selfEmployedCategories;
  final String serviceSubType = 'selfWork';
  final String earnServiceType = AppConstants.service;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/portrait-young-businesswoman-holding-digital-tablet-hand-looking-camera_23-2148176972.jpg?w=1380",
    "https://img.freepik.com/free-photo/man-doing-professional-home-cleaning-service_23-2150359024.jpg?w=1380",
    "https://img.freepik.com/free-photo/female-hairdresser-using-hairbrush-hair-dryer_329181-2084.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    _selfEmployedCategories = widget.selfEmployedCategories;
    final selected = widget.selectedSelfProfessionData;
    controller.selectedEarnServiceData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    controller.fetchEarnServices(
        earnServiceType: earnServiceType, subType: serviceSubType);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._selfEmployedCategories.map((c) => StickyCategory(
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
        backgroundColor: AppColors.appBackgroundColor,
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
                    singleLineLabel: true,
                    selectedId: controller.selectedEarnServiceData.value?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      controller.selectedEarnServiceData.value =
                          item.id == 'ALL_OPTION' ? null : OnboardingCategoryModel(
                            name: item.name,
                            slugId: item.id,
                            accountType: AppConstants.individual,
                          );
                      controller.fetchEarnServices(
                          earnServiceType: earnServiceType, subType: serviceSubType);
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
                verticalMargin: 8.0,
                onTabSelected: (index, _) {
                  final selectedEnum = controller.filters[index];
                  if (controller.selectedFilter.value == selectedEnum) return;
                  controller.selectedFilter.value = selectedEnum;
                },
                labelBuilder: (r) => r.localizedLabel,
                unSelectedBackgroundColor: AppColors.white,
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isEarnServiceLoading.value &&
                      controller.earnServiceList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.earnServiceList.isEmpty) {
                    return Center(
                        child: EmptyStateWidget(message: AppStrings.noServicesFound.tr));
                  }
                  return ListView.builder(
                    itemCount: controller.earnServiceList.length +
                        (controller.isEarnServiceLoadingMore.value ? 1 : 0),
                    padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                    itemBuilder: (context, index) {
                      if (index == controller.earnServiceList.length) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return selfProfessionCard(
                          controller.earnServiceList[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        ));
  }

  Widget selfProfessionCard(ServiceData service) {
    final timingMap = getMinMaxTimings(service.service?.timings);
    final priceData = service.priceData;
    final isRange = priceData?.priceType == 'range';
    final priceDisplay = isRange
        ? "₹${formatIndianNumber(priceData?.priceRange?.min ?? 0)}-${formatIndianNumber(priceData?.priceRange?.max ?? 0)}"
        : "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
    final badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    final badgeText = priceData?.priceType.toString().capitalizeFirst ?? '';

    return InkWell(
      onTap: () => Get.to(() => SelfProfessionScreenPreview(
            service: service,
            timingMap: timingMap,
            priceDisplay: priceDisplay,
            priceBadgeText: badgeText,
            priceBadgeColor: badgeColor,
          )),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5, width: 0.8),
          boxShadow: [AppShadows.textFieldShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with online indicator
                  Stack(
                    children: [
                      CachedAvatarWidget(
                        imageUrl: service.profileImage ?? '',
                        size: SizeConfig.size44,
                        borderColor: Colors.white,
                        borderRadius: SizeConfig.size22,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: SizeConfig.size8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          service.name ?? AppStrings.unknownUser.tr,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: SizeConfig.size2),
                        CommonRatingRow(
                          rating:
                              double.tryParse(service.rating.toString()) ?? 0.0,
                          reviews: service.reviewCount ?? 0,
                          distance: '${service.distance ?? 0} KM',
                        ),
                      ],
                    ),
                  ),

                  // Price badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size8,
                        vertical: SizeConfig.size4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(priceDisplay,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: badgeColor),
                        CustomText(badgeText,
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: badgeColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Expertise bullets ───
            if (service.service?.expertise?.isNotEmpty == true)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    service.service!.expertise!.take(2).length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 6.0, right: 6.0),
                            child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle)),
                          ),
                          Expanded(
                            child: CustomText(
                              service.service!.expertise![index],
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            SizedBox(height: SizeConfig.size8),

            // ─── Service Media Photos / Profile Picture ───
            if (service.serviceMedia?.photos?.isNotEmpty == true) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: StoreLivePhotoWidget(
                  livePhotos: service.serviceMedia!.photos!,
                  natureOfBusiness: service.profession ?? 'Service',
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
              ),
              SizedBox(height: SizeConfig.size6),
            ] else if ((service.profileImage ?? '').isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: service.profession ?? 'Service',
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: [service.profileImage!],
                        initialIndex: 0,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: service.profileImage!,
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
              ),
              SizedBox(height: SizeConfig.size6),
            ],


            // ─── Footer — timing + action ───
            Container(
              margin: EdgeInsets.only(top: SizeConfig.size8),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.whiteF3,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Timing
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.secondaryTextColor),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          '${timingMap["start"]} - ${timingMap["end"]}',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                  // Book now chip
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                        vertical: SizeConfig.size4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      AppStrings.viewProfile,
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timing helpers ───
  DateTime _parse12HourTime(String timeStr) {
    final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
    final match = format.firstMatch(timeStr.trim());
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);
      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      return DateTime(0, 1, 1, hour, minute);
    }
    return DateTime(0);
  }

  Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
    if (timingsList == null || timingsList.isEmpty)
      return {"start": "--", "end": "--"};
    Timings? earliest = timingsList.first;
    Timings? latest = timingsList.first;
    for (final t in timingsList) {
      if (_parse12HourTime(t.start ?? "00:00 AM")
          .isBefore(_parse12HourTime(earliest?.start ?? "00:00 AM")))
        earliest = t;
      if (_parse12HourTime(t.end ?? "00:00 AM")
          .isAfter(_parse12HourTime(latest?.end ?? "00:00 AM"))) latest = t;
    }
    return {"start": earliest?.start ?? "--", "end": latest?.end ?? "--"};
  }
}
