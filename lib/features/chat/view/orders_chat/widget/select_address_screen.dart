import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/porter_vehicle_option_page.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/select_blueera_pilot.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/common_methods.dart';
import '../../../../common/map/view/searchLocationScreen.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetBlueeraPiolotModel.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../../auth/model/get_adress_details_model.dart';
import 'add_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen(
      {super.key, required this.businessId, required this.message});

  final String businessId;
  final Messages message;

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final orderController = Get.put(OrderNowController());
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    orderController.getAddressApi();
    orderController.viewBusinessForLocation(
        widget.businessId, (widget.message.seller?.accountType=="INDIVIDUAL")?widget.message.seller?.accountType ?? '':widget.businessId);
    orderController.setMessageDetails(widget.message);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(
        title: "Choose Delivery Address",
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (orderController.getAddressResponse.value.status ==
                      Status.COMPLETE &&
                  orderController.viewBusinessProfileResponse.value.status ==
                      Status.COMPLETE) {
                List<AddressDetails>? addresses =
                    orderController.getAddressDetails.value.data;

                if (addresses != null) {
                  return Expanded(
                    child: (addresses.isEmpty)
                        ? const Center(
                            child: CustomText(
                              "There is no address found, Please add Address",
                              fontSize: 15,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedIndex == index;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.blue),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              addresses[index].name,
                                              color: AppColors.black,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                            CustomText(
                                              addresses[index].phone,
                                              color: AppColors.black,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                            ),
                                            CustomText(
                                              "${addresses[index].houseNo} ${addresses[index].street}, ${addresses[index].city}, ${addresses[index].state}, ${addresses[index].zipCode}",
                                              fontSize: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                } else {
                  return const SizedBox();
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),

            // Add address button

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: OutlinedButton.icon(
                onPressed: () {
                  String? getAddress;
                  double? getLat;
                  double? getLong;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchLocationScreen(
                        onPlaceSelected: (lat, long, address) {
                          getLat = lat;
                          getLong = long;
                          getAddress = address;
                        },
                        fromScreen: '',
                      ),
                    ),
                  ).then((_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAddressScreen(
                          message: widget.message,
                          address: getAddress,
                          lat: getLat,
                          long: getLong,
                        ),
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add, color: Colors.blue),
                label: const CustomText("Add Address", color: Colors.blue),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Next button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selectedIndex != null
                  ? () async{

                showFindingRiderDialog(context);
                Map<String, dynamic> params = {
                  ApiKeys.latitude: double.parse(orderController.lat.value),
                  ApiKeys.longitude: double.parse(orderController.long.value),
                  ApiKeys.range_in_km: 5,
                };
                orderController.selectedIndex?.value = selectedIndex ?? 0;
                final selectedAddress = orderController
                    .getAddressDetails.value.data?[selectedIndex!];

                List<Riders>? riders= await orderController.getRidersNearByShop(params);
                orderController.calculateDistanceInKm(
                    endLat: double.parse(orderController.lat.value) ,
                    endLng:  double.parse(orderController.long.value) ,
                    startLat:double.parse("${selectedAddress?.lat??"0.0"}") ,
                    startLng:double.parse("${selectedAddress?.lng??"0.0"}")
                );

                Future.delayed(Duration(seconds: 2),(){
                  if(riders!=null&&riders.isNotEmpty){

                    Get.off(() => DeliveryPilotScreen(
                      shopName: widget.message.seller?.name??'',
                      lat: double.parse(orderController.lat.value),
                      long:   double.parse(orderController.long.value),
                      startLat: double.parse("${selectedAddress?.lat??"0.0"}"),
                      startLng: double.parse("${selectedAddress?.lng??"0.0"}"),
                    ));
                  }else{
                    final Map<String, dynamic> payload = {
                      ApiKeys.pickup_details: {
                        ApiKeys.lat: orderController.lat.value,
                        ApiKeys.lng: orderController.long.value,
                      },
                      ApiKeys.drop_details: {
                        ApiKeys.lat: selectedAddress?.lat,
                        ApiKeys.lng: selectedAddress?.lng,
                      },
                      ApiKeys.customer: {
                        ApiKeys.name: "${selectedAddress?.name}",
                        ApiKeys.mobile: {
                          ApiKeys.country_code: "+91",
                          ApiKeys.number: "${selectedAddress?.phone}",
                        },
                      },
                    };

                    orderController.fetchVehicleQuotes(payload);
                    Get.off(() => PorterVehicleListScreen(
                      userName: selectedAddress?.name,
                      userNum: selectedAddress?.phone,
                    ));
                  }
                });


                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedIndex != null ? Colors.blue : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const CustomText(
                "Next",
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  void showFindingRiderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ cannot close manually
      barrierColor: Colors.black.withOpacity(0.4), // dim background
      builder: (BuildContext context) {
        int remainingSeconds = 30;
        ValueNotifier<int> timerNotifier = ValueNotifier(remainingSeconds);

        // ⏱ Start 30s timer
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (remainingSeconds <= 1) {
            timer.cancel();
          } else {
            remainingSeconds--;
            timerNotifier.value = remainingSeconds;
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: staggeredDotsWaveLoading(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const CustomText(
                  "Finding best rider for you...",
                  textAlign: TextAlign.center,
                  // style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  // ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: timerNotifier,
                  builder: (context, seconds, _) {
                    return CustomText(
                      "Finding in $seconds seconds",
                      // style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      // ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
