import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalCard extends StatelessWidget {
  final RentalServiceData rentalServiceData;
  final VoidCallback? deleteServiceApi;
  final double width;

  const RentalCard({
    super.key,
    required this.rentalServiceData,
    this.deleteServiceApi,
    required this.width
  });

  @override
  Widget build(BuildContext context) {

    // ignore: unused_local_variable
    int servicePhotoIndex = 0;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RouteHelper.getRentalServiceFullDetailsScreenRoute(),
          arguments: {
            ApiKeys.argRentalData: rentalServiceData
          },
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: width,
          color: AppColors.whiteFE,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Home Stay Image
              AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: rentalServiceData.images ?? [],
                      borderRadius: BorderRadius.zero,
                      onPhotoIndex: (index) {
                        servicePhotoIndex = index;
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildIconBox(
                        onTap: deleteServiceApi,
                        Icon(Icons.more_vert, color: Colors.white, size: 16),
                      ),
                    ),
                    // Positioned(
                    //   top: 8,
                    //   left: 8,
                    //   child: _buildIconBox(
                    //     Icon(Icons.share, color: AppColors.white, size: 16),
                    //     onTap: () {
                    //       // Handle share icon tap if needed
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),

              // Product Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    CustomText(
                      rentalServiceData.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size2),

                    CustomText(
                      rentalServiceData.description,
                      fontWeight: FontWeight.w400,
                      fontSize: SizeConfig.small11,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size8),

                    // Price Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                        '₹${rentalServiceData.price}/${rentalServiceData.priceUnit}',
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size8),

                    // Contact Number & Address
                    Row(
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.call,
                            imgColor: AppColors.secondaryTextColor
                        ),
                        SizedBox(width: SizeConfig.size6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            rentalServiceData.contactNumber,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.small11,
                            color: AppColors.secondaryTextColor
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Row(
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.location_outline,
                            imgColor: AppColors.secondaryTextColor
                        ),
                        SizedBox(width: SizeConfig.size6),
                        Expanded(
                          child: CustomText(
                              rentalServiceData.address,
                              fontWeight: FontWeight.w400,
                              fontSize: SizeConfig.small11,
                              color: AppColors.secondaryTextColor
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(Widget child, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

}
