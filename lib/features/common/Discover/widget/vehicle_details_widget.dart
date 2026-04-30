import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDetailsWidget extends StatelessWidget {
  final RentalServiceData service;

  const VehicleDetailsWidget({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistance(
        service.location?.coordinates?[1].toDouble() ?? 0.0,
        service.location?.coordinates?[0].toDouble() ?? 0.0);
    var vehicleDetails = service.vehicleDetails;

    bool hasAnyRequirement =
        (vehicleDetails?.documentRequired?.adharCard == true) ||
            (vehicleDetails?.documentRequired?.addressProof == true) ||
            (vehicleDetails?.documentRequired?.drivingLicence == true);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: service.name,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonCardWidget(
              padding: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        (service.images?.isNotEmpty ?? false)
                            ? CustomImageSlideshow(
                          isLoading: false,
                          width: double.infinity,
                          height: SizeConfig.size150,
                          imagePaths: service.images!,
                          borderRadius: BorderRadius.circular(10),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: SizeConfig.size150,
                            width: double.infinity,
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
                              child: (service.images?.isNotEmpty ?? false)
                                  ? CachedAvatarWidget(
                                imageUrl: service.images![0],
                                size: SizeConfig.size80,
                                borderColor: Colors.white,
                                borderRadius: SizeConfig.size40,
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    SizeConfig.size40),
                                child: LocalAssets(
                                  imagePath:
                                  AppIconAssets.place_holder_image,
                                  height: SizeConfig.size80,
                                  width: SizeConfig.size80,
                                ),
                              ),
                            ))
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size40,
                    ),
                    ServiceHomeHeaderTitleWidget(title: service.name ?? "N/A",
                        description: service.description ?? "N/A"),

                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: CommonRatingRow(
                        rating: double.tryParse(service.rating.toString()) ??
                            0.0,
                        reviews: service.reviews ?? 0,
                        distance: '${distance?.toStringAsFixed(2)} KM',
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),

                  ],
                ),
              ),
            ),


            // Price, security deposit , pickup location
            CommonCardWidget(
              child: Column(
                children: [
                  Row(
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
                        '₹${service.price}/${service.priceUnit}',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        'Security Deposit: ',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        vehicleDetails?.securityDeposit,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        'Pickup Location: ',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        vehicleDetails?.pickupLocation,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),


            // Vehicle Details
            CommonCardWidget(
              padding: 0,
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Brand: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          vehicleDetails?.brand,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Registration Type: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          vehicleDetails?.registrationType,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Registration Number: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          vehicleDetails?.registrationNumber,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Vehicle Type: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          vehicleDetails?.vehicleType,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Fuel Type: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          vehicleDetails?.fuelType,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Year Of Manufacture: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          '${vehicleDetails?.yearOfManufacture}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          'Seating Capacity: ',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        CustomText(
                          '${vehicleDetails?.seatingCapacity}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    if (vehicleDetails?.registrationType == 'commercialGoods')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomText(
                              'Load Capacity: ',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                            ),
                            CustomText(
                              vehicleDetails?.loadCapacity,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),


            CommonCardWidget(
              padding: 0,
              child: Container(
                width: SizeConfig.screenWidth,
                padding: EdgeInsets.all(SizeConfig.size10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Document Required For Rent',
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
                    if (!hasAnyRequirement)
                      Padding(
                        padding: EdgeInsets.only(top: SizeConfig.size8),
                        child: CustomText(
                          'No document is required',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    if (vehicleDetails?.documentRequired?.adharCard ==
                        true) ...[
                      SizedBox(height: SizeConfig.size8),
                      _buildRequirementRow('Aadhar Card required'),
                    ],
                    if (vehicleDetails?.documentRequired?.addressProof ==
                        true) ...[
                      SizedBox(height: SizeConfig.size8),
                      _buildRequirementRow('Address Proof required'),
                    ],
                    if (vehicleDetails?.documentRequired?.drivingLicence ==
                        true) ...[
                      SizedBox(height: SizeConfig.size8),
                      _buildRequirementRow('Driving License required'),
                    ]
                  ],
                ),
              ),
            ),

            // Highlights
            if (service.highlights?.isNotEmpty ?? false)
              Container(
                padding: EdgeInsets.all(SizeConfig.size10),
                margin: EdgeInsets.only(top: SizeConfig.size15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: service.highlights!
                      .map((e) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: SizeConfig.size6,
                              width: SizeConfig.size6,
                              decoration: BoxDecoration(
                                  color: AppColors.secondaryTextColor,
                                  shape: BoxShape.circle),
                            ),
                            SizedBox(width: SizeConfig.size6),
                            Expanded(
                              child: CustomText(
                                e,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                          ],
                        ),
                      ))
                      .toList(),
                ),
              ),

            if (service.additionalRules?.isNotEmpty ?? false)
              Container(
                padding: EdgeInsets.all(SizeConfig.size10),
                margin: EdgeInsets.only(top: SizeConfig.size15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: service.additionalRules!
                      .map((e) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CustomText(
                          '⚠️${e}',
                          fontSize: SizeConfig.medium,
                        ),
                      ))
                      .toList(),
                ),
              ),


            CommonCardWidget(
              // padding: 0,
              child: Builder(builder: (BuildContext context) {
                final v = service.vehicleDetails;
                List<String> allImages = [
                  ...?v?.vehicleFrontImage,
                  ...?v?.vehicleBackImage,
                  ...?v?.vehicleLeftSideImage,
                  ...?v?.vehicleRightHandSideImage,
                ];
                return _buildPhotoGrid(allImages, context);
              }),
            ),

            SizedBox(height: SizeConfig.paddingL),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0,right: 15,left: 15),
                child: CustomBtn(
                  onTap: () {
                    commonSnackBar(message: "Coming soon....");
                  },
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: 'Book Now',
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> images, BuildContext context) {
    if (images.isEmpty) {
      return CustomText(
        'No Photos Available',
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextColor,
      );
    }

    const crossAxisCount = 4;
    const mainAxisSpacing = 8.0;

    final rows = <List<String>>[];
    for (int i = 0; i < images.length; i += crossAxisCount) {
      rows.add(
        images.sublist(
          i,
          (i + crossAxisCount).clamp(0, images.length),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceHomeTitleWidget(title: "Gallery",)  ,
        SizedBox(height: 10,),
        Column(
          children: List.generate(rows.length, (rowIndex) {
            final rowItems = rows[rowIndex];
            final isLastRow = rowIndex == rows.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : mainAxisSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(crossAxisCount * 2 - 1, (i) {
                  if (i.isEven) {
                    final itemIndex = i ~/ 2;
                    if (itemIndex < rowItems.length) {
                      return Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CachedNetworkImage(
                            imageUrl: rowItems[itemIndex],
                            width: SizeConfig.size80,
                            height: SizeConfig.size80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(
                                  color: Colors.grey[300],
                                  width: SizeConfig.size80,
                                  height: SizeConfig.size80,
                                ),
                            errorWidget: (context, url, error) =>
                                Container(
                                  color: Colors.grey[200],
                                  width: SizeConfig.size80,
                                  height: SizeConfig.size80,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                          ),
                        ),
                      );
                    } else {
                      return const Expanded(child: SizedBox.shrink());
                    }
                  } else {
                    return SizedBox(width: SizeConfig.size8);
                  }
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text) {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.green_tick_icon,
          height: 20,
          width: 20,
          imgColor: AppColors.secondaryTextColor,
        ),
        SizedBox(width: SizeConfig.size6),
        CustomText(
          text,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
        ),
      ],
    );
  }
}
