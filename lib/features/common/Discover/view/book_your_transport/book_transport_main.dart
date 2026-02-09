import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../map/view/searchLocationScreen.dart';
import '../../controller/discover_controller.dart';
import '../../model/get_booking_rider_model.dart';

class BookTransportMain extends StatefulWidget {
  const BookTransportMain({super.key});

  @override
  State<BookTransportMain> createState() => _BookTransportMainState();
}

class _BookTransportMainState extends State<BookTransportMain> {
  final discoverController = getOrPut(() => DiscoverController());

  List<TransportCategoryDetailsModel> inCityVehicleList = [
    TransportCategoryDetailsModel(
      name: "Bike",
      svgImage: AppIconAssets.transport_bike,
      charge: 100,
    ),
    TransportCategoryDetailsModel(
      name: "Taxi",
      svgImage: AppIconAssets.transport_taxi,
      charge: 500.0,
    ),
    TransportCategoryDetailsModel(
      name: "Auto",
      svgImage: AppIconAssets.transport_auto,
      charge: 200.0,
    ),
    TransportCategoryDetailsModel(
      name: "Big Auto",
      svgImage: AppIconAssets.transport_big_auto,
      charge: 250.0,
    ),
  ];
  List<TransportCategoryDetailsModel> inOutStationVehicleList = [
    TransportCategoryDetailsModel(
      name: "4 Seater",
      svgImage: AppIconAssets.transport_taxi,
    ),
    TransportCategoryDetailsModel(
      name: "7 Seater",
      svgImage: AppIconAssets.transport_7_seater,
    ),
  ];
  List<TransportCategoryDetailsModel> inParcelVehicleList = [
    TransportCategoryDetailsModel(
      name: "Lorem Ip",
      svgImage: AppIconAssets.transport_load_auto,
    ),
    TransportCategoryDetailsModel(
      name: "Lorem Ip",
      svgImage: AppIconAssets.transport_truck,
    ),
    TransportCategoryDetailsModel(
      name: "Lorem Ip",
      svgImage: AppIconAssets.transport_container,
    ),
  ];
  MapplsMapController? mapController;

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
  }

  get optionList =>
      discoverController.selectedHorizontalTab.value == 0
          ? inCityVehicleList
          : discoverController.selectedHorizontalTab.value ==
          3 ? inParcelVehicleList : inOutStationVehicleList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
                isValidate: discoverController.selectedRider.value.riderId !=
                    null,
                onTap: () {
                  discoverController.makeTransportBookOrderApi();
                },
                title: "Book"),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.blueLightShade,
                borderRadius: BorderRadius.circular(10),
              ),
              height: 160,
              child: MapplsMap(
                onMapCreated: (controller) => _onMapCreated(controller),
                initialCameraPosition: CameraPosition(
                  target: LatLng(26.7836, 80.9013),
                  zoom: 14.0,
                ),
                myLocationEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10,),
                HorizontalTabSelector(
                    unSelectedBackgroundColor: AppColors.white,
                    tabs: [
                      'In City',
                      "Out Station",
                      "Hourly Rental",
                      "Parcel"
                    ],
                    selectedIndex: discoverController.selectedHorizontalTab
                        .value,
                    onTabSelected: (index, d) {
                      discoverController.selectedHorizontalTab.value = index;
                    },
                    labelBuilder: (value) => value),
                SizedBox(
                  height: 60,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      color: AppColors.white
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SizeConfig.size10,),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              AppShadows.bottomShadow
                            ],
                            color: AppColors.white

                        ),
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  LocalAssets(imagePath: AppIconAssets
                                      .transport_from_location,),
                                  SizedBox(height: SizeConfig.size4,),
                                  LocalAssets(imagePath: AppIconAssets
                                      .tranport_location_pointer,),
                                  SizedBox(height: SizeConfig.size2,),
                                  LocalAssets(
                                    imagePath: AppIconAssets.location_new,
                                    imgColor: AppColors.red00,
                                  )
                                ],
                              ),
                            ),

                            /// ✅ FIXED HERE
                            Expanded(
                              child: Column(
                                spacing: 12,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SearchLocationScreen(
                                                onPlaceSelected: (lat, long,
                                                    address) {
                                                  discoverController
                                                      .selectedFromLat
                                                      ?.value =
                                                      lat ?? 0;
                                                  discoverController
                                                      .selectedFromLong
                                                      ?.value =
                                                      long ?? 0;
                                                  discoverController
                                                      .selectedFromAddress
                                                      ?.value = address ?? "";
                                                  discoverController
                                                      .getBookingRidersApi();
                                                },
                                                fromScreen: '',
                                              ),
                                        ),
                                      );
                                    },
                                    child: CustomText(
                                      (discoverController.selectedFromAddress
                                          ?.value == '' ||
                                          discoverController
                                              .selectedFromAddress
                                              ?.value == null)
                                          ?
                                      "Select From Address"
                                          : discoverController
                                          .selectedFromAddress?.value,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    width: double.infinity,
                                    color: AppColors.whiteE5,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SearchLocationScreen(
                                                onPlaceSelected: (lat, long,
                                                    address) {
                                                  discoverController
                                                      .selectedToLat?.value =
                                                      lat ?? 0;
                                                  discoverController
                                                      .selectedToLong?.value =
                                                      long ?? 0;
                                                  discoverController
                                                      .selectedToAddress
                                                      ?.value = address ?? "";
                                                  discoverController
                                                      .getBookingRidersApi();
                                                },
                                                fromScreen: '',
                                              ),
                                        ),
                                      );
                                    },
                                    child: CustomText(
                                      (discoverController.selectedToAddress
                                          ?.value == '' ||
                                          discoverController.selectedToAddress
                                              ?.value == null) ?
                                      "Select To Address" : discoverController
                                          .selectedToAddress?.value,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: SizeConfig.size6,),
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [AppShadows.bottomShadow],
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.white,
                              ),
                              padding: EdgeInsets.all(10),
                              child: LocalAssets(imagePath: AppIconAssets
                                  .transport_location_exchange),
                            )
                          ],
                        ),

                      ),
                      SizedBox(height: SizeConfig.size16,),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for(int i = 0; i < optionList.length; i++)
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  discoverController
                                      .selectedVehicleOptionIndex
                                      .value = i;
                                },
                                child: Container(
                                  height: 82,
                                  width: 86,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                      Border.all(
                                          color: discoverController
                                              .selectedVehicleOptionIndex
                                              .value == i ?
                                          AppColors.primaryColor : AppColors
                                              .whiteE5)
                                      ,
                                      boxShadow: AppShadows.lightBottomShadow
                                  ),

                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        left: 0,
                                        child: Container(
                                          // height: 0,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius
                                                .circular(
                                                10),
                                            gradient: discoverController
                                                .selectedVehicleOptionIndex
                                                .value ==
                                                i ? LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                AppColors.primaryColor
                                                    .withOpacity(0.0),
                                                AppColors.primaryColor
                                                    .withOpacity(0.2),
                                              ],
                                            ) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .center,
                                            mainAxisAlignment: MainAxisAlignment
                                                .end,
                                            children: [
                                              Center(child: LocalAssets(
                                                  imagePath: optionList[i]
                                                      .svgImage)),
                                              const SizedBox(height: 2),
                                              CustomText(
                                                (optionList[i].charge != null)
                                                    ? "₹${optionList[i]
                                                    .charge}"
                                                    : "${optionList[i].name}",
                                                textAlign: TextAlign.center,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,),
                                              const SizedBox(height: 6),
                                            ],
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size16,),
                      CustomText("Choose Your Rider", fontSize: 16,
                        fontWeight: FontWeight.w600,),
                      SizedBox(height: SizeConfig.size16,),

                      // for(int i = 0; i < optionList.length; i++)
                      Obx(() {
                        if (discoverController.bookingRiderListResponse.value
                            .status ==
                            Status.COMPLETE) {
                          final VehicleAllResponse response =
                              discoverController.ridersDetailsList.value;

                          final vehicleData = getSelectedVehicleData(
                            response,
                            discoverController.selectedHorizontalTab.value,
                            discoverController.selectedVehicleOptionIndex
                                .value,
                          );

                          final riders = vehicleData?.users ?? [];

                          if (riders.isEmpty) {
                            return const Center(
                                child: Text("No riders available"));
                          }

                          return (discoverController.findRiderDetailsLoading
                              .value)
                              ?
                          Center(child: CircularProgressIndicator(),)
                              : Column(
                            children: riders
                                .map((rider) => RiderCardWidget(rider: rider))
                                .toList(),
                          );
                        } else {
                          if (discoverController.findRiderDetailsLoading
                              .value == true) {
                            return Center(child: CircularProgressIndicator());
                          } else {
                            return Center(child: CustomText(
                                "Choose From And To Address"));
                          }
                        }
                      }),
                      SizedBox(
                        height: SizeConfig.size30,
                      ),


                    ],
                  ),
                )
              ],
            ),


          ],
        ),
      );
    });
  }
}

