import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/view/widget/service_provider_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeServiceScreen extends StatefulWidget {
  const HomeServiceScreen({super.key});

  @override
  State<HomeServiceScreen> createState() => _HomeServiceScreenState();
}

class _HomeServiceScreenState extends State<HomeServiceScreen> {
  final controller = getOrPut(() => DiscoverController());
  final List<OnboardingCategoryModel> _homeServicesCategories =
      homeServicesCategories;
  String serviceSubType = 'homeService';
  String earnServiceType = AppConstants.service;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/young-handyman-installing-kitchen-cabinet_155003-37938.jpg?w=1380",
    "https://img.freepik.com/free-photo/medium-shot-woman-cleaning-home_23-2150454566.jpg?w=1380",
    "https://img.freepik.com/free-photo/plumber-man-fixing-kitchen-sink_53876-27.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      clearSelectedCategory();
      controller.fetchEarnServices(
          earnServiceType: earnServiceType, subType: serviceSubType);
    });
  }

  void clearSelectedCategory() {
    controller.selectedEarnServiceData.value = null;
    controller.selectedTabIndex.value = 0;
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
      StickyCategory(
          id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._homeServicesCategories.map((c) => StickyCategory(
            id: c.slugId,
            name: c.name,
            imageUrl: c.icon,
          )),
    ];

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
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                categories: stickyCategories,
                selectedId:
                    controller.selectedEarnServiceData.value?.slugId ??
                        'ALL_OPTION',
                onCategoryTap: (item) {
                  if (item.id == 'ALL_OPTION') {
                    controller.selectedEarnServiceData.value = null;
                  } else {
                    controller.selectedEarnServiceData.value =
                        _homeServicesCategories
                            .firstWhere((c) => c.slugId == item.id);
                  }
                  controller.fetchEarnServices(
                    earnServiceType: earnServiceType,
                    subType: serviceSubType,
                  );
                  setState(() {});
                },
                onBack: () => Navigator.pop(context),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: _buildRightContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildRightContent() {
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
                  if (controller.isEarnServiceLoading.value &&
                      controller.earnServiceList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.earnServiceList.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                          message: AppStrings.noServicesFound.tr),
                    );
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
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _serviceCard(
                          controller.earnServiceList[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        ));
  }

  Widget _serviceCard(ServiceData service) {
    final timingMap = _getMinMaxTimings(service.service?.timings);
    final isOpen = timingMap["start"] != "--";

    final priceData = service.priceData;
    final isRange = priceData?.priceType == 'range';
    String priceDisplay;
    if (isRange) {
      final min = priceData?.priceRange?.min ?? 0;
      final max = priceData?.priceRange?.max ?? 0;
      priceDisplay =
          "₹${formatIndianNumber(min)} - ₹${formatIndianNumber(max)}";
    } else {
      priceDisplay = "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
    }

    final perUnit = priceData?.perUnit;

    return InkWell(
      onTap: () =>
          Get.to(() => ServiceProviderDetailScreen(service: service)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedAvatarWidget(
              imageUrl: service.profileImage ?? '',
              size: SizeConfig.size50,
              borderColor: Colors.white,
              borderRadius: SizeConfig.size25,
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          service.name ?? AppStrings.unknown.tr,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size6,
                            vertical: SizeConfig.size2),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.green00.withValues(alpha: 0.1)
                              : AppColors.redB4.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          isOpen ? AppStrings.open.tr : AppStrings.close.tr,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w500,
                          color: isOpen ? AppColors.green00 : AppColors.redB4,
                        ),
                      ),
                    ],
                  ),
                  if ((service.profession ?? '').isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      service.profession!,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: SizeConfig.size4),
                  CommonRatingRow(
                    rating:
                        double.tryParse(service.rating.toString()) ?? 0.0,
                    reviews: service.reviewCount ?? 0,
                    distance: '${service.distance ?? 0}',
                  ),
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      CustomText(
                        priceDisplay,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      if (perUnit != null && perUnit.isNotEmpty) ...[
                        CustomText(
                          '/$perUnit',
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                      Spacer(),
                      if (isOpen)
                        CustomText(
                          '${timingMap["start"]} - ${timingMap["end"]}',
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.secondaryTextColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Timing helpers ---

  Map<String, String> _getMinMaxTimings(List<Timings>? timingsList) {
    if (timingsList == null || timingsList.isEmpty) {
      return {"start": "--", "end": "--"};
    }

    Timings? earliest = timingsList.first;
    Timings? latest = timingsList.first;

    for (final t in timingsList) {
      final startTime = _parse12HourTime(t.start ?? "00:00 AM");
      final earliestStart =
          _parse12HourTime(earliest?.start ?? "00:00 AM");
      if (startTime.isBefore(earliestStart)) earliest = t;

      final endTime = _parse12HourTime(t.end ?? "00:00 AM");
      final latestEnd = _parse12HourTime(latest?.end ?? "00:00 AM");
      if (endTime.isAfter(latestEnd)) latest = t;
    }

    return {
      "start": earliest?.start ?? "--",
      "end": latest?.end ?? "--",
    };
  }

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
}
