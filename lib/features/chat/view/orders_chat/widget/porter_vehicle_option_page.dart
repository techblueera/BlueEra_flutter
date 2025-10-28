import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
              final amount=(vehicle.fare?.minorAmount ?? 0) / 100;
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

                        children: [
                          LocalAssets(imagePath: AppIconAssets.motorcycle,height: 140,width: 140,),
                          const SizedBox(width: 12,),
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                vehicle.type ?? '',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,

                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.whiteE0
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 8,vertical: 2),

                                child: CustomText(
                                  "Pay : ₹ ${((amount)+(amount * 0.10)).toStringAsFixed(2)}",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),

                      Divider(color: Colors.grey.shade300, height: 1),
                      // const SizedBox(height: 8),

                      // Capacity
                      (vehicle.capacity?.value=='-')?SizedBox():Row(
                        children: [
                          const Icon(
                              Icons.local_shipping, size: 18,
                              color: Colors.grey),
                          const SizedBox(width: 6),
                          CustomText(
                            "Capacity: ${vehicle.capacity?.value} ${vehicle
                                .capacity?.unit}",
                           fontSize: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Size
                      (vehicle.size?.length?.value=='-')?SizedBox():Row(
                        children: [
                          const Icon(
                              Icons.straighten, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          CustomText(
                            "Size: ${vehicle.size?.length?.value} × ${vehicle.size
                                ?.breadth?.value} × ${vehicle.size?.height
                                ?.value} ft",
                           fontSize: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if(orderController.getVehicleOptionResponse.value.status ==
            Status.ERROR){
          String message=orderController.getVehicleOptionResponse.value.message??'';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.coloGreyText,
                  size: 50,
                ),
                 SizedBox(height: SizeConfig.size16),
                CustomText(
                  message.isNotEmpty ? message : "Something went wrong!",
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.size30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const CustomText(
                    "Go Back",
                    color: Colors.white, fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }else{
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
                    amount: double.parse((selectedVehicle.fare?.minorAmount ?? 0/100).toString()),
                    customerName: "${widget.userName}", // Replace with logged user name
                    contact: "${widget.userNum}",    // Replace with user contact
                    email: "admin@bluecs.in", // Replace with user email
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
