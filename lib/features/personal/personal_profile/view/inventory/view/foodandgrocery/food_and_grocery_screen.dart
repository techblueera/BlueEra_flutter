import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../../common/food/controller/food_upload_controller.dart';
import '../../../../../../common/food/model/getfooddetails_model.dart';

class FoodAndGroceryScreen extends StatefulWidget {
  const FoodAndGroceryScreen({super.key});

  @override
  State<FoodAndGroceryScreen> createState() => _FoodAndGroceryScreenState();
}

class _FoodAndGroceryScreenState extends State<FoodAndGroceryScreen> {
  final controller = Get.put(FoodUploadController());

  @override
  void initState() {
    // TODO: implement initState
    Map<String,dynamic> params={
      "all":false,
      "type":"food"
    };
    controller.getFoodService(params);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.foodList.isEmpty) {
          return const Center(child: Text("No food items found"));
        }

        return ListView.builder(
          itemCount: controller.foodList.length,
          itemBuilder: (context, index) {
            final food = controller.foodList[index];
            return FoodItemCard(foodData: food,); // ✅ dynamic card
          },
        );
      }),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  const FoodItemCard({super.key, required this.foodData});
  final FoodModel foodData;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Icon(Icons.image)),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + menu button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomText(
                                "${foodData.title}",
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.more_vert, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Veg label + category
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: CustomText(
                                "${foodData.subCategory}",
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              foodData.category,
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Description
                        CustomText(
                       foodData.description,
                          fontSize: 12,
                          maxLines: 2,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 6),

                        // Price list
                        CustomText(
                         "Rs ${foodData.singlePrice.toString()}",
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 4),

                        // Offer
                        if (foodData.discounts != null && foodData.discounts!.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: foodData.discounts!
                                .map((d) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ))
                                .toList(),
                          ),

                        const SizedBox(height: 6),

                        // Add-ons
                        if(foodData.addOns!=null||foodData.addOns!.isNotEmpty??false)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:(foodData.addOns?.isEmpty??true)?[SizedBox()]: foodData.addOns!.map<Widget>((addon) {
                              return _addonChip("${addon}");
                            }).toList(),
                          )


                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _addonChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        text,
        fontSize: 12,
        color: Colors.blue,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
