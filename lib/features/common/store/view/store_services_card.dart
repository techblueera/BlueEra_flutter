import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreServicesCard extends StatelessWidget {
  final GetServiceModel? serviceData;
  const StoreServicesCard({Key? key, this.serviceData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Discounts? maxDiscount;
    if ((serviceData?.discounts?.length ?? 0) > 0)
      maxDiscount = serviceData?.discounts
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


    final timingMap = getMinMaxTimings(serviceData?.timings);


    return InkWell(
      onTap: (){
        Get.to(ServiceDetailsScreen(
          service: serviceData ?? GetServiceModel(),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteFE,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 1.4,
              offset: const Offset(0, 0.7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CustomImageSlideshow(
                isLoading: false,
                height: 200,
                width: 140,
                imagePaths: serviceData?.photos ?? [],
                borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
                // fit: BoxFit.cover,
              ),

            SizedBox(height: SizeConfig.size5),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            serviceData?.title ?? "N/A",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    CustomText(
                      serviceData?.description ?? '',
                      fontSize: SizeConfig.small,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size6),

                    // Title & price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(
                            "Price: ",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor
                        ),

                        CustomText(
                            "₹${serviceData?.priceRange?.min} - ₹${serviceData?.priceRange?.max}",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                            (maxDiscount?.amountOff != null)
                                ? "${maxDiscount?.amountOff.toString()}% Off"
                                : "0% Off",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: Colors.green.shade600
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                            "₹${serviceData?.priceRange?.max}",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),

                    // Open | close
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(
                            "Open: ",
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
                            "Close: ",
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
                    SizedBox(height: SizeConfig.size5),

                    CustomText(
                    serviceData?.business?.categoryOfBusiness?.name ?? "N/A",
                    fontSize: SizeConfig.small,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    color: AppColors.secondaryTextColor
                  ),

                    SizedBox(height: SizeConfig.size5),
                    CustomText(
                      serviceData?.business?.businessName ?? "N/A",
                      fontSize: SizeConfig.small,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      color: AppColors.secondaryTextColor
                    ),
                    SizedBox(height: SizeConfig.size5),

                    StoreKmAwayTextWidget(
                      lat: serviceData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
                      long: serviceData?.business?.businessLocation?.lon?.toDouble() ?? 0.0,
                      isUnderlineShow: false,
                      isPadding: 4.0,
                    ),

                    SizedBox(height: SizeConfig.size10),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
