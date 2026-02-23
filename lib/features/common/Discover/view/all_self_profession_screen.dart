import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class AllSelfProfessionScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> selfEmployedCategories;
  final OnboardingCategoryModel? selectedSelfProfessionData;

  const AllSelfProfessionScreen(
      {super.key,
      required this.selfEmployedCategories,
      this.selectedSelfProfessionData});

  @override
  State<AllSelfProfessionScreen> createState() =>
      _AllSelfProfessionScreenState();
}

class _AllSelfProfessionScreenState extends State<AllSelfProfessionScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _selfEmployedCategories;
  final ScrollController scrollController = ScrollController();
  final String serviceSubType = EarnServiceTypes.selfWork.label;
  final String earnServiceType = AppConstants.service;

  @override
  initState() {
    super.initState();
    _selfEmployedCategories = widget.selfEmployedCategories;
    controller.selectedEarnServiceData.value =
        widget.selectedSelfProfessionData;
    controller.fetchEarnServices(
        earnServiceType: earnServiceType, subType: serviceSubType);

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller.fetchEarnServices(
            earnServiceType: earnServiceType,
            subType: serviceSubType,
            isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.paddingM,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: InkWell(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 1.2),
                      boxShadow: [AppShadows.textFieldShadow]),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.franchiseIcon,
                        height: SizeConfig.size30,
                        width: SizeConfig.size30,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomText(AppStrings.bookViaBlueEraPartner,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: SizeConfig.paddingXSL,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(child: rightContent()),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = OnboardingCategoryModel(
      name: 'All',
      slugId: 'ALL_OPTION',
      icon: AppImageAssets.all,
      flagIcon: AppImageAssets.all,
      individualType: IndividualProfileType.SELF_EMPLOYED,
      accountType: AppConstants.individual,
    );

    final fullList = [allItem, ..._selfEmployedCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.flagIcon ?? "",

      // --- SELECTION LOGIC ---
      isSelected: (item) {
        // If checking the "All" item, return true only if controller value is null
        if (item.slugId == 'ALL_OPTION') {
          return controller.selectedEarnServiceData.value == null;
        }
        // Otherwise compare IDs normally
        return controller.selectedEarnServiceData.value?.slugId == item.slugId;
      },

      // --- ON TAP LOGIC ---
      onTap: (item, index) {
        controller.selectedTabIndex.value = index;

        if (item.slugId == 'ALL_OPTION') {
          // "All" logic: Set value to null
          controller.selectedEarnServiceData.value = null;
        } else {
          // Normal logic: Set value to item
          controller.selectedEarnServiceData.value = item;
        }

        // Single API Call (Clean & Shared)
        controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
        );
      },
    );
  }

  // Widget leftCategoryList() {
  //   return Container(
  //     width: 94,
  //     color: AppColors.white,
  //     child: ListView.builder(
  //       // We keep +1 to accommodate the "All" button at the top
  //       itemCount: _selfEmployedCategories.length + 1,
  //       padding: EdgeInsets.only(bottom: SizeConfig.size30),
  //       shrinkWrap: true,
  //       itemBuilder: (context, index) {
  //
  //         // --- CASE 1: The "All" Item (Index 0) ---
  //         if (index == 0) {
  //           return Obx(() => ServiceCategoryItem(
  //             icon: AppImageAssets.all,
  //             label: "All",
  //             selected: controller.selectedEarnServiceData.value == null,
  //             onTap: () {
  //               controller.selectedEarnServiceData.value = null;
  //               controller.selectedTabIndex.value = index;
  //               controller.fetchEarnServices(
  //                   earnServiceType: earnServiceType,
  //                   subType: serviceSubType
  //               );
  //             },
  //           ));
  //         }
  //
  //         // --- CASE 2: Actual Categories (Index 1+) ---
  //         var item = _selfEmployedCategories[index - 1];
  //
  //         return Obx(() => ServiceCategoryItem(
  //           icon: item.flagIcon ?? '',
  //           label: item.name,
  //           selected: controller.selectedEarnServiceData.value?.slugId == item.slugId,
  //           onTap: () {
  //             controller.selectedEarnServiceData.value = item;
  //             controller.selectedTabIndex.value = index;
  //             controller.fetchEarnServices(
  //                 earnServiceType: earnServiceType,
  //                 subType: serviceSubType
  //             );
  //           },
  //         ));
  //       },
  //     ),
  //   );
  // }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: EdgeInsets.only(right: SizeConfig.size8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HorizontalTabSelector<CategoryFilter>(
                tabs: controller.filters,
                selectedIndex:
                    controller.filters.indexOf(controller.selectedFilter.value),
                horizontalMargin: 0.0,
                onTabSelected: (index, _) {
                  final selectedEnum = controller.filters[index];

                  if (controller.selectedFilter.value == selectedEnum) return;

                  controller.selectedFilter.value = selectedEnum;
                  // controller.callApi();
                },
                labelBuilder: (r) => r.label,
                unSelectedBackgroundColor: AppColors.white,
              ),
              SizedBox(
                height: SizeConfig.size5,
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isEarnServiceLoading.value &&
                      controller.earnServiceList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.earnServiceList.isEmpty) {
                    return Center(
                        child: EmptyStateWidget(message: "No services found"));
                  }

                  return ListView.builder(
                      controller: scrollController,
                      itemCount: controller.earnServiceList.length +
                          (controller.isEarnServiceLoadingMore.value ? 1 : 0),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                      itemBuilder: (context, index) {
                        if (index == controller.earnServiceList.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        var service = controller.earnServiceList[index];

                        return selfProfessionCard(service);
                      });
                }),
              )
            ],
          ),
        ));
  }

  Widget selfProfessionCard(ServiceData service) {
    // Timings
    DateTime parse12HourTime(String timeStr) {
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

      return DateTime(0); // fallback
    }

    Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
      if (timingsList == null || timingsList.isEmpty)
        return {"start": "--", "end": "--"};

      Timings? earliest = timingsList.first;
      Timings? latest = timingsList.first;

      for (final t in timingsList) {
        final startTime = parse12HourTime(t.start ?? "00:00 AM");
        final earliestStart = parse12HourTime(earliest?.start ?? "00:00 AM");
        if (startTime.isBefore(earliestStart)) earliest = t;

        final endTime = parse12HourTime(t.end ?? "00:00 AM");
        final latestEnd = parse12HourTime(latest?.end ?? "00:00 AM");
        if (endTime.isAfter(latestEnd)) latest = t;
      }

      return {
        "start": earliest?.start ?? "--",
        "end": latest?.end ?? "--",
      };
    }

    final timingMap = getMinMaxTimings(service.service?.timings);

    // Price
    final priceData = service.priceData;
    final isRange = priceData?.priceType == 'range';

    String priceDisplay;
    if (isRange) {
      final min = priceData?.priceRange?.min ?? 0;
      final max = priceData?.priceRange?.max ?? 0;
      priceDisplay = "₹${formatIndianNumber(min)}-${formatIndianNumber(max)}";
    } else {
      priceDisplay = "₹${formatIndianNumber(priceData?.singlePrice ?? 0)}";
    }

    Color badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    String badgeText = priceData?.priceType.toString().capitalizeFirst ?? '';

    return InkWell(
 onTap: (){
   Get.to(SelfProfessionScreenPreview(service: service,


       timingMap: timingMap,
       priceDisplay: priceDisplay,
       priceBadgeText: badgeText,
       priceBadgeColor: badgeColor,
   ));
 },
      // onTap: () => showFullProfessionDetails(
      //   service,
      //   timingMap: timingMap,
      //   priceDisplay: priceDisplay,
      //   priceBadgeText: badgeText,
      //   priceBadgeColor: badgeColor,
      // ),
      child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      // Navigate to details
                    },
                    child: CachedAvatarWidget(
                      imageUrl: service.profileImage ?? '',
                      size: SizeConfig.size40,
                      borderColor: Colors.white,
                      borderRadius: SizeConfig.size20,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.name ?? 'Unknown User',
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      SizedBox(height: SizeConfig.size6),
                      CommonRatingRow(
                        rating:
                            double.tryParse(service.rating.toString()) ?? 0.0,
                        reviews: service.reviewCount ?? 0,
                        distance: '${service.distance ?? 0} KM',
                      )
                    ],
                  )),
                  Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),

              // if(service.bio?.isNotEmpty??false)
              //   ...[
              //     CustomText(
              //         service.bio ?? 'No description available...',
              //         fontSize: SizeConfig.small,
              //         color: AppColors.secondaryTextColor,
              //         fontWeight: FontWeight.w400
              //     ),
              //     SizedBox(height: SizeConfig.size6),
              //   ],

              (service.service != null &&
                      service.service!.expertise != null &&
                      service.service!.expertise!.isNotEmpty)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          SizedBox(height: SizeConfig.size6),
                          ...List.generate(
                            service.service!.expertise!.take(2).length,
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
                          SizedBox(height: SizeConfig.size6),
                        ])
                  : SizedBox(),

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
                  )
                ],
              ),
            ],
          )),
    );
  }



}

