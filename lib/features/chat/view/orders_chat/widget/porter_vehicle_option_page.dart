import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/controller/razorpay_controller.dart';
import '../../../auth/model/get_porter_vechile_option_model.dart';

class PorterVehicleListScreen extends StatefulWidget {
  const PorterVehicleListScreen({super.key, this.userName, this.userNum});
  final String? userName;
  final String? userNum;
  @override
  State<PorterVehicleListScreen> createState() =>
      _PorterVehicleListScreenState();
}

class _PorterVehicleListScreenState extends State<PorterVehicleListScreen> {
  int? selectedIndex;

  final orderController = Get.find<OrderNowController>();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Select Vehicle",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),

      body: Obx(() {
        if (orderController.getVehicleOptionResponse.value.status ==
            Status.COMPLETE) {
          List<Vehicles> vehicleList =
              orderController.getPorterVehicleOptionModel.value.vehicles ?? [];
          return (vehicleList.isEmpty) ? Center(
            child: CustomText("No Options Found Your Location"),
          ) : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicleList.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleList[index];
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Type and Fare
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vehicle.type ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "₹ ${vehicle.fare?.minorAmount}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade300, height: 1),
                      const SizedBox(height: 8),

                      // Capacity
                      Row(
                        children: [
                          const Icon(
                              Icons.local_shipping, size: 18,
                              color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "Capacity: ${vehicle.capacity?.value} ${vehicle
                                .capacity?.unit}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Size
                      Row(
                        children: [
                          const Icon(
                              Icons.straighten, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "Size: ${vehicle.size?.length?.value}×${vehicle.size
                                ?.breadth?.value}×${vehicle.size?.height
                                ?.value} ft",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }),

      bottomNavigationBar: Obx(() {
      if (orderController.getVehicleOptionResponse.value.status ==
          Status.COMPLETE) {
        List<Vehicles> vehicleList =
            orderController.getPorterVehicleOptionModel.value.vehicles ??
                [];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedIndex != null
                    ? () {
                  final selectedVehicle = vehicleList[selectedIndex!];

                  final razorpayController = Get.put(RazorpayController());
                  razorpayController.openCheckout(
                    amount: (selectedVehicle.fare?.minorAmount ?? 0).toDouble(),
                    customerName: "${widget.userName}", // Replace with logged user name
                    contact: "${widget.userNum}",    // Replace with user contact
                    email: "boopathi9092@gmail.com", // Replace with user email
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  selectedIndex != null ? Colors.blue : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:  Text(
                  "Pay",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      }else{
        return SizedBox();
      }

      }),
    );
  }
}
