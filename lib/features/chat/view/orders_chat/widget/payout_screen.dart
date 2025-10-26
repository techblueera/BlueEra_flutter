import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  int quantity = 1;
  double itemPrice = 180;
  double deliveryFee = 30;
  double discount = 20;

  final TextEditingController addressController = TextEditingController();

  List<String> savedAddresses = [
    "Home - 123, Main Street, Chennai",
    "Office - 45, IT Park, OMR Road"
  ];

  @override
  Widget build(BuildContext context) {
    double itemTotal = itemPrice * quantity;
    double totalAmount = itemTotal - discount + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payout Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Paneer Butter Masala",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),

                        // Quantity Row
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              "$quantity",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => quantity++);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text("₹${(itemPrice * quantity).toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),

                        const Text("Expected delivery: 30 mins",
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bill Summary
            const Text("Bill Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _billRow("Item Total", "₹${itemTotal.toStringAsFixed(0)}"),
            _billRow("Discount", "- ₹${discount.toStringAsFixed(0)}",
                color: Colors.green),
            _billRow("Delivery Fee", "₹${deliveryFee.toStringAsFixed(0)}"),
            const Divider(height: 30),
            _billRow("Total Amount", "₹${totalAmount.toStringAsFixed(0)}",
                isBold: true, fontSize: 16, color: Colors.black),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue..withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "You saved ₹${discount.toStringAsFixed(0)} on this order 🎉",
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 25),

            // Address Section
            const Text("Delivery Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                hintText: "Enter new address",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.blueAccent),
                  onPressed: () {
                    if (addressController.text.isNotEmpty) {
                      setState(() {
                        savedAddresses.add(addressController.text);
                        addressController.clear();
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Saved Address List
            ListView.builder(
              itemCount: savedAddresses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(savedAddresses[index],
                            style: const TextStyle(fontSize: 14)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            savedAddresses.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                      )
                    ],
                  ),
                );
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  addressController.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                  Get.snackbar("Add Address", "You can add new address above");
                },
                icon: const Icon(Icons.add, color: Colors.blueAccent),
                label: const Text("Add New Address",
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // Bottom fixed button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showOptionsBottomSheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: CustomText("Place Order",

                    color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
  String? selectedOption;

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Payment Required",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text(
            "Delivery charge needs to be paid first to proceed.",
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grayText..withValues(alpha: 0.1),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                    ),
                    child: const CustomText("Cancel",color: Colors.white,),
                  ),
                ),
                const SizedBox(width: 8,),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const CustomText("Pay Now ₹50",color: Colors.white,),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void selectOption(String option) {
              setModalState(() => selectedOption = option);
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Choose an Option",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Two selectable buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => selectOption("Pickup"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedOption == "Pickup"
                              ? AppColors.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          side: BorderSide(
                            color: selectedOption == "Pickup"
                                ? AppColors.primaryColor
                                : Colors.grey.shade400,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: CustomText(
                          "Pickup From Shop",
                          fontWeight: FontWeight.w600,
                          color: selectedOption == "Pickup"
                              ? AppColors.primaryColor
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 20),
                      OutlinedButton(
                        onPressed: () => selectOption("Delivery"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedOption == "Delivery"
                              ? AppColors.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          side: BorderSide(
                            color: selectedOption == "Delivery"
                                ? AppColors.primaryColor
                                : Colors.grey.shade400,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: CustomText(
                          "Home Delivery",
                          fontWeight: FontWeight.w600,
                          color: selectedOption == "Delivery"
                              ? AppColors.primaryColor
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Next button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: selectedOption == null
                              ? null
                              : () {
                            Navigator.pop(context);
                            if (selectedOption == "Delivery") {
                              _showPaymentDialog(context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedOption == null
                                ? Colors.grey.shade300
                                : AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: CustomText(
                            "Next",
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _billRow(String title, String value,
      {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black87,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: fontSize,
                color: color ?? Colors.black87,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