class SelfProfessionScreenPreview extends StatelessWidget {
  const SelfProfessionScreenPreview({super.key, required this.service, required this.timingMap, required this.priceDisplay, required this.priceBadgeText, required this.priceBadgeColor,});
final ServiceData service;
  final Map<String, String> timingMap;
  final String priceDisplay;
  final String priceBadgeText;
  final Color priceBadgeColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "Profession",
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(0),
          child: Column(
            children: [
              const SizedBox(height: 4),

              CommonCardWidget(
                padding: 0,
                child: Container(
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(10.0),
                  //   border: Border.all(color: AppColors.greyE5, width: 0.5),
                  // ),
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
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                imageUrl: service.profileImage ?? '',
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
                                    imageUrl: service.profileImage ?? '',
                                    size: 80,
                                    // size: SizeConfig.size75,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size50,
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(service.name ?? 'Unknown User',
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
                              child: CustomText(service.profession,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      if(service.bio?.isNotEmpty??false)...[
                        SizedBox(
                          height: SizeConfig.size12,
                        ),
                        Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                          child: ExpandableText(
                            text: "${service.bio ?? ''}",
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

                      ],
                      SizedBox(
                        height: SizeConfig.size10,
                      ),

                    ],
                  ),
                ),
              ),


              // Price
              CommonCardWidget(
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


              // Timing
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title: "Timing",
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                      color: AppColors.transparent,
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
              ),


              // Service Description
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title:      'Service Description',
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                      color: AppColors.transparent,
                      height: 0.5,
                      width: SizeConfig.screenWidth,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    (service.service != null &&
                            service.service!.facilities != null &&
                            service.service!.facilities!.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.service!.facilities!.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                          EdgeInsets.only(top: 6.0, right: 8.0),
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
                          ),
                  ],
                ),
              ),


