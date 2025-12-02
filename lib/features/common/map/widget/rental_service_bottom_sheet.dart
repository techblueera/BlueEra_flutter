import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/model/rental_service_model.dart';
import 'package:BlueEra/features/common/map/widget/sub_category_tab_bar.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalServicesBottomSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onClose;
  final String category;
  final String subType;

  RentalServicesBottomSheet({
    super.key,
    required this.onClose,
    required this.lat,
    required this.lng,
    required this.category,
    required this.subType,
  });

  @override
  State<RentalServicesBottomSheet> createState() =>
      _RentalServicesBottomSheetState();
}

class _RentalServicesBottomSheetState extends State<RentalServicesBottomSheet> {
  final MapServiceController mapServiceController = Get.put(MapServiceController());
  int _selectedSubCategoryIndex = 0;
  String? _selectedSubCategory;
  final List<String> subCategories = [];

  @override
  initState() {
    super.initState();
    print("called after getting lat lng");
    // mapServiceController.getHomeServiceDataByProfession(
    //     serviceType: _selectedSubCategory,
    // );
    fetchHomeServices();

    // if (widget.lat != 0.0 && widget.lng != 0.0) {
    //   print("called after getting lat lng");
    //   fetchHomeServices();
    // }
  }

  @override
  void didUpdateWidget(covariant RentalServicesBottomSheet oldWidget) {
    // fetchHomeServices();

    // if (oldWidget.lat != widget.lat && oldWidget.lng != widget.lng) {
    //   if (widget.lat != 0.0 && widget.lng != 0.0) {
    //     print("called after getting lat lng");
    //     fetchHomeServices();
    //   }
    // }
    super.didUpdateWidget(oldWidget);
  }

  void fetchHomeServices() {
    mapServiceController.fetchRentalService(
        lat: widget.lat,
        lng: widget.lng,
        serviceType: widget.category,
        subType: widget.subType);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      key: ValueKey(widget.category),
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      backgroundColor: AppColors.whiteF1,
      boxShadow: [
        BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4.0,
            offset: Offset(0, -3))
      ],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: EdgeInsets.only(top: SizeConfig.size10, bottom: kToolbarHeight),
      builder: (scrollController) {
        return Obx(() {
          if (mapServiceController.rentalServiceResponse.value.status ==
              Status.COMPLETE) {
            if (mapServiceController.isHomeServiceLoading.isTrue) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              List<RentalDataList> homeServiceList =
                  mapServiceController.rentalDataList;
              if (homeServiceList.isNotEmpty) {
                final professionMap = mapServiceController
                    .groupRentalServicesByType(homeServiceList);

                final List<String> subCategories = professionMap.keys.toList();

                if (_selectedSubCategory == null && subCategories.isNotEmpty) {
                  _selectedSubCategory = subCategories.first;
                  _selectedSubCategoryIndex = 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                        child: IconButton(
                          iconSize: SizeConfig.size18,
                          onPressed: () => widget.onClose(),
                          icon: Icon(
                            Icons.close,
                            size: SizeConfig.size16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SubCategoryTabBar<String>(
                      tabs: subCategories,
                      selectedIndex: _selectedSubCategoryIndex,
                      onSelected: (index, label) {
                        setState(() {
                          _selectedSubCategoryIndex = index;
                          _selectedSubCategory = label;
                        });
                      },
                      labelBuilder: (label) => label,
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final List<RentalDataList> serviceData =
                                _selectedSubCategory != null
                                    ? professionMap[_selectedSubCategory] ?? []
                                    : [];
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: serviceData.length,
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) =>
                                  _buildServiceCard(serviceData[index]),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Center(
                    child: EmptyStateWidget(
                  message: 'No service available.',
                ));
              }
            }
          } else if (mapServiceController.rentalServiceResponse.value.status ==
              Status.ERROR) {
            return LoadErrorWidget(
                errorMessage: 'Failed to load rental services',
                onRetry: () => fetchHomeServices());
          }

          return SizedBox();
        });
      },
    );
  }

  Widget _buildServiceCard(RentalDataList serviceData) {
    return InkWell(
      onTap: () {
        // if (userId == serviceData.id) {
        //   Get.to(() => PersonalProfileSetupNewScreen());
        // } else {
        //   Get.to(() => NewVisitProfileScreen(
        //         authorId: serviceData.id ?? '',
        //         screenFromName: AppConstants.feedScreen,
        //       ));
        // }
      },
      child: Container(
        width: Get.width,
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.min,
          children: [
            /// ✅ Make image flexible — not fixed 190
            AspectRatio(
              aspectRatio: 2, // controls image height dynamically
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CustomImageSlideshow(
                  isLoading: false,
                  width: double.infinity,
                  height: double.infinity,
                  imagePaths: (serviceData.images?.isNotEmpty ?? false)
                      ? [
                          serviceData.images?.firstOrNull ?? "",
                        ]
                      : [],
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),

            /// ✅ Rest of info area flexible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisSize: MainAxisSize.min,

                children: [
                  // Hotel name
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          serviceData.name,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.size10,
                      ),
                      LocalAssets(imagePath: AppIconAssets.upload_share),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  // Rating & Distance row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      CustomText(
                        "${serviceData.rating}",
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                          "(${formatNumberLikePost(serviceData.reviews ?? 0)} reviews)",
                          color: Colors.grey,
                          fontSize: 13),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      CustomText("${serviceData.distance ?? 0} km",
                          color: Colors.grey, fontSize: 13),
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Direction
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // 🔹 removes extra touch area padding
                          ),
                          icon: LocalAssets(
                            imagePath: AppIconAssets.directionIcon,
                            imgColor: AppColors.primaryColor,
                          ),
                          label: CustomText(
                            "Direction",
                            color: AppColors.primaryColor,
                            fontSize: SizeConfig.small,
                          ),
                          onPressed: () {
                            if (serviceData.lat != null &&
                                serviceData.lng != null) {
                              canGoogleMapOpen(
                                latitude: serviceData.lat?.toDouble() ?? 0.0,
                                longitude: serviceData.lng?.toDouble() ?? 0.0,
                              );
                            } else {
                              commonSnackBar(
                                  message: AppStrings.somethingWentWrong);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reviews
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // 🔹 removes extra touch area padding
                          ),
                          icon: LocalAssets(
                            imagePath: AppIconAssets.star_rounded,
                            imgColor: AppColors.primaryColor,
                            height: 15,
                            width: 15,
                          ),
                          label: CustomText(
                            "Reviews",
                            color: AppColors.primaryColor,
                            fontSize: SizeConfig.small,
                          ),
                          onPressed: () {
                            commonSnackBar(message: "Coming soon");
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Book Now
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // 🔹 removes extra touch area padding
                          ),
                          icon: LocalAssets(
                            imagePath: AppIconAssets.chat,
                            imgColor: AppColors.white,
                            height: 15,
                            width: 15,
                          ),
                          label: CustomText(
                            "Book Now",
                            color: AppColors.white,
                            fontSize: SizeConfig.small,
                          ),
                          onPressed: () {
                            commonSnackBar(message: "Coming soon");
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
