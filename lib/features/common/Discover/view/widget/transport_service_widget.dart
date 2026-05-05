import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/parcel_pickup_drop_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class TransportServiceWidget extends StatelessWidget {
  const TransportServiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => const ParcelPickupDropScreen());
      },
      child: CustomFormCard(
        color: AppColors.white,
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget(AppStrings.bookYourTransport),
            SizedBox(height: SizeConfig.paddingXSL),
            CustomFormCard(
              color: AppColors.blue5CFF,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.all(SizeConfig.size12),
              border: Border.all(
                color: AppColors.greyE5,
              ),
              child: Column(
                children: [
                  CustomFormCard(
                    border: Border.all(
                        color: AppColors.greyE5
                    ),
                    padding: EdgeInsets.all(SizeConfig.size10),
                    // IntrinsicHeight ensures the vertical line stretches to match the fields
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // 1. LEFT SECTION: Icons and Dotted Line
                          Column(
                            children: [
                              const Icon(Icons.home_outlined,
                                  color: AppColors.secondaryTextColor, size: 16),

                              // The Dotted Line
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: CustomPaint(
                                    size: const Size(1, double.infinity),
                                    painter: DottedLinePainter(),
                                  ),
                                ),
                              ),

                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.redLite, size: 16),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // 2. MIDDLE SECTION
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // From
                                CustomText(
                                    "${LocationService.userCurrentAddress.value.formattedAddress}",
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                ),

                                SizedBox(height: SizeConfig.paddingS),

                                // Divider
                                CommonHorizontalDivider(
                                    height: 1,
                                    color: AppColors.greyE5
                                ),

                                SizedBox(height: SizeConfig.paddingS),

                                // To
                                CustomText(
                                    AppStrings.toLabel.tr,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400)
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 3. RIGHT SECTION: Swap Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              // border: Border.all(color: AppColors.greyE5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(0, 1.1),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                )],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert,
                                  color: AppColors.secondaryTextColor),
                              onPressed: () {
                                // Add swap logic here
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  LayoutBuilder(builder: (context, constraints) {
                    const double spacing = 8;
                    const int columns = 3;
                    final double itemWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) / columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: transportItemsCategories.map((item) {
                        return SizedBox(
                          width: itemWidth,
                          child: CommonServiceCard(
                            service: item,
                            getName: (i) => i.name,
                            getIcon: (i) => i.icon ?? "",
                            onTap: (_) {
                              Get.to(() => ParcelPickupDropScreen(
                                    vehicleType: item.slugId,
                                  ));
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            )


          ],
        ),
      ),
    );
  }
}
