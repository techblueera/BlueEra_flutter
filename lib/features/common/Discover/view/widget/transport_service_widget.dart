import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/ride_booking/view/ride_home_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class TransportServiceWidget extends StatelessWidget {
  const TransportServiceWidget({super.key, this.targetRiderKey});
  final GlobalKey? targetRiderKey;

  @override
  Widget build(BuildContext context) {
    // Landing grid (see [DiscoverFolderScope]): this is the one section with a
    // hand-rolled card rather than a DiscoverGridSection, so it opts into
    // folder mode itself. The pickup/drop card lives inside the sheet.
    if (DiscoverFolderScope.isActive(context)) {
      final host = DiscoverFolderHost.sectionOf(context);
      return DiscoverFolderTile(
        title: AppStrings.bookYourTransport.tr,
        iconPaths:
            transportItemsCategories.map((e) => e.icon ?? '').toList(),
        expandedBuilder: (ctx) => host ?? _fullCard(ctx),
      );
    }
    return Builder(
      key: targetRiderKey,
      builder: _fullCard,
    );
  }

  Widget _fullCard(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              CustomText(
                AppStrings.bookYourTransport.tr,
                fontSize: SizeConfig.large18,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: SizeConfig.size16),

              // From / To pickup-drop card
              _pickupDropCard(),
              SizedBox(height: SizeConfig.size16),

              // Circular transport-type grid (5 per row)
              LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 8;
                  const int columns = 5;
                  final double itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: SizeConfig.size16,
                    children: transportItemsCategories.map((item) {
                      return SizedBox(
                        width: itemWidth,
                        child: DiscoverIconTile(
                          name: item.name,
                          iconPath: item.icon ?? "",
                          diameter: itemWidth * 0.9,
                          onTap: () => Get.to(() => const RideHomeScreen()),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
  }

  Widget _pickupDropCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.to(() => const RideHomeScreen()),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 1. LEFT: colored dots joined by a dotted line
              Column(
                children: [
                  _dot(AppColors.green0B),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: CustomPaint(
                        size: const Size(1, double.infinity),
                        painter: DottedLinePainter(),
                      ),
                    ),
                  ),
                  _dot(AppColors.redLite),
                ],
              ),
              const SizedBox(width: 12),

              // 2. MIDDLE: From / To labels
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final address = LocationService
                          .userCurrentAddress.value.formattedAddress;
                      final from = (address.isNotEmpty)
                          ? address
                          : "Enter pickup location";
                      return CustomText(
                        "From — $from",
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }),
                    SizedBox(height: SizeConfig.paddingS),
                    Divider(height: 1, color: AppColors.greyE5),
                    SizedBox(height: SizeConfig.paddingS),
                    CustomText(
                      "To — Enter destination",
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 3. RIGHT: bordered square swap button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5),
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
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
