import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayDetailsWidget extends StatelessWidget {
  final RentalServiceData service;

  const HomeStayDetailsWidget({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistance(
        service.location?.coordinates?[1].toDouble() ?? 0.0,
        service.location?.coordinates?[0].toDouble() ?? 0.0);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: service.name,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonCardWidget(
              padding: 0,
              cardMargin: 0,
              child: Column(
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
                                boxFix: BoxFit.cover,
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
                            // Opens the host's personal profile — home
                            // stays are always listed by individuals.
                            child: DiscoverProfileTap(
                              accountType: AppConstants.individual,
                              userId: service.userId,
                              child: (service.images?.isNotEmpty ?? false)
                                  ? CachedAvatarWidget(
                                      imageUrl: service.images![0],
                                      size: SizeConfig.size65,
                                      borderColor: Colors.white,
                                      borderRadius: SizeConfig.size40,
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.size40),
                                      child: LocalAssets(
                                        imagePath:
                                            AppIconAssets.place_holder_image,
                                        height: SizeConfig.size65,
                                        width: SizeConfig.size65,
                                      ),
                                    ),
                            ),
                          ))
                    ],
                  ),
                  SizedBox(
                    height: SizeConfig.size40,
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(left: SizeConfig.size20,right: SizeConfig.size10),
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
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //     vertical: SizeConfig.size3,
                        //     horizontal: SizeConfig.size10,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(12.0),
                        //     border: Border.all(
                        //         color: AppColors.secondaryTextColor,
                        //         width: 0.5),
                        //   ),
                        //   child: CustomText('5 Star',
                        //       fontSize: SizeConfig.small,
                        //       color: AppColors.secondaryTextColor,
                        //       fontWeight: FontWeight.w400),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size8,
                  ),
                  Padding(
                    padding:
                    EdgeInsets.only(left: SizeConfig.size20,right: SizeConfig.size10),
                    child: Row(
                      children: [
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //     vertical: SizeConfig.size3,
                        //     horizontal: SizeConfig.size10,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(12.0),
                        //     border: Border.all(
                        //         color: AppColors.secondaryTextColor, width: 0.5),
                        //   ),
                        //   child: CustomText('5 Star',
                        //       fontSize: SizeConfig.small,
                        //       color: AppColors.secondaryTextColor,
                        //       fontWeight: FontWeight.w400),
                        // ),
                        SizedBox(
                          width: SizeConfig.size5,
                        ),
                        CommonRatingRow(
                          rating:
                              double.tryParse(service.rating.toString()) ?? 0.0,
                          reviews: service.reviews ?? 0,
                          distance: '${distance?.toStringAsFixed(2)} KM',
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size12,
                  ),
                  Padding(
                    padding:
                    EdgeInsets.only(left: SizeConfig.size20,right: SizeConfig.size10),
                    child: ExpandableText(
                      text: service.description ?? AppStrings.na,
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
                    '₹${service.price}/${service.priceUnit}',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),


            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title:  'Important Places Distance',
                  ),

                  SizedBox(height: SizeConfig.size8),
                  Container(
                    color: AppColors.transparent,
                    height: 0.5,
                    width: SizeConfig.screenWidth,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    children: [
                      Icon(Icons.bus_alert_outlined,
                          color: AppColors.secondaryTextColor),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        service.nearbyLocations?.railwayStation??"N/A",
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                      ),
                    ],
                  ),

                ],
              ),
            ),


            // Check In & Check Out Timing
            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title:   'Check In & Check Out Timing',
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText("Check In: ",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.green39),
                        CustomText('9:00 AM',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor),
                        CustomText("  |  ",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor),
                        CustomText("Check Out: ",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.red),
                        CustomText('9:00 PM',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            if (service.type == 'Property') ...[
              // --- SECTION 1: (AMENITIES) ---
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title:   'Resort Amenities',
                    ),


                    SizedBox(height: SizeConfig.size8),
                    Container(
                        color: AppColors.transparent,
                        height: 0.5,
                        width: SizeConfig.screenWidth),
                    SizedBox(height: SizeConfig.size8),
                    Builder(
                      builder: (context) {
                        final List<String> highlights =
                            service.highlights ?? [];

                        if (highlights.isEmpty) {
                          return CustomText(
                            'No Amenities Available',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            highlights.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 8.0, right: 8.0),
                                    width: 4.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryTextColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      highlights[index],
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),


              // --- SECTION 2: GALLERY ---
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title:  'Gallery',
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                        color: AppColors.transparent,
                        height: 0.5,
                        width: SizeConfig.screenWidth),
                    SizedBox(height: SizeConfig.size8),
                    Builder(
                      builder: (context) {
                        final p = service.propertyDetails;
                        final List<String> allImages = [
                          ...?p?.roomImages,
                          ...?p?.kitchenImages,
                          ...?p?.bathroomImages,
                          ...?p?.roadImages,
                          ...?p?.otherImages,
                        ];

                        // Reusing the helper method _buildPhotoGrid from the previous step
                        // If you removed it, paste the grid logic here instead.
                        return _buildPhotoGrid(allImages, context);
                      },
                    ),
                  ],
                ),
              ),


              // CommonCardWidget SECTION 3: RESTRICTIONS ---
              CommonCardWidget(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceHomeTitleWidget(
                      title:   'House Rules & Restrictions',
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Container(
                        color: AppColors.transparent,
                        height: 0.5,
                        width: SizeConfig.screenWidth),
                    SizedBox(height: SizeConfig.size8),
                    Builder(
                      builder: (context) {
                        // 1. Logic to create the list of strings
                        List<String> rules = [];
                        var restrictions =
                            service.propertyDetails?.restrictions;
                        // var restrictions = service.propertyDetails?.;

                        if (restrictions != null) {
                          if (restrictions.unmarriedCoupleAllowed != null) {
                            rules.add(restrictions.unmarriedCoupleAllowed!
                                ? "Unmarried Couples Allowed"
                                : "Unmarried Couples Not Allowed");
                          }
                          if (restrictions.studentOrBachelorAllowed != null) {
                            rules.add(restrictions.studentOrBachelorAllowed!
                                ? "Students/Bachelors Allowed"
                                : "Students/Bachelors Not Allowed");
                          }
                          if (restrictions.foodRestriction != null) {
                            rules.add(restrictions
                                        .foodRestriction?.isFoodRestriction ==
                                    false
                                ? '${restrictions.foodRestriction?.allowedFood} Allowed'
                                : "No Food Restriction");
                          }
                          if (restrictions.pets != null) {
                            rules.add(restrictions.pets!
                                ? "Pets Allowed"
                                : "No Pets Allowed");
                          }
                          if (restrictions.smoking != null) {
                            rules.add(restrictions.smoking!
                                ? "Smoking Allowed"
                                : "No Smoking");
                          }
                          if (service.additionalRules != null) {
                            rules.addAll(service.additionalRules!);
                          }
                        }

                        // 2. Inline Rendering (Same as Amenities above)
                        if (rules.isEmpty) {
                          return CustomText(
                            'No Restrictions Specified',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            rules.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 8.0, right: 8.0),
                                    width: 4.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryTextColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      rules[index],
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0,vertical: 10),
              child: CustomBtn(
                onTap: () {
                  commonSnackBar(message: 'coming soon');
                },
                isValidate: true,
                radius: SizeConfig.size10,
                title: 'Book Now',
                // isLoading: authController.isAddBusinessUserLoading.value
              ),
            ),
            SizedBox(height: kBottomNavigationBarHeight,),
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
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          width: SizeConfig.size80,
                          height: SizeConfig.size80,
                        ),
                        errorWidget: (context, url, error) => Container(
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
    );
  }
}