              // Work Experience
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title:   'Work Experience',
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                      color: AppColors.transparent,
                      height: 0.5,
                      width: SizeConfig.screenWidth,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    (service.experiences != null &&
                            service.experiences!.isNotEmpty)
                        ? CustomText(
                            service.experiences![0],
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          )
                        : CustomText(
                            'No Experience',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                  ],
                ),
              ),


              // Expertise
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title: "Expertise",
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                      color: AppColors.transparent,
                      height: 0.5,
                      width: SizeConfig.screenWidth,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    (service.skills != null && service.skills!.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.skills!.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                          EdgeInsets.only(top: 6.0, right: 8.0),
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        service.skills![index],
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
                            'No Skills',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                  ],
                ),
              ),

              // SizedBox(height: SizeConfig.size15),

              // Gallery
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title: "Gallery",
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Container(
                      color: AppColors.transparent,
                      height: 0.5,
                      width: SizeConfig.screenWidth,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    _buildGallery( service.serviceMedia!.photos??[] ,context),
                  /*  (service.serviceMedia != null &&
                            service.serviceMedia!.photos != null &&
                            service.serviceMedia!.photos!.isNotEmpty)
                        ? Builder(builder: (context) {
                            const crossAxisCount = 4;
                            const mainAxisSpacing = 8.0;

                            // Split into rows of 4
                            final rows = <List<String>>[];

                            for (int i = 0;
                                i < service.serviceMedia!.photos!.length;
                                i += crossAxisCount) {
                              rows.add(
                                service.serviceMedia!.photos!.sublist(
                                  i,
                                  (i + crossAxisCount).clamp(
                                      0, service.serviceMedia!.photos!.length),
                                ),
                              );
                            }

                            return Column(
                              children: List.generate(rows.length, (rowIndex) {
                                final rowItems = rows[rowIndex];
                                final isLastRow = rowIndex == rows.length - 1;

                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: isLastRow ? 0 : mainAxisSpacing),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List.generate(
                                        crossAxisCount * 2 - 1, (i) {
                                      if (i.isEven) {
                                        final itemIndex = i ~/ 2;

                                        if (itemIndex < rowItems.length) {
                                          final photos = rowItems[itemIndex];

                                          return Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(10.0)),
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
                                                    (context, url, error) => Icon(
                                                        Icons.person,
                                                        size: SizeConfig.size80 /
                                                            2),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const Expanded(
                                              child: SizedBox.shrink());
                                        }
                                      } else {
                                        return SizedBox(width: SizeConfig.size8);
                                      }
                                    }),
                                  ),
                                );
                              }),
                            );
                          })
                        : CustomText(
                            'No Photos Available',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),*/
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.paddingL),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CustomBtn(
                  onTap: () {},
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: 'Request Booking',
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ),
              SizedBox(height: kBottomNavigationBarHeight,),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGallery(List<String> galleryList, BuildContext context) {
    // Flatten all images
    List<String> allImages = [];
    for (var g in galleryList) {
      allImages.add(g);
        }

    if (allImages.isEmpty) return const SizedBox();

    // Randomize and pick 6
    allImages.shuffle(Random());

    return StaggeredGrid.count(
      // shrinkWrap: true,
      // physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
      List.generate(allImages.length > 10 ? 10 : allImages.length, (index) {
        // Logic to replicate the pattern in your image:
        // Large Vertical (index 0), Two small (index 1,2), Large Horizontal (index 3)...
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;

        if (index % 6 == 0 || index % 6 == 5) {
          // Large Vertical Tiles
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          // Large Full-Width Horizontal Tile
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          // Standard Small Squares
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: AppStrings.imageViewer,
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allImages,
                  initialIndex: index,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                allImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      }),

    );
  }

}
