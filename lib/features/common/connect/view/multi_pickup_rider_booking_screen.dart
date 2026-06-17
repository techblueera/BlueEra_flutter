import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/multi_shop_rider_model.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/book_transport_main.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-shop (multi-stop) ride booking screen.
///
/// Renders the sorted route returned by `POST /fare/multi-shop/riders`
/// (pickups farthest→nearest, then the single drop), the In-City vehicle
/// options + nearby riders, and books the order via
/// `POST /fare/multi-shop/orders`. Booking reuses the existing fare-call
/// queue flow ([FareCallQueueScreen]).
///
/// The riders request is fired by [InquiryRideOrderSelectionScreen] before
/// this screen opens, so [DiscoverController] already holds the sorted shops
/// + riders by the time we build.
class MultiPickupRiderBookingScreen extends StatefulWidget {
  const MultiPickupRiderBookingScreen({
    super.key,
    required this.pickups,
    required this.dropAddress,
  });

  /// Selected inquiry conversations used as pickup points (pre-resolution).
  final List<ChatList> pickups;

  /// The already-selected drop location.
  final SavedAddress dropAddress;

  @override
  State<MultiPickupRiderBookingScreen> createState() =>
      _MultiPickupRiderBookingScreenState();
}

class _MultiPickupRiderBookingScreenState
    extends State<MultiPickupRiderBookingScreen> {
  final discoverController = getOrPut(() => DiscoverController());

  // In-City vehicle choices (same set / order as the transport flow, so the
  // shared `getSelectedVehicleData(response, 0, index)` mapping applies).
  List<TransportCategoryDetailsModel> get optionList => [
        TransportCategoryDetailsModel(
            name: AppStrings.transportBike.tr,
            svgImage: AppIconAssets.transport_bike),
        TransportCategoryDetailsModel(
            name: AppStrings.transportTaxi.tr,
            svgImage: AppIconAssets.transport_taxi),
        TransportCategoryDetailsModel(
            name: AppStrings.transportAuto.tr,
            svgImage: AppIconAssets.transport_auto),
        TransportCategoryDetailsModel(
            name: AppStrings.transportERickshaw.tr,
            svgImage: AppIconAssets.transport_big_auto),
      ];

  Future<void> _onCallToRider() async {
    // Setup queue listeners BEFORE the API call so we don't miss
    // ride:queue:calling if the server fires it immediately after creation.
    discoverController.setupFareCallQueueListeners();
    final success = await discoverController.makeMultiShopOrderApi();
    if (success && discoverController.selectedRiders.isNotEmpty) {
      Get.to(() => FareCallQueueScreen(
            orderId: discoverController.fareCallOrderId.value,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: 'Book Rider'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Obx(
            () => CustomBtn(
              height: 44,
              isLoading: discoverController.bookRiderBtnLoading.value,
              isValidate: discoverController.selectedRiders.isNotEmpty,
              onTap: _onCallToRider,
              title: AppStrings.callToRider.tr,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                /// Route card — multiple pickups + single drop.
                Obx(() => _buildRouteCard()),

                const SizedBox(height: 16),

                /// Vehicle options (In City).
                _buildVehicleOptions(),

                SizedBox(height: SizeConfig.size16),
                CustomText(AppStrings.chooseYourRider.tr,
                    fontSize: 16, fontWeight: FontWeight.w600),
                SizedBox(height: SizeConfig.size12),

                /// Rider list (from the multi-shop riders response).
                _buildRiderList(),

                SizedBox(height: SizeConfig.size30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    final shops = discoverController.multiShopSortedShops;
    final routeKm = discoverController.multiShopRouteDistanceKm.value;
    // Number of pickups: sorted shops if available, else the raw selection.
    final pickupCount = shops.isNotEmpty ? shops.length : widget.pickups.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppShadows.bottomShadow],
        color: AppColors.white,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route,
                  size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  '$pickupCount pickup${pickupCount == 1 ? '' : 's'} • 1 drop',
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (routeKm > 0)
                CustomText(
                  '${routeKm.toStringAsFixed(1)} km',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup points (sequence 0 = farthest from drop = route start).
          if (shops.isNotEmpty)
            ...List.generate(shops.length, (i) {
              final SortedShop shop = shops[i];
              return _routeStop(
                index: i + 1,
                isLast: false,
                title: shop.name.isNotEmpty ? shop.name : 'Pickup ${i + 1}',
                subtitle: i == 0
                    ? (shop.address.isNotEmpty
                        ? shop.address
                        : 'Farthest pickup')
                    : (shop.address.isNotEmpty
                        ? shop.address
                        : 'Pickup point ${i + 1}'),
                dotColor: AppColors.primaryColor,
                highlight: i == 0,
              );
            })
          else
            // Fallback before the sorted response is available.
            ...List.generate(widget.pickups.length, (i) {
              final chat = widget.pickups[i];
              return _routeStop(
                index: i + 1,
                isLast: false,
                title: chat.sender?.name ?? 'Pickup ${i + 1}',
                subtitle: i == 0 ? 'Farthest pickup' : 'Pickup point ${i + 1}',
                dotColor: AppColors.primaryColor,
                highlight: i == 0,
              );
            }),

          // Drop point (the user's location).
          _routeStop(
            index: null,
            isLast: true,
            title: widget.dropAddress.label.isNotEmpty
                ? widget.dropAddress.label
                : 'Drop location',
            subtitle: widget.dropAddress.fullAddress,
            dotColor: AppColors.red00,
            highlight: false,
          ),
        ],
      ),
    );
  }

  /// One stop in the route column. A numbered/coloured dot with a connecting
  /// line (omitted for [isLast]) beside the stop's title + subtitle.
  Widget _routeStop({
    required int? index,
    required bool isLast,
    required String title,
    required String subtitle,
    required Color dotColor,
    required bool highlight,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: index != null
                    ? CustomText('$index',
                        fontSize: SizeConfig.size11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)
                    : const Icon(Icons.location_on, size: 14, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.whiteE5),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (highlight)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText('Start',
                              fontSize: SizeConfig.size10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOptions() {
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: optionList.length,
        itemBuilder: (context, i) {
          return Obx(() {
            final response = discoverController.ridersDetailsList.value;
            final vehicleData = getSelectedVehicleData(response, 0, i);
            final fare = vehicleData?.fare;
            final isSelected =
                discoverController.selectedVehicleOptionIndex.value == i;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  discoverController.selectedVehicleOptionIndex.value = i,
              child: Container(
                height: 82,
                width: 86,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.whiteE5),
                  boxShadow: AppShadows.lightBottomShadow,
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.0),
                            AppColors.primaryColor.withValues(alpha: 0.2),
                          ],
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: LocalAssets(imagePath: optionList[i].svgImage)),
                    const SizedBox(height: 4),
                    CustomText(
                      fare != null
                          ? "₹${fare % 1 == 0 ? fare.toInt() : fare}"
                          : optionList[i].name ?? '',
                      textAlign: TextAlign.center,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildRiderList() {
    return Obx(() {
      final status = discoverController.bookingRiderListResponse.value.status;
      final loading = discoverController.findRiderDetailsLoading.value;

      if (loading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (status == Status.COMPLETE) {
        final response = discoverController.ridersDetailsList.value;
        final vehicleData = getSelectedVehicleData(
            response, 0, discoverController.selectedVehicleOptionIndex.value);
        final riders = vehicleData?.users ?? [];

        // Subscribe this Obx to the selection so the rider cards re-render
        // their selected state on tap (RiderCardWidget reads selectedRiders
        // inside its own build, which this Obx wouldn't otherwise track).
        discoverController.selectedRiders.length;

        if (riders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: CustomText(AppStrings.noRidersAvailable.tr)),
          );
        }

        return Column(
          children:
              riders.map((rider) => RiderCardWidget(rider: rider)).toList(),
        );
      }

      if (status == Status.ERROR) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: CustomText(AppStrings.noRidersAvailable.tr)),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: CustomText(AppStrings.loadingRiders.tr)),
      );
    });
  }
}
