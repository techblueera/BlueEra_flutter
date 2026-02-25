import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/view/hotel_discover_home_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/home_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/hotel_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/vehicle_details_widget.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllStayServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> stayCategories;
  final OnboardingCategoryModel? selectedStayCategory;

  const AllStayServiceScreen(
      {super.key, required this.stayCategories, this.selectedStayCategory});

  @override
  State<AllStayServiceScreen> createState() => _AllStayServiceScreenState();
}

class _AllStayServiceScreenState extends State<AllStayServiceScreen> {
  final controller = getOrPut(() => DiscoverController());
  ScrollController scrollController = ScrollController();
  late List<OnboardingCategoryModel> _stayCategories;
  late String _category;

  @override
  initState() {
    super.initState();
    _stayCategories = widget.stayCategories;
    controller.selectedStayCategory.value = widget.selectedStayCategory;
    _category = controller.selectedStayCategory.value!.slugId;

    if (controller.selectedStayCategory.value != null) {
      if (controller.selectedStayCategory.value?.accountType.toUpperCase() ==
          AppConstants.individual) {
        var serviceType = _category.toRentalServiceType();
        controller.fetchRentalServices(
          rentalServiceType: serviceType,
        );

        // Listener for Pagination
        scrollController.addListener(() {
          if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
            controller.fetchRentalServices(
                rentalServiceType: serviceType, isLoadMore: true);
          }
        });
      } else {
        // handle business rental api call
        controller.fetchHotelServices(category: _category);

        // Listener for Pagination
        scrollController.addListener(() {
          if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
            controller.fetchHotelServices(
                category: _category, isLoadMore: true);
          }
        });
      }
    }
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
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: _stayCategories,
      getIcon: (item) => item.icon,
      getLabel: (item) => item.name,
      isSelected: (item) =>
          controller.selectedStayCategory.value?.slugId == item.slugId,
      onTap: (item, index) {
        controller.selectedStayCategory.value = item;
        controller.selectedTabIndex.value = index;

        _category = controller.selectedStayCategory.value!.slugId;

        if (controller.selectedStayCategory.value?.accountType ==
            AppConstants.individual) {
          var serviceType = _category.toRentalServiceType();
          controller.fetchRentalServices(
            rentalServiceType: serviceType,
          );
        } else {
          // handle business rental api call
          controller.fetchHotelServices(category: _category);
        }
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
                child: (controller.selectedStayCategory.value?.accountType ==
                        AppConstants.individual)
                    ? Obx(() {
                        if (controller.isRentalServiceLoading.value &&
                            controller.rentalServices.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (controller.rentalServices.isEmpty) {
                          return Center(
                              child: EmptyStateWidget(
                                  message: "No stay service found"));
                        }

                        return ListView.builder(
                            controller: scrollController,
                            itemCount: controller.rentalServices.length +
                                (controller.isRentalServiceLoadingMore.value
                                    ? 1
                                    : 0),
                            shrinkWrap: true,
                            padding:
                                EdgeInsets.only(bottom: SizeConfig.paddingL),
                            itemBuilder: (context, index) {
                              if (index == controller.rentalServices.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }

                              var service = controller.rentalServices[index];

                              return rentalServiceCard(service);
                            });
                      })
                    : Obx(() {
                        if (controller.isRentalServiceLoading.value &&
                            controller.hotelServices.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (controller.hotelServices.isEmpty) {
                          return Center(
                              child: EmptyStateWidget(
                                  message: "No hotel service found"));
                        }

                        return ListView.builder(
                            controller: scrollController,
                            itemCount: controller.hotelServices.length +
                                (controller.isRentalServiceLoadingMore.value
                                    ? 1
                                    : 0),
                            shrinkWrap: true,
                            padding:
                                EdgeInsets.only(bottom: SizeConfig.paddingL),
                            itemBuilder: (context, index) {
                              if (index == controller.hotelServices.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }

                              var service = controller.hotelServices[index];

                              return hotelServiceCard(service);
                            });
                      }),
              )
            ],
          ),
        ));
  }

  Widget rentalServiceCard(RentalServiceData service) {
    final distance = calculateDistance(
        service.location?.coordinates?[1].toDouble() ?? 0.0,
        service.location?.coordinates?[0].toDouble() ?? 0.0);

    return InkWell(
      onTap: () {
        (service.type == AppConstants.property ||
                service.type == AppConstants.flat)
            ? Get.to(HomeStayDetailsWidget(service: service))
            : Get.to(VehicleDetailsWidget(service: service));
      },
      // onTap: ()=> showFullRentalDetails(
      //   service
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
                  (service.images?.isNotEmpty ?? false)
                      ? InkWell(
                          onTap: () {
                            // Navigate to details
                          },
                          child: CachedAvatarWidget(
                            imageUrl: service.images?[0] ?? '',
                            size: SizeConfig.size40,
                            borderColor: Colors.white,
                            borderRadius: SizeConfig.size20,
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size20),
                          child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: SizeConfig.size40,
                            width: SizeConfig.size40,
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
                        reviews: service.reviews ?? 0,
                        distance: '${distance?.toStringAsFixed(2)} KM',
                      )
                    ],
                  )),
                  Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),
              if (service.highlights?.isNotEmpty ?? false) ...[
                SizedBox(height: SizeConfig.size6),
                CustomText(service.highlights?.join(", ") ?? "",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400),
              ],
              SizedBox(height: SizeConfig.size8),
              if (service.price != null && service.priceUnit != null)
                CustomText(
                  '₹${service.price}/${service.priceUnit}',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              SizedBox(height: SizeConfig.size8),
              if (service.type == AppConstants.property ||
                  service.type == AppConstants.flat)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      CustomText(
                        "Check In: ",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.green00,
                      ),
                      CustomText(
                        service.checkInTime,
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
                        "Check Out: ",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.redB4,
                        maxLines: 1,
                      ),
                      CustomText(
                        service.checkOutTime,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              if (service.type == AppConstants.vehicle) ...[
                Row(
                  children: [
                    CustomText(
                      "Security Deposit: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor,
                    ),
                    CustomText(
                      service.vehicleDetails?.securityDeposit ?? AppStrings.na,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size5),
                Row(
                  children: [
                    CustomText(
                      "Pickup Location: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.mainTextColor,
                    ),
                    CustomText(
                      service.vehicleDetails?.pickupLocation ?? AppStrings.na,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ]
            ],
          )),
    );
  }

  Widget hotelServiceCard(HotelServiceData service) {
    final distance = calculateDistanceInt(
        service.profile?.location?.coordinates?[1].toDouble() ?? 0.0,
        service.profile?.location?.coordinates?[0].toDouble() ?? 0.0);
    List<String> allImages = service.profile?.photos
            ?.expand((photo) =>
                photo.imageReferences ?? []) // Flatten all image lists
            .map((url) => url.toString()) // Ensure they are strings
            .take(5) // Stop after 5 items
            .toList() ??
        []; // Fallback to empty list
    return InkWell(
      onTap: () {
        Get.to(HotelDiscoverHomeScreen(
          data: service,
        ));
      },
      child: PropertyCard(
        imageUrls: allImages ?? [],
        hotelName: service.profile?.name ?? "N/A",
        hotelDescr: '',
        distance: distance.toString(),
        totalRoom:
            service.rooms?.firstOrNull?.totalRooms.toString() ?? 0.toString(),
        bedType: service.rooms?.firstOrNull?.bedType ?? "",
        rent: service.rooms?.firstOrNull?.pricePerDay.toString() ?? "",
      ),
    );
/*
    return InkWell(
      onTap: () {
        Get.to(HotelDiscoverHomeScreen(
          data: service,
        ));
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
                  (profile?.coverUrl?.isNotEmpty ?? false)
                      ? InkWell(
                          onTap: () {
                            // Navigate to details
                          },
                          child: CachedAvatarWidget(
                            imageUrl: profile?.coverUrl,
                            size: SizeConfig.size40,
                            borderColor: Colors.white,
                            borderRadius: SizeConfig.size20,
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size20),
                          child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: SizeConfig.size40,
                            width: SizeConfig.size40,
                          ),
                        ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.profile?.name ?? AppStrings.na,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      SizedBox(height: SizeConfig.size6),
                      CommonRatingRow(
                        rating: double.tryParse(
                                profile?.rating.toString() ?? '0.0') ??
                            0.0,
                        reviews: profile?.reviews ?? 0,
                        distance: '${distance?.toStringAsFixed(2)} KM',
                      )
                    ],
                  )),
                  // Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),

              if (profile?.photos?.firstOrNull?.imageReferences?.isNotEmpty ??
                  false) ...[
                SizedBox(height: SizeConfig.size6),
                CustomText(profile?.description ?? "",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400),
              ],

              // SizedBox(height: SizeConfig.size8),
              //
              // if(service.price!=null && service.priceUnit!=null)
              //   CustomText(
              //     '₹${service.price}/${service.priceUnit}',
              //     fontSize: SizeConfig.medium,
              //     fontWeight: FontWeight.w700,
              //     color: AppColors.mainTextColor,
              //   ),
              // SizedBox(height: SizeConfig.size8),
              //
              // if(service.type == AppConstants.property || service.type == AppConstants.flat)
              //   FittedBox(
              //     fit: BoxFit.scaleDown,
              //     child: Row(
              //       children: [
              //         CustomText(
              //           "Check In: ",
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.green00,
              //         ),
              //         CustomText(
              //           service.checkInTime,
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.secondaryTextColor,
              //           maxLines: 1,
              //         ),
              //         CustomText(
              //           ' | ',
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           color: AppColors.secondaryTextColor,
              //           overflow: TextOverflow.ellipsis,
              //         ),
              //         CustomText(
              //           "Check Out: ",
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.redB4,
              //           maxLines: 1,
              //         ),
              //         CustomText(
              //           service.checkOutTime,
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           color: AppColors.grayText,
              //           overflow: TextOverflow.ellipsis,
              //           maxLines: 1,
              //         ),
              //       ],
              //     ),
              //   ),
            ],
          )),
    );
*/
  }

  void showFullRentalDetails(
    RentalServiceData service,
  ) {
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
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),
                _header(context),
                const SizedBox(height: 4),
                (service.type == AppConstants.property ||
                        service.type == AppConstants.flat)
                    ? HomeStayDetailsWidget(service: service)
                    : VehicleDetailsWidget(service: service),
                SizedBox(height: SizeConfig.paddingL)
              ],
            );
          },
        );
      },
    );
  }

  void showFullHotelDetails(
    HotelServiceData service,
  ) {
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
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),
                _header(context),
                const SizedBox(height: 4),
                HotelsDetailsWidget(hotelServiceData: service),
                SizedBox(height: SizeConfig.paddingL)
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
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          Expanded(
            child: CustomText(
              "Details",
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

class PropertyCard extends StatefulWidget {
  final List<String> imageUrls;
  final String hotelName, hotelDescr, distance, totalRoom, bedType, rent;

  const PropertyCard(
      {super.key,
      required this.imageUrls,
      required this.hotelName,
      required this.hotelDescr,
      required this.distance,
      required this.totalRoom,
      required this.bedType,
      required this.rent});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool hasMultipleImages = widget.imageUrls.length > 1;

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            widget.hotelName,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: 10,
          ),
          // 1. The Image Stack
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: hasMultipleImages,
                    onPageChanged: (index, reason) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                  items: widget.imageUrls.map((url) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }).toList(),
                ),
              ),

              // // 2. The Floating "Guest Favourite" Badge
              // Positioned(
              //   top: 12,
              //   left: 12,
              //   child: Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //     child: const Text(
              //       'Guest favourite',
              //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              //     ),
              //   ),
              // ),

              // 3. The Indicators (Only visible if > 1 image)
              if (hasMultipleImages)
                Positioned(
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.imageUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 6.0,
                        height: 6.0,
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(
                            _currentIndex == entry.key ? 1.0 : 0.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),

          // 4. The Text Content
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Room Type : ${widget.bedType}",
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CustomText("${widget.totalRoom} Room",
                          color: AppColors.secondaryTextColor),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: CustomText("INR ${widget.rent}/day",
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16),
                    CustomText("${widget.distance} km away"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
