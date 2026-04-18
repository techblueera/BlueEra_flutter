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
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/home_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/hotel_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/vehicle_details_widget.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';

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

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/beautiful-luxury-outdoor-swimming-pool-hotel-resort_74190-7433.jpg?w=1380",
    "https://img.freepik.com/free-photo/luxury-classic-modern-bedroom-suite-hotel_105762-1787.jpg?w=1380",
    "https://img.freepik.com/free-photo/beautiful-shot-modern-house-with-pool-sunset_181624-4587.jpg?w=1380",
  ];

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * 8 / 16) + statusBarHeight;
    const double stickyMaxHeight = 165;
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bannerHeight + stickyMaxHeight,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.5),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor: Colors.transparent,
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
                    categories: _stayCategories.map((c) => StickyCategory(
                      id: c.slugId,
                      name: c.name,
                      imageUrl: c.icon,
                    )).toList(),
                    selectedId: controller.selectedStayCategory.value?.slugId,
                    onCategoryTap: (item) {
                      final cat = _stayCategories.firstWhere((c) => c.slugId == item.id);
                      controller.selectedStayCategory.value = cat;
                      controller.selectedTabIndex.value = _stayCategories.indexOf(cat);
                      _category = cat.slugId;
                      if (cat.accountType == AppConstants.individual) {
                        final serviceType = _category.toRentalServiceType();
                        controller.fetchRentalServices(rentalServiceType: serviceType);
                      } else {
                        controller.fetchHotelServices(category: _category);
                      }
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                  ),
                ),
                SliverToBoxAdapter(
                  child: BookViaBlueEraPartnerBanner(onTap: () {}),
                ),
                _buildListSliver(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver() {
    return Obx(() {
      final isIndividual =
          controller.selectedStayCategory.value?.accountType ==
              AppConstants.individual;

      if (isIndividual) {
        if (controller.isRentalServiceLoading.value &&
            controller.rentalServices.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.rentalServices.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _NoHotelsFound(
              title: 'No stays available',
              subtitle:
                  'We couldn\'t find any stays or rooms in this area. Try another category or change your location.',
              onRetry: () {
                final serviceType = _category.toRentalServiceType();
                controller.fetchRentalServices(
                    rentalServiceType: serviceType);
              },
            ),
          );
        }

        final list = controller.rentalServices;
        final showMoreLoader = controller.isRentalServiceLoadingMore.value;

        return SliverPadding(
          padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            bottom: SizeConfig.paddingL,
          ),
          sliver: SliverList.builder(
            itemCount: list.length + (showMoreLoader ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == list.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return rentalServiceCard(list[index]);
            },
          ),
        );
      }

      // Business (hotel) branch
      if (controller.isRentalServiceLoading.value &&
          controller.hotelServices.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hotelServices.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _NoHotelsFound(
            title: 'No hotels & rooms available',
            subtitle:
                'No hotels or rooms found nearby. Try a different category or change your location to explore more stays.',
            onRetry: () =>
                controller.fetchHotelServices(category: _category),
          ),
        );
      }

      final list = controller.hotelServices;
      final showMoreLoader = controller.isRentalServiceLoadingMore.value;

      return SliverPadding(
        padding: EdgeInsets.only(
          left: SizeConfig.size8,
          right: SizeConfig.size8,
          bottom: SizeConfig.paddingL,
        ),
        sliver: SliverList.builder(
          itemCount: list.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return hotelServiceCard(list[index]);
          },
        ),
      );
    });
  }

  Widget rentalServiceCard(RentalServiceData service) {
    final rentalCoords = service.location?.coordinates;
    final distanceData = (rentalCoords != null && rentalCoords.length >= 2)
        ? calculateDistance(
            rentalCoords[1].toDouble(),
            rentalCoords[0].toDouble())
        : null;

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
                      CustomText(service.name ?? AppStrings.unknownUser.tr,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      SizedBox(height: SizeConfig.size6),
                      CommonRatingRow(
                        rating:
                            double.tryParse(service.rating.toString()) ?? 0.0,
                        reviews: service.reviews ?? 0,
                        distance: distanceData != null ? '$distanceData KM' : '',
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
                        AppStrings.checkInLabel,
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
                        AppStrings.checkOutLabel,
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
                      AppStrings.securityDepositLabel,
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
                      AppStrings.pickupLocationLabel,
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
    final coords = service.profile?.location?.coordinates;
    final distance = (coords != null && coords.length >= 2)
        ? calculateDistanceInt(
            coords[1].toDouble(),
            coords[0].toDouble())
        : 0;
    List<String> allImages = service.profile?.photos
            ?.expand((photo) =>
                photo.imageReferences ?? []) // Flatten all image lists
            .map((url) => url.toString()) // Ensure they are strings
            .take(5) // Stop after 5 items
            .toList() ??
        []; // Fallback to empty list
    return InkWell(
      onTap: () {
        Get.to(()=> HotelDiscoverHomeScreen(
          data: service,
        ));
      },
      child: PropertyCard(
        imageUrls: allImages,
        logoUrl: service.profile?.logoUrl ?? '',
        hotelName: service.profile?.name ?? "N/A",
        subCategory: service.rooms?.firstOrNull?.bedType ?? 'Hotel',
        address: [
          service.profile?.address?.street,
          service.profile?.address?.city,
          service.profile?.address?.state,
        ].where((e) => e != null && e.isNotEmpty).join(', '),
        distance: distance.toString(),
        rent: service.rooms?.firstOrNull?.pricePerDay.toString() ?? "",
        rating: (service.profile?.rating ?? 0).toDouble(),
        reviews: service.profile?.reviews ?? 0,
        businessId: service.profile?.businessId ?? '',
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
              AppStrings.detailsLabel,
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
  final String logoUrl;
  final String hotelName;
  final String subCategory;
  final String address;
  final String distance;
  final String rent;
  final double rating;
  final int reviews;
  final String businessId;

  const PropertyCard({
    super.key,
    required this.imageUrls,
    required this.logoUrl,
    required this.hotelName,
    required this.subCategory,
    required this.address,
    required this.distance,
    required this.rent,
    required this.rating,
    required this.reviews,
    required this.businessId,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _currentIndex = 0;

  // Dummy reviews for the read-only review sheet.
  final List<Map<String, dynamic>> _dummyReviews = const [
    {
      'name': 'Priya Sharma',
      'rating': 5.0,
      'date': '2 days ago',
      'comment':
          'Fantastic stay! The rooms were spotless and the staff was incredibly warm. Breakfast spread was delicious.',
    },
    {
      'name': 'Rahul Verma',
      'rating': 4.0,
      'date': '1 week ago',
      'comment':
          'Great value for money. Clean rooms, good location, though check-in took a little longer than expected.',
    },
    {
      'name': 'Anita Desai',
      'rating': 4.5,
      'date': '3 weeks ago',
      'comment':
          'Loved the view from our room. The pool area is well-maintained and the ambience is peaceful.',
    },
    {
      'name': 'Vikram Rao',
      'rating': 3.5,
      'date': '1 month ago',
      'comment':
          'Decent stay. Rooms could be a little more spacious but the service made up for it.',
    },
  ];

  Future<void> _openInquiryChat() async {
    if (widget.businessId.isEmpty) {
      Get.snackbar(AppStrings.na, 'Business not available for chat',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final chatViewController = Get.find<ChatViewController>();
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: widget.businessId,
    );
  }

  void _openReviewsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewsBottomSheet(
        hotelName: widget.hotelName,
        rating: widget.rating,
        reviews: _dummyReviews,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.imageUrls.length > 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = (screenWidth - SizeConfig.size32) * 11 / 16;

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.imageUrls.isEmpty
                    ? _brokenImage(imageHeight)
                    : CarouselSlider(
                        options: CarouselOptions(
                          height: imageHeight,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: hasMultipleImages,
                          onPageChanged: (index, _) =>
                              setState(() => _currentIndex = index),
                        ),
                        items: widget.imageUrls.map((url) {
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _brokenImage(imageHeight),
                          );
                        }).toList(),
                      ),
              ),
              if (hasMultipleImages)
                Positioned(
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        widget.imageUrls.asMap().entries.map((entry) {
                      final active = _currentIndex == entry.key;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: active ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(
                              alpha: active ? 1.0 : 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),

          SizedBox(height: SizeConfig.size10),

          // Logo + name + subcategory
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _logoAvatar(),
              SizedBox(width: SizeConfig.size8),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      widget.hotelName,
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.subCategory.isNotEmpty) ...[

                    CustomText(
                      widget.subCategory,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  ],
                ),
              ),

            ],
          ),

          SizedBox(height: SizeConfig.size6),

          // Rating + reviews
          Row(
            children: [
              Icon(Icons.star_rounded,
                  size: SizeConfig.size18, color: Colors.amber),
              SizedBox(width: SizeConfig.size2),
              CustomText(
                widget.rating.toStringAsFixed(1),
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.small,
                color: AppColors.mainTextColor,
              ),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                '(${widget.reviews} reviews)',
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),

          SizedBox(height: SizeConfig.size6),

          // Address
          if (widget.address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: SizeConfig.size16,
                    color: AppColors.secondaryTextColor),
                SizedBox(width: SizeConfig.size2),
                Expanded(
                  child: CustomText(
                    widget.address,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          SizedBox(height: SizeConfig.size6),

          // Distance + price
          Row(
            children: [
              Icon(Icons.near_me_outlined,
                  size: SizeConfig.size16,
                  color: AppColors.secondaryTextColor),
              SizedBox(width: SizeConfig.size2),
              Flexible(
                child: CustomText(
                  "${widget.distance} ${AppStrings.kmAwayLabel.tr}",
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (widget.rent.isNotEmpty)
                CustomText(
                  "₹${widget.rent}",
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
              if (widget.rent.isNotEmpty)
                CustomText(
                  " /day",
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
            ],
          ),

          SizedBox(height: SizeConfig.size10),

          // Review + Inquiry action row
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.star_border_rounded,
                  label: 'Review',
                  onTap: _openReviewsSheet,
                  filled: false,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: _actionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Inquiry',
                  onTap: _openInquiryChat,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoAvatar() {
    if (widget.logoUrl.isEmpty) return _brokenHotelLogo();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: widget.logoUrl,
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: SizeConfig.size40,
          height: SizeConfig.size40,
          color: AppColors.greyE5,
        ),
        errorWidget: (_, __, ___) => _brokenHotelLogo(),
      ),
    );
  }

  Widget _brokenHotelLogo() => Container(
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Icon(
          Icons.broken_image_outlined,
          size: SizeConfig.size22,
          color: AppColors.secondaryTextColor,
        ),
      );

  Widget _brokenImage(double height) => Container(
        width: double.infinity,
        height: height,
        color: AppColors.greyE5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: SizeConfig.size40,
                color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size6),
            CustomText(
              'Image unavailable',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );


  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final bg = filled ? AppColors.primaryColor : AppColors.white;
    final fg = filled ? AppColors.white : AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: SizeConfig.size18, color: fg),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.small,
              color: fg,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsBottomSheet extends StatelessWidget {
  final String hotelName;
  final double rating;
  final List<Map<String, dynamic>> reviews;

  const _ReviewsBottomSheet({
    required this.hotelName,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      backgroundColor: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size10,
      ),
      builder: (scrollController) {
        final avg = reviews.isEmpty
            ? rating
            : reviews
                    .map((r) => (r['rating'] as num).toDouble())
                    .reduce((a, b) => a + b) /
                reviews.length;

        return ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    hotelName,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    color: Colors.amber, size: SizeConfig.size22),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  avg.toStringAsFixed(1),
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  '· ${reviews.length} reviews',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Divider(color: AppColors.greyE5, height: 1),
            SizedBox(height: SizeConfig.size10),
            ...reviews.map(_reviewTile),
            SizedBox(height: SizeConfig.paddingL),
          ],
        );
      },
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final name = r['name'] as String;
    final rate = (r['rating'] as num).toDouble();
    final date = r['date'] as String;
    final comment = r['comment'] as String;
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: SizeConfig.size16,
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.15),
                child: CustomText(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                    ),
                    CustomText(
                      date,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < rate.floor();
                  final half = !filled && (i < rate);
                  return Icon(
                    half
                        ? Icons.star_half_rounded
                        : (filled
                            ? Icons.star_rounded
                            : Icons.star_border_rounded),
                    size: SizeConfig.size16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            comment,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }
}

class _NoHotelsFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoHotelsFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 380;
        final illustrationSize = isCompact
            ? SizeConfig.size80
            : (constraints.maxWidth * 0.35).clamp(
                SizeConfig.size80,
                SizeConfig.size150,
              );

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24,
              vertical: SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: illustrationSize,
                  height: illustrationSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.12),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.hotel_outlined,
                    size: illustrationSize * 0.5,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  title,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (onRetry != null) ...[
                  SizedBox(height: SizeConfig.size16),
                  InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: AppColors.white,
                              size: SizeConfig.size18),
                          SizedBox(width: SizeConfig.size6),
                          CustomText(
                            'Retry',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Keeps the category slider pinned at the top while scrolling.
