import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessAllServiceCard extends StatefulWidget {
  final List<GetServiceModel> allServices;

  const BusinessAllServiceCard({super.key, required this.allServices});

  @override
  State<BusinessAllServiceCard> createState() => _BusinessAllServiceCardState();
}

class _BusinessAllServiceCardState extends State<BusinessAllServiceCard> {
  late final List<GlobalKey> _cardKey;
  late final List<GetServiceModel> _allServices;

  @override
  void initState() {
    super.initState();
    _allServices = widget.allServices;
    _cardKey = List.generate(_allServices.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = 2;
        final crossSpacing = 10.0;
        final mainSpacing = 10.0;

        final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
        final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

        final approximateItemHeight = SizeConfig.size330;

        final childAspectRatio = itemWidth / approximateItemHeight;

        return GridView.builder(
          // controller: storesScrollController,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _allServices.length,
          itemBuilder: (context, index) {
            final serviceData = _allServices[index];
            Discounts? maxDiscount;
            if ((serviceData.discounts?.length ?? 0) > 0)
              maxDiscount = serviceData.discounts
                  ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

            DateTime parse12HourTime(String timeStr) {
              final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
              final match = format.firstMatch(timeStr.trim());

              if (match != null) {
                int hour = int.parse(match.group(1)!);
                int minute = int.parse(match.group(2)!);
                final period = match.group(3);

                if (period == "PM" && hour != 12) hour += 12;
                if (period == "AM" && hour == 12) hour = 0;

                return DateTime(0, 1, 1, hour, minute);
              }

              return DateTime(0); // fallback
            }

            Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
              if (timingsList == null || timingsList.isEmpty) return {"start": "--", "end": "--"};

              Timings? earliest = timingsList.first;
              Timings? latest = timingsList.first;

              for (final t in timingsList) {
                final startTime = parse12HourTime(t.start ?? "00:00 AM");
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


            final timingMap = getMinMaxTimings(serviceData.timings);

            return RepaintBoundary(
              key: _cardKey[index],
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.blueLightShade,
                  boxShadow:  [AppShadows.cardShadow],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.transparent,
                      width: 1.5
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        CustomImageSlideshow(
                          isLoading: false,
                          height: SizeConfig.size150,
                          width: double.infinity,
                          imagePaths: serviceData.photos ?? [],
                          borderRadius: BorderRadius.circular(10),                            // fit: BoxFit.cover,
                        ),

                        SizedBox(height: SizeConfig.size5),

                        Padding(
                          padding: EdgeInsets.all(SizeConfig.size8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              CustomText(
                                serviceData.title ?? AppStrings.na,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                color: AppColors.mainTextColor,
                              ),

                              SizedBox(height: SizeConfig.size5),

                              // CustomText(
                              //   serviceData.description ?? '',
                              //   fontSize: SizeConfig.small,
                              //   overflow: TextOverflow.ellipsis,
                              //   maxLines: 2,
                              //   color: AppColors.secondaryTextColor,
                              //   fontWeight: FontWeight.w400,
                              // ),
                              // SizedBox(height: SizeConfig.size4),

                              // Title & price
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomText(
                                        AppStrings.pricePrefix,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor
                                    ),

                                    CustomText(
                                        "₹${serviceData.priceRange?.min} - ₹${serviceData.priceRange?.max}",
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryColor
                                    ),
                                    const SizedBox(width: 6),
                                    CustomText(
                                        (maxDiscount?.amountOff != null)
                                            ? "${maxDiscount?.amountOff.toString()}% ${AppStrings.off.tr}"
                                            : "0% ${AppStrings.off.tr}",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.green.shade600
                                    ),
                                    const SizedBox(width: 6),
                                    CustomText(
                                        "₹${serviceData.priceRange?.max}",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                        decoration: TextDecoration.lineThrough
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: SizeConfig.size3),

                              // Open | close
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomText(
                                        "${AppStrings.open.tr}: ",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.green39
                                    ),

                                    CustomText(
                                        timingMap["start"]!,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor
                                    ),

                                    CustomText(
                                        "  |  ",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor
                                    ),


                                    CustomText(
                                        "${AppStrings.close.tr}: ",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.red
                                    ),

                                    CustomText(
                                        timingMap["end"]!,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: SizeConfig.size4),

                              CustomText(
                                  serviceData.business?.categoryOfBusiness?.name ?? AppStrings.na,
                                  fontSize: SizeConfig.small,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  color: AppColors.secondaryTextColor
                              ),

                              SizedBox(height: SizeConfig.size3),
                              CustomText(
                                  serviceData.business?.businessName ?? AppStrings.na,
                                  fontSize: SizeConfig.small,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  color: AppColors.secondaryTextColor
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),


                    Spacer(),

                    Column(
                      children: [
                        CommonHorizontalDivider(
                          color: Colors.grey,
                        ),

                        InkWell(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                          onTap: () async {
                            final currentService = _allServices[index];
                            await VisitingCardHelper().shareVisitingCard(
                                _cardKey[index],
                                serviceId: currentService.id
                            );
                          },
                          child: Container(
                            color: AppColors.white,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size8,
                                vertical: SizeConfig.size8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LocalAssets(
                                      imagePath: AppIconAssets.share_bold,
                                      imgColor: AppColors.primaryColor
                                  ),
                                  SizedBox(width: SizeConfig.size8),
                                  CustomText(
                                      AppStrings.share,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.medium,
                                      fontFamily: AppConstants.OpenSans
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // InkWell(
                        //   borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                        //   onTap: () async {
                        //     final currentService = _allServices[index];
                        //     await VisitingCardHelper().shareVisitingCard(
                        //         _cardKey[index],
                        //         serviceId: currentService.id
                        //     );
                        //   },
                        //   child: Padding(
                        //     padding: EdgeInsets.symmetric(
                        //       horizontal: SizeConfig.size8,
                        //       vertical: SizeConfig.size8,
                        //     ),
                        //     child: FittedBox(
                        //       fit: BoxFit.scaleDown,
                        //       child: Row(
                        //         children: [
                        //           CustomText(
                        //               AppStrings.shareCardToSocialMediaGrowBusiness,
                        //               color: AppColors.secondaryTextColor,
                        //               fontWeight: FontWeight.w400,
                        //               fontSize: SizeConfig.small,
                        //               fontFamily: AppConstants.OpenSans),
                        //           SizedBox(width: SizeConfig.size8),
                        //           LocalAssets(
                        //               imagePath: AppIconAssets.share_bold,
                        //               imgColor: AppColors.primaryColor
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    )

                  ],
                ),
              ),
            );
          },
        );

      },
    );
  }

}
