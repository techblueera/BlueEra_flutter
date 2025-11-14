import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class RentalServiceFullDetailsScreen extends StatelessWidget {
  final RentalServiceData rentalServiceData;
  const RentalServiceFullDetailsScreen({super.key, required this.rentalServiceData});

  @override
  Widget build(BuildContext context) {
    final item = rentalServiceData;
    RentalServiceType? type = rentalServiceData.type?.toRentalServiceType();

    List<String>? getAllPropertyImages() {
      PropertyDetails? propertyDetails = item.propertyDetails;
      if(propertyDetails==null) return null;
      final List<String> all = [];

      if (propertyDetails.roomImages != null) all.addAll(propertyDetails.roomImages!);
      if (propertyDetails.kitchenImages != null) all.addAll(propertyDetails.kitchenImages!);
      if (propertyDetails.bathroomImages != null) all.addAll(propertyDetails.bathroomImages!);
      if (propertyDetails.roadImages != null) all.addAll(propertyDetails.roadImages!);
      if (propertyDetails.otherImages != null) all.addAll(propertyDetails.otherImages!);

      return all;
    }

    List<String>? getAllVehicleImages() {
      VehicleDetails? vehicleDetails = item.vehicleDetails;
      if(vehicleDetails==null) return null;
      final List<String> all = [];

      if (vehicleDetails.vehicleFrontImage != null) all.addAll(vehicleDetails.vehicleFrontImage!);
      if (vehicleDetails.vehicleBackImage != null) all.addAll(vehicleDetails.vehicleBackImage!);
      if (vehicleDetails.vehicleLeftSideImage != null) all.addAll(vehicleDetails.vehicleLeftSideImage!);
      if (vehicleDetails.vehicleRightHandSideImage != null) all.addAll(vehicleDetails.vehicleRightHandSideImage!);

      return all;
    }


    List<String>? images;
    if(type == RentalServiceType.vehicle){
      images = getAllVehicleImages();
    }else{
      images = getAllPropertyImages();
    }

    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: Column(
          children: [
            // ---- IMAGE ----
            (images!=null && images.isNotEmpty) ?
            InkWell(
              onTap: (){
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: item.name ?? '',
                    subTitle: item.description,
                    imageUrls: images!,
                    initialIndex: 0,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomImageSlideshow(
                  isLoading: false,
                  width: double.infinity,
                  height: SizeConfig.size260,
                  imagePaths:  images,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ) : LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),

            SizedBox(height: SizeConfig.size10),
            
            CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      type == RentalServiceType.vehicle
                          ? 'Vehicle Details'
                          : 'Home Details',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Container(
                      width: SizeConfig.screenWidth,
                      color: AppColors.whiteE0,
                      height: 0.5,
                    ),

                    SizedBox(height: SizeConfig.size10),

                    // Service Name
                    CustomText(
                      rentalServiceData.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.large,
                      color: AppColors.secondaryTextColor
                    ),
                    SizedBox(height: SizeConfig.size6),

                    ExpandableText(
                      text: rentalServiceData.description ?? '',
                      trimLines: 5,
                      expandMode: ExpandMode.dialog,
                      style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontFamily: AppConstants.OpenSans,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.small,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size10),

                    // Price Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                        '₹${rentalServiceData.price}/${rentalServiceData.priceUnit}',
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.large18,
                        color: AppColors.mainTextColor,
                      ),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        width: SizeConfig.screenWidth,
                       padding: EdgeInsets.symmetric(
                           horizontal: SizeConfig.size10,
                           vertical: SizeConfig.size12
                       ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SizeConfig.size4),
                          color: AppColors.primaryColor.withValues(alpha: 0.05)
                        ),
                        child: (type == RentalServiceType.vehicle)
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.seatIcon,
                                text: '${rentalServiceData.propertyDetails?.beds??0} Seats'
                            ),
                            CommonVerticalDivider(
                              width: 0.5,
                              color: AppColors.secondaryTextColor,
                            ),
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.fuelIcon,
                                text:
                                '${rentalServiceData.propertyDetails?.maxPeople?.adults??0} Beds, ${rentalServiceData.propertyDetails?.maxPeople?.children??0} Child'
                            ),
                            CommonVerticalDivider(
                              width: 0.5,
                              color: AppColors.secondaryTextColor,
                            ),
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.call,
                                text: rentalServiceData.contactNumber ?? 'N/A'
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.bedIcon,
                                text: '${rentalServiceData.propertyDetails?.beds??0} Beds'
                            ),
                            CommonVerticalDivider(
                              width: 0.5,
                              color: AppColors.secondaryTextColor,
                            ),
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.multiPersonsIcon,
                                text:
                                '${rentalServiceData.propertyDetails?.maxPeople?.adults??0} Beds, ${rentalServiceData.propertyDetails?.maxPeople?.children??0} Child'
                            ),
                            CommonVerticalDivider(
                              width: 0.5,
                              color: AppColors.secondaryTextColor,
                            ),
                            _buildAmentityWidget(
                                iconImage: AppIconAssets.call,
                                text: rentalServiceData.contactNumber ?? 'N/A'
                            ),
                          ],
                        )
                      ),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    Row(
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.location_outline,
                            imgColor: AppColors.primaryColor
                        ),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          rentalServiceData.address,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.small11,
                          color: AppColors.primaryColor
                        ),
                      ],
                    )

                  ],
                )
            ),

            SizedBox(height: SizeConfig.size10),

            if(rentalServiceData.highlights?.isNotEmpty ?? false)
            CustomFormCard(
                margin: EdgeInsets.only(top: SizeConfig.size10),
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Highlights',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),

                    SizedBox(height: SizeConfig.size6),

                    Container(
                      width: SizeConfig.screenWidth,
                      color: AppColors.whiteE0,
                      height: 0.5,
                    ),

                    SizedBox(height: SizeConfig.size10),

                    Column(
                      children: rentalServiceData.highlights!
                          .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: SizeConfig.size6,
                              width: SizeConfig.size6,
                              decoration: BoxDecoration(
                                  color: AppColors.secondaryTextColor,
                                  shape: BoxShape.circle
                              ),
                            ),
                            SizedBox(width: SizeConfig.size6),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ))
                          .toList()
                    )


                  ],
                )
            ),

            // if(type == RentalServiceType.homeStay)
            // if(rentalServiceData.propertyDetails?.restrictions?.isNotEmpty ?? false)
            //   CustomFormCard(
            //       margin: EdgeInsets.only(top: SizeConfig.size10),
            //       padding: EdgeInsets.all(SizeConfig.size10),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           CustomText(
            //             'Restrictions',
            //             fontSize: SizeConfig.medium,
            //             fontWeight: FontWeight.w600,
            //             color: AppColors.mainTextColor,
            //           ),
            //
            //           SizedBox(height: SizeConfig.size6),
            //
            //           Container(
            //             width: SizeConfig.screenWidth,
            //             color: AppColors.whiteE0,
            //             height: 0.5,
            //           ),
            //
            //           SizedBox(height: SizeConfig.size10),
            //
            //           Column(
            //               children: rentalServiceData.highlights!
            //                   .map((e) => Padding(
            //                 padding: const EdgeInsets.symmetric(vertical: 4),
            //                 child: Row(
            //                   crossAxisAlignment: CrossAxisAlignment.center,
            //                   children: [
            //                     Container(
            //                       height: SizeConfig.size6,
            //                       width: SizeConfig.size6,
            //                       decoration: BoxDecoration(
            //                           color: AppColors.secondaryTextColor,
            //                           shape: BoxShape.circle
            //                       ),
            //                     ),
            //                     SizedBox(width: SizeConfig.size6),
            //                     Expanded(
            //                       child: Text(
            //                         e,
            //                         style: const TextStyle(fontSize: 14),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ))
            //                   .toList()
            //           )
            //
            //
            //         ],
            //       )
            //   ),

          ]
        )
      ),
    );
  }

  Widget _buildAmentityWidget({required String iconImage, required String text}){
    return Row(
      children: [
        LocalAssets(imagePath: iconImage, imgColor: AppColors.secondaryTextColor),
        SizedBox(width: SizeConfig.size6),
        CustomText(
          text,
          fontWeight: FontWeight.w400,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

}
