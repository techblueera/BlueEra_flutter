import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    Map<String, dynamic> params = {"all": false, "type": "food"};
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
            return FoodItemCard(
              foodData: food,
            ); // ✅ dynamic card
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0,top: 2,left: 8,right: 8),
      child: Card(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            SizedBox(
              width: 140, // fixed width for image column
              height: 200, // fixed height (adjust as needed)
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: foodData.photos?.first ?? "",
                  fit: BoxFit.cover, // fills entire box
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),


            // CONTENT SECTION
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
                          child: Text(
                            foodData.title ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Veg",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          foodData.category ?? "",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      foodData.description ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price options (Small / Medium / Large)
                    CustomText(
                      "Rs ${foodData.singlePrice.toString()}",
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    // Row(
                    //   children: [
                    //     Text("Small: ₹299",
                    //         style: TextStyle(fontWeight: FontWeight.w600)),
                    //     const SizedBox(width: 8),
                    //     Text("Medium: ₹499",
                    //         style: TextStyle(fontWeight: FontWeight.w600)),
                    //     const SizedBox(width: 8),
                    //     Text("Large: ₹799",
                    //         style: TextStyle(fontWeight: FontWeight.w600)),
                    //   ],
                    // ),
                    const SizedBox(height: 4),

                    // Discount
                    if (foodData.discounts != null &&
                        foodData.discounts!.isNotEmpty)
                      Text(
                        foodData.discounts!.first,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Add-ons
                    if (foodData.addOns != null && foodData.addOns!.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: foodData.addOns!
                            .map((addon) =>
                            InkWell(
                              onTap: () {},
                              child: Text(
                                addon,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ))
                            .toList(),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}