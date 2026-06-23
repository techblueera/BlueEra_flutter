import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/passenger_booking_main.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/search_transport_address.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_response.dart';

import '../../controller/discover_controller.dart';
import 'fare_call_queue_screen.dart';
import '../../model/get_booking_rider_model.dart';

/// Booking screen for the product-order (self-pickup) ride flow.
///
/// A trimmed copy of [BookTransportMain]: the category tabs (In City / Out
/// Station / Hourly Rental / Parcel) and the One Way / Round Trip selector are
/// removed — only the In-City vehicle + rider selection UI is shown. The shared
/// vehicle/rider widgets and helpers ([RiderCardWidget], [getSelectedVehicleData],
/// [TransportCategoryDetailsModel]) are reused from [BookTransportMain].
class ProductOrderBookingRiderMain extends StatefulWidget {
  const ProductOrderBookingRiderMain({super.key, this.vehicleType});

  final String? vehicleType;

  @override
  State<ProductOrderBookingRiderMain> createState() =>
      _ProductOrderBookingRiderMainState();
}

class _ProductOrderBookingRiderMainState
    extends State<ProductOrderBookingRiderMain> {
  final discoverController = getOrPut(() => DiscoverController());

  // In-City vehicles only — this flow doesn't expose the other categories.
  List<TransportCategoryDetailsModel> get optionList => [
        TransportCategoryDetailsModel(
          name: AppStrings.transportBike.tr,
          svgImage: AppIconAssets.transport_bike,
        ),
        TransportCategoryDetailsModel(
          name: AppStrings.transportTaxi.tr,
          svgImage: AppIconAssets.transport_taxi,
        ),
        TransportCategoryDetailsModel(
          name: AppStrings.transportAuto.tr,
          svgImage: AppIconAssets.transport_auto,
        ),
        TransportCategoryDetailsModel(
          name: AppStrings.transportERickshaw.tr,
          svgImage: AppIconAssets.transport_big_auto,
        ),
      ];

  @override
  void initState() {
    super.initState();
    // This flow is In-City only.
    discoverController.selectedHorizontalTab.value = 0;
    if (widget.vehicleType == "PASSENGER") {
      discoverController.selectedVehicleOptionIndex.value = 1;
    } else {
      discoverController.selectedVehicleOptionIndex.value = 0;
    }
  }

  @override
  void dispose() {
    // The chat-dispatch context lives on the shared DiscoverController; clear
    // it when leaving so a later regular booking can't accidentally inherit it.
    discoverController.clearChatDispatchContext();
    super.dispose();
  }

  void _editAddress() {
    Get.off(() => SearchTransportAddress(
          onPlaceSelected: () {},
          vehicleType: widget.vehicleType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        appBar: CommonBackAppBar(),
        backgroundColor: AppColors.white,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: CustomBtn(
                isLoading: discoverController.bookRiderBtnLoading.value,
                height: 44,
                isValidate: discoverController.selectedRiders.isNotEmpty,
                onTap: () async {
                  // Chat self-pickup → rider dispatch: create the delivery ride
                  // via the chat-dispatch endpoint and return to the chat. The
                  // pickup/delivery OTP cards then arrive over the chat socket.
                  if (discoverController.chatDispatchContext != null) {
                    final dispatched =
                        await discoverController.makeChatDispatchOrderApi();
                    if (dispatched) {
                      discoverController.clearChatDispatchContext();
                      Get.back();
                      commonSnackBar(
                          message: AppStrings.riderDispatchRequested.tr);
                    }
                    return;
                  }
                  // Setup queue listeners BEFORE the API call so we don't
                  // miss ride:queue:calling if the server fires it
                  // immediately after order creation.
                  discoverController.setupFareCallQueueListeners();
                  final success =
                      await discoverController.makeTransportBookOrderApi();
                  if (success &&
                      discoverController.selectedRiders.isNotEmpty) {
                    Get.to(() => FareCallQueueScreen(
                          orderId: discoverController.fareCallOrderId.value,
                        ));
                  }
                },
                title: AppStrings.callToRider.tr),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  /// Pickup & Drop address card (tap to edit)
                  InkWell(
                    onTap: _editAddress,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppShadows.bottomShadow],
                        color: AppColors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          /// Location icons
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                LocalAssets(
                                  imagePath:
                                      AppIconAssets.transport_from_location,
                                ),
                                SizedBox(height: SizeConfig.size4),
                                LocalAssets(
                                  imagePath:
                                      AppIconAssets.tranport_location_pointer,
                                ),
                                SizedBox(height: SizeConfig.size2),
                                LocalAssets(
                                  imagePath: AppIconAssets.location_new,
                                  imgColor: AppColors.red00,
                                ),
                              ],
                            ),
                          ),

                          /// Addresses
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Pickup address
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          (discoverController
                                                          .selectedFromAddress
                                                          ?.value ??
                                                      '')
                                                  .isNotEmpty
                                              ? discoverController
                                                  .selectedFromAddress?.value
                                              : AppStrings.selectPickup.tr,
                                          fontSize: 13,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.edit_outlined,
                                          size: 16, color: AppColors.grayText),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: AppColors.whiteE5,
                                ),

                                /// Drop address
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          (discoverController.selectedToAddress
                                                          ?.value ??
                                                      '')
                                                  .isNotEmpty
                                              ? discoverController
                                                  .selectedToAddress?.value
                                              : AppStrings.selectDrop.tr,
                                          fontSize: 13,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(Icons.edit_outlined,
                                          size: 16, color: AppColors.grayText),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: SizeConfig.size6),

                          /// Swap button
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [AppShadows.bottomShadow],
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: LocalAssets(
                                imagePath:
                                    AppIconAssets.transport_location_exchange),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// Vehicle options (In City)
                  SizedBox(
                    height: 82,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: optionList.length,
                      itemBuilder: (context, i) {
                        return Obx(() {
                          final response =
                              discoverController.ridersDetailsList.value;
                          final vehicleData =
                              getSelectedVehicleData(response, 0, i);
                          final fare = vehicleData?.fare;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              discoverController
                                  .selectedVehicleOptionIndex.value = i;
                            },
                            child: Container(
                              height: 82,
                              width: 86,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: discoverController
                                                .selectedVehicleOptionIndex
                                                .value ==
                                            i
                                        ? AppColors.primaryColor
                                        : AppColors.whiteE5),
                                boxShadow: AppShadows.lightBottomShadow,
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    left: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        gradient: discoverController
                                                    .selectedVehicleOptionIndex
                                                    .value ==
                                                i
                                            ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  AppColors.primaryColor
                                                      .withValues(alpha: 0.0),
                                                  AppColors.primaryColor
                                                      .withValues(alpha: 0.2),
                                                ],
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Center(
                                              child: LocalAssets(
                                                  imagePath:
                                                      optionList[i].svgImage)),
                                          const SizedBox(height: 2),
                                          CustomText(
                                            fare != null
                                                ? "₹${fare % 1 == 0 ? fare.toInt() : fare}"
                                                : "${optionList[i].name}",
                                            textAlign: TextAlign.center,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(AppStrings.chooseYourRider.tr,
                          fontSize: 16, fontWeight: FontWeight.w600),
                      if (discoverController.selectedRiders.length > 1)
                        CustomText(
                          "${discoverController.selectedRiders.length} ${AppStrings.selectedLabel.tr}",
                          fontSize: 13,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size16),

                  /// Rider list
                  Obx(() {
                    if (discoverController
                            .bookingRiderListResponse.value.status ==
                        Status.COMPLETE) {
                      final VehicleAllResponse response =
                          discoverController.ridersDetailsList.value;

                      final vehicleData = getSelectedVehicleData(
                        response,
                        0,
                        discoverController.selectedVehicleOptionIndex.value,
                      );

                      final riders = vehicleData?.users ?? [];

                      if (riders.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child: CustomText(
                                  AppStrings.noRidersAvailable.tr)),
                        );
                      }

                      return (discoverController.findRiderDetailsLoading.value)
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              children: riders
                                  .map((rider) =>
                                      RiderCardWidget(rider: rider))
                                  .toList(),
                            );
                    } else {
                      if (discoverController
                              .findRiderDetailsLoading.value ==
                          true) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child:
                                  CustomText(AppStrings.loadingRiders.tr)),
                        );
                      }
                    }
                  }),
                  SizedBox(height: SizeConfig.size30),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