class TransportCategoryDetailsModel {
  final String? name;
  final String svgImage;
  final double? charge;

  TransportCategoryDetailsModel({
    required this.name,
    required this.svgImage,
    this.charge,
  });

  factory TransportCategoryDetailsModel.fromJson(Map<String, dynamic> json) {
    return TransportCategoryDetailsModel(
      name: json['name'] ?? '',
      svgImage: json['svgImage'] ?? '',
      charge: json['charge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'svgImage': svgImage,
      'charge': charge,
    };
  }
}

VehicleData? getSelectedVehicleData(VehicleAllResponse response,
    int selectedTab,
    int selectedIndex,) {
  // In City
  if (selectedTab == 0) {
    switch (selectedIndex) {
      case 0:
        return response.twoWheelerRider;
      case 1:
        return response.carMini;
      case 2:
        return response.autoTempo;
      case 3:
        return response.miniBus;
    }
  }

  // Out Station
  if (selectedTab == 1) {
    switch (selectedIndex) {
      case 0:
        return response.suvCar;
      case 1:
        return response.suvCar;
    }
  }

  // Parcel
  if (selectedTab == 3) {
    return response.pickupGoods;
  }

  return null;
}

class RiderCardWidget extends StatelessWidget {
  final RiderUser rider;

  const RiderCardWidget({
    super.key,
    required this.rider,
  });

