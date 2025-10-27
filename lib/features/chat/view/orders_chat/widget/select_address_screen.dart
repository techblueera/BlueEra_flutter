import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/porter_vehicle_option_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../common/map/view/searchLocationScreen.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../../auth/model/get_adress_details_model.dart';
import 'add_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key, required this.businessId, required this.businessName, required this.businessNumber, required this.message});
  final String businessId;
  final Messages message;
  final String businessName;
  final String businessNumber;

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
    orderController.viewBusinessForLocation(widget.businessId);
    orderController.setMessageDetails(widget.message);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Address",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (orderController.getAddressResponse.value.status ==
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
            Spacer(),
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
                        builder: (context) => AddAddressScreen(message: widget.message,
                          address: getAddress,
                          lat: getLat,
                          long: getLong,
                        ),
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add, color: Colors.blue),
                label: const Text(
                  "Add Address",
                  style: TextStyle(color: Colors.blue),
                ),
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
                  ? () {
                orderController.selectedIndex?.value=selectedIndex??0;
                final selectedAddress = orderController
                    .getAddressDetails.value.data?[selectedIndex!];

                final Map<String, dynamic> payload = {
                  "pickup_details": {
                    "lat": orderController.lat.value,
                    "lng": orderController.long.value,
                  },
                  "drop_details": {
                    "lat": selectedAddress?.lat,
                    "lng":selectedAddress?.lng,
                  },
                  "customer": {
                    "name": "${selectedAddress?.name}",
                    "mobile": {
                      "country_code": "+91",
                      "number": "${selectedAddress?.phone}",
                    },
                  },
                };
                orderController.fetchVehicleQuotes(payload);
               Get.off(()=>PorterVehicleListScreen(userName: selectedAddress?.name,userNum: selectedAddress?.phone,));
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                selectedIndex != null ? Colors.blue : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
