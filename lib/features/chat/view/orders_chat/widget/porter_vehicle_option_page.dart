import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../core/services/razor_pay_services.dart';
import '../../../auth/controller/order_controllar.dart';
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
        title: const CustomText(AppStrings.selectVehicle,
            fontSize: 18, fontWeight: FontWeight.w600),
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
          return (vehicleList.isEmpty)
              ? Center(
                  child: CustomText(AppStrings.noOptionsFoundLocation),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicleList.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicleList[index];
                    final isSelected = selectedIndex == index;
                    final amount = (vehicle.fare?.minorAmount ?? 0) / 100;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.transparent,
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle Type and Fare
                            Row(
                              children: [
                                Expanded(
                                  child: LocalAssets(
                                    imagePath: vehicle.type == "2 Wheeler"
                                        ? AppIconAssets.twoWheeler
                                        : vehicle.type == "3 Wheeler"
                                            ? AppIconAssets.threeWheeler
                                            : vehicle.type ==
                                                    "Ace (Helper + 1 Labour)"
                                                ? AppIconAssets.ace_helper
                                                : vehicle.type == "Tata 407"
                                                    ? AppIconAssets.tata_407
                                                    : '',
                                    height: vehicle.type ==
                                            "Ace (Helper + 1 Labour)"
                                        ? 70
                                        : 100,
                                    width: vehicle.type ==
                                            "Ace (Helper + 1 Labour)"
                                        ? 70
                                        : 90,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        vehicle.type ?? '',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: AppColors.whiteE0),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        child: CustomText(
                                          "${AppStrings.pay.tr} : ₹ ${((amount) + (amount * 0.10)).toStringAsFixed(2)}",
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300, height: 1),
                            const SizedBox(height: 8),

                            (vehicle.capacity?.value == '-')
                                ? SizedBox()
                                : Row(
                                    children: [
                                      const Icon(Icons.local_shipping,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        "${AppStrings.capacity.tr}: ${vehicle.capacity?.value} ${vehicle.capacity?.unit}",
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),

                            // const SizedBox(height: 4),
                            //
                            // // Size
                            // (vehicle.size?.length?.value=='-')?SizedBox():Row(
                            //   children: [
                            //     const Icon(
                            //         Icons.straighten, size: 18, color: Colors.grey),
                            //     const SizedBox(width: 6),
                            //     CustomText(
                            //       "Size: ${vehicle.size?.length?.value} × ${vehicle.size
                            //           ?.breadth?.value} × ${vehicle.size?.height
                            //           ?.value} ft",
                            //      fontSize: 14,
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        } else if (orderController.getVehicleOptionResponse.value.status ==
            Status.ERROR) {
          String message =
              orderController.getVehicleOptionResponse.value.message ?? '';

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
                  message.isNotEmpty ? message : AppStrings.somethingWentWrong,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const CustomText(
                    AppStrings.goBack,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }),
      bottomNavigationBar: Obx(() {
        if (orderController.getVehicleOptionResponse.value.status ==
            Status.COMPLETE) {
          List<Vehicles> vehicleList =
              orderController.getPorterVehicleOptionModel.value.vehicles ?? [];
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

                          final razorpayService = RazorpayService();

                          razorpayService.openCheckout(
                            name: "${widget.userName}",
                            subscriptionId: "",
                            description: '',
                            amount: (double.parse(
                                    (selectedVehicle.fare?.minorAmount ??
                                            0 / 100)
                                        .toString()) +
                                (double.parse(
                                        (selectedVehicle.fare?.minorAmount ??
                                                0 / 100)
                                            .toString()) *
                                    0.10)),
                            contact: "${widget.userNum}",
                            email: 'admin@bluecs.in',
                            onPaymentSuccess: (response) async {
                              debugPrint("Payment Suzzz: ${response.data}");
                            },
                            onPaymentError: (response) {
                              debugPrint("Payment Failed: ${response.message}");
                              commonSnackBar(
                                  message:
                                      "Payment Failed ${response.message}");
                            },
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIndex != null
                        ? Colors.blue
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: CustomText(
                      AppStrings.pay,
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      }),
    );
  }
}
