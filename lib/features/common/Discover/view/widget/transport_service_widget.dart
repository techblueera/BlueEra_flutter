import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/book_transport_main.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class TransportServiceWidget extends StatelessWidget {
  const TransportServiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(BookTransportMain());
      },
      child: CustomFormCard(
        color: AppColors.whiteFC,
        borderRadius: BorderRadius.circular(0),
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget(AppStrings.bookYourTransport),
            SizedBox(height: SizeConfig.paddingXSL),
            CustomFormCard(
              isBorderAvailable: true,
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
                              color: AppColors.greyBf,
                              fontWeight: FontWeight.w400),

                          SizedBox(height: SizeConfig.paddingS),

                          // Divider
                          CommonHorizontalDivider(
                              height: 1, color: AppColors.greyBf),

                          SizedBox(height: SizeConfig.paddingS),

                          // To
                          CustomText("To",
                              fontSize: SizeConfig.medium,
                              color: AppColors.greyBf,
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
                        border: Border.all(color: AppColors.greyE5),
                        boxShadow: [AppShadows.textFieldShadow],
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
            MasonryGridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              padding: EdgeInsets.zero,
              primary: false,
              shrinkWrap: true,
              itemCount: transportItemsCategories.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var item = transportItemsCategories[index];
                return CommonServiceCard(
                  service: item,
                  getName: (item) => item.name,
                  getIcon: (item) => item.icon ?? "",
                  // iconHeight: SizeConfig.size60,
                  flex: 1,
                  onTap: (_) {
                    Get.to(() => BookTransportMain(
                          vehicleType: item.slugId,
                        ));
                  },
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}
