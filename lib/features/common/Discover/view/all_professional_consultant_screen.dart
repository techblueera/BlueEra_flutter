import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class AllProfessionConsultantScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> professionalConsultantCategories;
  final OnboardingCategoryModel? selectedProfessionConsultantData;

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
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller.selectedProfessionalConsultantData.value =
        widget.selectedProfessionConsultantData;
    controller.fetchProfessionalConsultantServices();

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller.fetchProfessionalConsultantServices(isLoadMore: true);
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
      individualType: IndividualType.PROFESSIONAL,
      accountType: AppConstants.individual,
    );

    final fullList = [allItem, ..._professionalConsultantCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.flagIcon ?? "",
      isSelected: (item) {
        if (item.slugId == 'ALL_OPTION') {
          return controller.selectedProfessionalConsultantData.value == null;
        }
        return controller.selectedProfessionalConsultantData.value?.slugId ==
            item.slugId;
      },
      onTap: (item, index) {
        controller.selectedTabIndex.value = index;

        if (item.slugId == 'ALL_OPTION') {
          controller.selectedProfessionalConsultantData.value = null;
        } else {
          controller.selectedProfessionalConsultantData.value = item;
        }
        // Single API Call (Clean & Shared)
        controller.fetchProfessionalConsultantServices();
      },
    );
  }

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

                  if (controller.filters == selectedEnum) return;

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
                  if (controller.isProfConServiceLoading.value &&
                      controller.professionalConsDataList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.professionalConsDataList.isEmpty) {
                    return Center(
                        child: EmptyStateWidget(message: "No services found"));
                  }

                  return ListView.builder(
                      controller: scrollController,
                      itemCount: controller.professionalConsDataList.length +
                          (controller.isProfConServiceLoadingMore.value
                              ? 1
                              : 0),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                      itemBuilder: (context, index) {
                        if (index ==
                            controller.professionalConsDataList.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        var service =
                            controller.professionalConsDataList[index];

                        return selfProfessionCard(service);
                      });
                }),
              )
            ],
          ),
        ));
  }

  Widget selfProfessionCard(ProfessionalConsData service) {
    // Timings

/*
    Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
      if (timingsList == null || timingsList.isEmpty)
        return {"start": "--", "end": "--"};

      Timings? earliest = timingsList.first;
      Timings? latest = timingsList.first;

      for (final t in timingsList) {
        final startTime = parse12HourTime(t.schedule.monday.start ?? "00:00 AM");
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
*/

    // final timingMap = getMinMaxTimings(service.service?.timings);

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
      // onTap: null,
      onTap: () => showFullProfessionDetails(
        service,
        // timingMap: timingMap,
        priceDisplay: priceDisplay,
        priceBadgeText: badgeText,
        priceBadgeColor: badgeColor,
      ),
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
                      imageUrl: service.basicDetails?.profilePhotoUrl ?? '',
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
                      CustomText(service.basicDetails?.fullName ?? 'User',
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      // SizedBox(height: SizeConfig.size6),
                      CustomText(
                        service.basicDetails?.shortTagline ?? 'User',
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
                      "${service.pricing?.consultationMode}",
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
                  )
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
                        'Timing',
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
                        'Service Description',
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
                        'Work Experience',
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
                              "${service.about?.totalExperience?.years ?? 0} Yr",
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
                        'Portfolio',
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
                              'No Data',
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
                        'Gallery',
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
                              'No Photos Available',
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
                  title: 'Request Booking',
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
              "All Variants",
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