  @override
  Widget build(BuildContext context) {
    final discoverController = getOrPut(() => DiscoverController());

    return InkWell(
      onTap: () {
        discoverController.onSelectRider(rider);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color:
          discoverController.selectedRider.value == rider ?
          AppColors.primaryColor : AppColors.whiteE5),
        ),
        child: Row(
          children: [

            /// Profile image
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.network(
                rider.profileImage ?? "",
                height: 48,
                width: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 48,
                    width: 48,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 48,
                    width: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            /// Name + rating + vehicle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    rider.name ?? '',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [

                      /// Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greyE4,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            CustomText(
                              (rider.rating ?? 0.0).toString(),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// Vehicle name
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greyE4,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          (rider.vehicleInformation?.vehicleName == null ||
                              rider.vehicleInformation?.vehicleName == '')
                              ? "N/A"
                              : rider.vehicleInformation?.vehicleName,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Divider
            Container(
              height: 50,
              width: 1,
              margin: const EdgeInsets.only(right: 26),
              color: AppColors.whiteE5,
            ),

            /// Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  "Distance",
                  fontSize: 12,
                  color: AppColors.grayText,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    LocalAssets(imagePath: AppIconAssets.location_new),
                    SizedBox(width: SizeConfig.size2),
                    CustomText(
                      rider.distance ?? '',
                      fontSize: 12,
                      color: AppColors.grayText,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
