import 'package:flutter/material.dart';

import '../../../../../../../widgets/custom_text_cm.dart';

class FoodAndGroceryScreen extends StatefulWidget {
  const FoodAndGroceryScreen({super.key});

  @override
  State<FoodAndGroceryScreen> createState() => _FoodAndGroceryScreenState();
}

class _FoodAndGroceryScreenState extends State<FoodAndGroceryScreen> {
  @override
  Widget build(BuildContext context) {
    return const FoodItemCard();
  }
}

class FoodItemCard extends StatelessWidget {
  const FoodItemCard({super.key});

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
                                "Paneer Butter Masala",
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
                                "Veg",
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              "Main Course",
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Description
                        CustomText(
                          "Dorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio m.....",
                          fontSize: 12,
                          maxLines: 2,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 6),

                        // Price list
                        CustomText(
                          "Small: ₹299 | Medium: ₹499 | Large: ₹799",
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 4),

                        // Offer
                        CustomText(
                          "50% Off",
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 6),

                        // Add-ons
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _addonChip("Butter Naan (+₹30)"),
                            _addonChip("Extra Cheese (+₹30)"),
                            _addonChip("Butter Naan (+₹30)"),
                            _addonChip("Extra Cheese (+₹30)"),
                          ],
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
