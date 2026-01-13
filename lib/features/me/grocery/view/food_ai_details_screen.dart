import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/grocery/model/food_ai_details_res.dart';
import 'package:BlueEra/features/me/grocery/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodGenAiResModel foodData;

  const FoodDetailScreen({
    super.key,
    required this.foodData,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  FoodGenAiData product = FoodGenAiData();

  @override
  void initState() {
    // TODO: implement initState

    product = widget.foodData.data?.first ?? FoodGenAiData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Food Via AI',
      ),
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0, right: 20, left: 20),
        child: PositiveCustomBtn(onTap: () {}, title: AppStrings.postNow),
      )),
      body: CommonCardWidget(
        padding: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive horizontal padding
            double horizontalPadding = constraints.maxWidth > 600 ? 100 : 16;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Add Food Within 1 Min Via Al",
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  _buildImageSection(),
                  const SizedBox(height: 20),
                  _buildInfoCard("Product Name", product.name ?? ""),
                  const SizedBox(height: 12),
                  _buildInfoCard("Food Description", product.description ?? "",
                      isExpandable: true),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),
                  _buildIngredientsSection(),
                  const SizedBox(height: 12),
                  _buildInfoCard("Shelf Life", product.shelfLife ?? ""),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const CustomText("Food Image", fontWeight: FontWeight.normal),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: "https://example.com/idli_image.jpg",
            // Replace with real URL
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) =>
                const Icon(Icons.fastfood, size: 50),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content,
      {bool isExpandable = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            maxLines: isExpandable ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selected Category",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildRadioPlaceholder("Food Item", true)),
              Expanded(
                  child:
                      _buildRadioPlaceholder(product.dietaryType ?? "", true)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildRadioPlaceholder(
                      product.cookingMethod ?? "", true)),
              Expanded(child: _buildRadioPlaceholder("Breakfast", true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Key Ingredients",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            product.ingredients!.join(", "),
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioPlaceholder(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: Colors.blue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
