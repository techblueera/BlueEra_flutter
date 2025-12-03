import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';

class RentalServiceFullDetailsScreen extends StatelessWidget {
  final RentalServiceData rentalServiceData;

  const RentalServiceFullDetailsScreen(
      {super.key, required this.rentalServiceData});

  @override
  Widget build(BuildContext context) {
    final item = rentalServiceData;
    RentalServiceType? type = rentalServiceData.type?.toRentalServiceType();

    List<String>? getAllPropertyImages() {
      PropertyDetails? propertyDetails = item.propertyDetails;
      if (propertyDetails == null) return null;
      final List<String> all = [];

      if (propertyDetails.roomImages != null)
        all.addAll(propertyDetails.roomImages!);
      if (propertyDetails.kitchenImages != null)
        all.addAll(propertyDetails.kitchenImages!);
      if (propertyDetails.bathroomImages != null)
        all.addAll(propertyDetails.bathroomImages!);
      if (propertyDetails.roadImages != null)
        all.addAll(propertyDetails.roadImages!);
      if (propertyDetails.otherImages != null)
        all.addAll(propertyDetails.otherImages!);

      return all;
    }

    List<String>? getAllVehicleImages() {
      VehicleDetails? vehicleDetails = item.vehicleDetails;
      if (vehicleDetails == null) return null;
      final List<String> all = [];

      if (vehicleDetails.vehicleFrontImage != null)
        all.addAll(vehicleDetails.vehicleFrontImage!);
      if (vehicleDetails.vehicleBackImage != null)
        all.addAll(vehicleDetails.vehicleBackImage!);
      if (vehicleDetails.vehicleLeftSideImage != null)
        all.addAll(vehicleDetails.vehicleLeftSideImage!);
      if (vehicleDetails.vehicleRightHandSideImage != null)
        all.addAll(vehicleDetails.vehicleRightHandSideImage!);

      return all;
    }

    List<String>? images;
    if (type == RentalServiceType.vehicle) {
      images = getAllVehicleImages();
    } else {
      images = getAllPropertyImages();
    }

    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: Column(children: [
            // ---- IMAGE ----
            (images != null && images.isNotEmpty)
                ? InkWell(
                    onTap: () {
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
                        imagePaths: images,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  )
                : LocalAssets(
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
                          ? AppStrings.vehicleDetails
                          : AppStrings.homeDetails,
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
                    CustomText(rentalServiceData.name,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.large,
                        color: AppColors.secondaryTextColor),
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
                              vertical: SizeConfig.size12),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size4),
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.05)),
                          child: (type == RentalServiceType.vehicle)
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildAmentityWidget(
                                        iconImage: AppIconAssets.seatIcon,
                                        text:
                                            '${rentalServiceData.propertyDetails?.beds ?? 0} ${AppStrings.seats}'),
                                    CommonVerticalDivider(
                                      width: 0.5,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    _buildAmentityWidget(
                                        iconImage: AppIconAssets.fuelIcon,
                                        text:
                                            '${rentalServiceData.propertyDetails?.maxPeople?.adults ?? 0} ${AppStrings.beds}, ${rentalServiceData.propertyDetails?.maxPeople?.children ?? 0} ${AppStrings.child}'),
                                    CommonVerticalDivider(
                                      width: 0.5,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    _buildAmentityWidget(
                                        iconImage: AppIconAssets.call,
                                        text: rentalServiceData.contactNumber ??
                                            AppStrings.na),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildAmentityWidget(
                                        iconImage: AppIconAssets.bedIcon,
                                        text:
                                            '${rentalServiceData.propertyDetails?.beds ?? 0} ${AppStrings.beds.tr}'),
                                    CommonVerticalDivider(
                                      width: 0.5,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    _buildAmentityWidget(
                                        iconImage:
                                            AppIconAssets.multiPersonsIcon,
                                        text:
                                            '${rentalServiceData.propertyDetails?.maxPeople?.adults ?? 0} ${AppStrings.beds.tr}, ${rentalServiceData.propertyDetails?.maxPeople?.children ?? 0} ${AppStrings.child.tr}'),
                                    CommonVerticalDivider(
                                      width: 0.5,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    _buildAmentityWidget(
                                        iconImage: AppIconAssets.call,
                                        text: rentalServiceData.contactNumber ??
                                            AppStrings.na),
                                  ],
                                )),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    Row(
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.location_outline,
                            imgColor: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child: CustomText(rentalServiceData.address,
                              fontWeight: FontWeight.w400,
                              fontSize: SizeConfig.small11,
                              color: AppColors.primaryColor),
                        ),
                      ],
                    )
                  ],
                )),

            SizedBox(height: SizeConfig.size10),

            if (rentalServiceData.highlights?.isNotEmpty ?? false)
              buildHighlightsWidget(rentalServiceData.highlights!),

            _buildRestrictionsSection(type),
          ])),
    );
  }

  Widget _buildAmentityWidget(
      {required String iconImage, required String text}) {
    return Row(
      children: [
        LocalAssets(
            imagePath: iconImage, imgColor: AppColors.secondaryTextColor),
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

  Widget buildHighlightsWidget(List<String> highlights) {
    if (highlights.isEmpty) return const SizedBox();

    if (kDebugMode) {
      highlights.forEach(print);
    }

    return CustomFormCard(
      margin: EdgeInsets.only(top: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.highlights,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(
                highlights.length,
                (index) {
                  final e = highlights[index];
                  final isFirst = index == 0;
                  final isLast = index == highlights.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(
                      top: isFirst ? 0 : 4,
                      bottom: isLast ? 0 : 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LocalAssets(imagePath: AppIconAssets.blueStarsIcon),
                        SizedBox(width: SizeConfig.size6),
                        Expanded(
                          child: CustomText(
                            e,
                            fontSize: SizeConfig.small,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRestrictionsSection(RentalServiceType? type) {
    final hasRules = (rentalServiceData.additionalRules?.isNotEmpty ?? false);

    if (type == RentalServiceType.vehicle && !hasRules) {
      return const SizedBox();
    }

    final rules = rentalServiceData.additionalRules ?? [];

    List<Widget> restrictionItems = [];

    // -----------------------------
    //  PROPERTY RESTRICTIONS
    // -----------------------------
    if (type != RentalServiceType.vehicle) {
      // 1. Unmarried couple allowed
      restrictionItems.add(
        _restrictionRow(
          rentalServiceData.propertyDetails?.restrictions?.unmarriedCoupleAllowed == false
              ? AppStrings.unmarriedCouplesNotAllowed
              : AppStrings.unmarriedCouplesAllowed,
        ),
      );

      // 2. Student / bachelor allowed
      restrictionItems.add(
        _restrictionRow(
          rentalServiceData.propertyDetails?.restrictions?.studentOrBachelorAllowed == false
              ? AppStrings.studentsBachelorsNotAllowed
              : AppStrings.studentsBachelorsAllowed,
        ),
      );

      // 3. Food restriction
      final foodR = rentalServiceData.propertyDetails?.restrictions?.foodRestriction;
      restrictionItems.add(
        _restrictionRow(
          foodR?.isFoodRestriction == true
              ? '${AppStrings.foodRestriction.tr}: ${foodR?.allowedFood ?? ''}'
              : AppStrings.noFoodRestrictions,
        ),
      );
    }

    // -----------------------------
    //  VEHICLE RESTRICTIONS
    // -----------------------------
    if (hasRules) {
      restrictionItems.addAll(
        rules.map((e) => _restrictionRow(e)).toList(),
      );
    }

    // -----------------------------
    // REMOVE BOTTOM PADDING FOR LAST ITEM
    // -----------------------------
    for (int i = 0; i < restrictionItems.length; i++) {
      restrictionItems[i] = Padding(
        padding: EdgeInsets.only(
          top: i == 0 ? 0 : 4,
          bottom: i == restrictionItems.length - 1 ? 0 : 10, //  No bottom padding for last
        ),
        child: restrictionItems[i],
      );
    }

    return CustomFormCard(
      margin: EdgeInsets.only(top: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.restrictions,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          Container(
            width: SizeConfig.screenWidth,
            height: 0.5,
            color: AppColors.whiteE0,
          ),

          SizedBox(height: SizeConfig.size10),

          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.redLite.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: restrictionItems),
          ),
        ],
      ),
    );
  }

// 🔹 Reusable row widget
  Widget _restrictionRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalAssets(imagePath: AppIconAssets.warningOutlineIcon),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

}
