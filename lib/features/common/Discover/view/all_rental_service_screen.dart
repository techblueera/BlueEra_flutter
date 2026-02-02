import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllRentalServiceScreen extends StatefulWidget {
  final RentalServiceType type;
  const AllRentalServiceScreen({super.key, required this.type});

  @override
  State<AllRentalServiceScreen> createState() => _AllRentalServiceScreenState();
}

class _AllRentalServiceScreenState extends State<AllRentalServiceScreen> {
  final DiscoverController controller = Get.put(DiscoverController());
  ScrollController scrollController = ScrollController();

  @override
  initState(){
    super.initState();

    controller.fetchRentalServices(
        rentalServiceType: widget.type,
    );

    // Listener for Pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        controller.fetchRentalServices(
            rentalServiceType: widget.type,
            isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.type.label,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.rentalServiceResponse.value.status ==
              Status.COMPLETE) {
            if (controller.isRentalServiceLoading.isTrue) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              List<RentalServiceData> rentalServices = List.from(controller.rentalServices);
              if (rentalServices.isNotEmpty) {
                return Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                  child: LayoutBuilder(
                    builder: (context, constraints) {

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: rentalServices.length,
                        shrinkWrap: true,
                        padding:
                        const EdgeInsets.only(top: 12, bottom: 24),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) =>
                            _buildServiceCard(rentalServices[index]),
                      );
                    },
                  ),
                );
              } else {
                return Center(
                    child: EmptyStateWidget(
                      message: 'No ${widget.type.label.tr} available.',
                    ));
              }
            }
          } else if (controller.rentalServiceResponse.value.status ==
              Status.ERROR) {
            return LoadErrorWidget(
                errorMessage: 'Failed to load rental services',
                onRetry: () => controller.fetchRentalServices(
                  rentalServiceType: widget.type,
                )
            );
          }

          return SizedBox();
        })
      ),
    );
  }

  Widget _buildServiceCard(RentalServiceData serviceData) {
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

                  CommonRatingRow(
                    rating: serviceData.rating?.toDouble()??0.0,
                    reviews: serviceData.reviews??0,
                    distance: '0',
                    // distance: serviceData.distance,
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
