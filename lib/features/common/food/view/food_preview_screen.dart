import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodDetailScreen extends StatefulWidget {
  Map<String, dynamic> foodData;

  FoodDetailScreen({super.key, required this.foodData});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final controller = Get.find<FoodUploadController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.foodData["productName"] ?? "Food Item",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:  EdgeInsets.only(left: SizeConfig.size20,right: SizeConfig.size20,bottom: SizeConfig.size20),
          child: PositiveCustomBtn(
              onTap: () {
                Get.back();
                Get.back();
              },
              title: "Go Back"),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.large,
              right: SizeConfig.large,
              bottom: SizeConfig.size30),
          child: CommonCardWidget(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Hero Section
                  Container(
                    height: SizeConfig.size300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                      image: DecorationImage(
                        image: FileImage(
                            controller.selectedImage.value ?? File("")),
                        // or NetworkImage
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size10,
                          vertical: SizeConfig.size6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        widget.foodData["cuisine"] ?? "",
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),

                  // 🔹 Title + Category
                  CustomText(
                    widget.foodData["productName"] ?? "",
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.size22,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    "${widget.foodData["category"]} • Shelf Life: ${widget.foodData["shelfLife"]}",
                    color: Colors.grey[600],
                  ),

                  SizedBox(height: SizeConfig.size16),

                  // 🔹 Short Description
                  CustomText(
                    widget.foodData["shortDescription"] ?? "",
                    fontSize: SizeConfig.large,
                  ),

                  SizedBox(height: SizeConfig.size16),

                  // 🔹 Key Ingredients
                  _buildSectionTitle("Key Ingredients"),
                  Wrap(
                    spacing: 8,
                    children: List<String>.from(
                            widget.foodData["keyIngredients"] ?? [])
                        .map((e) {
                      return Chip(
                        shadowColor: AppColors.secondaryTextColor,
                        elevation: 2,
                        label: CustomText(e),
                        backgroundColor: AppColors.white.withValues(alpha: 0.5),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: SizeConfig.size20),

                  // 🔹 Serving Options
                  _buildSectionTitle("Serving Options"),
                  Column(
                    children: List<Map<String, dynamic>>.from(
                            widget.foodData["servingOptions"] ?? [])
                        .map((e) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: CustomText("${e["size"]}"),
                          subtitle: CustomText("Serves ${e["serves"]}"),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: SizeConfig.size20),

                  // 🔹 Accompaniments
                  _buildSectionTitle("Accompaniments"),
                  Wrap(
                    spacing: 8,
                    children: List<String>.from(
                            widget.foodData["accompaniments"] ?? [])
                        .map((e) {
                      return Chip(
                        label: CustomText(e),
                        shadowColor: AppColors.secondaryTextColor,
                        elevation: 2,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: SizeConfig.size20),

                  // 🔹 Nutrition Summary
                  _buildSectionTitle("Nutritional Summary (per 100g)"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _nutritionCard(
                          "Calories",
                          widget.foodData["nutritionalSummary_per100g"]
                              ["calories_kcal"]),
                      _nutritionCard(
                          "Protein",
                          widget.foodData["nutritionalSummary_per100g"]
                              ["protein_g"]),
                      _nutritionCard(
                          "Carbs",
                          widget.foodData["nutritionalSummary_per100g"]
                              ["carbs_g"]),
                      _nutritionCard(
                          "Fat",
                          widget.foodData["nutritionalSummary_per100g"]
                              ["fat_g"]),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size20),

                  // 🔹 Key Minerals
                  _buildSectionTitle("Key Minerals"),
                  Wrap(
                    spacing: 8,
                    children:
                        List<String>.from(widget.foodData["keyMinerals"] ?? [])
                            .map((e) {
                      return Chip(
                        backgroundColor: Colors.teal[50],
                        label: CustomText(e),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: SizeConfig.size20),

                  // 🔹 SEO Tags
                  _buildSectionTitle("SEO Tags"),
                  Wrap(
                    spacing: 8,
                    children:
                        List<String>.from(widget.foodData["seoTags"] ?? [])
                            .map((e) {
                      return Chip(
                        backgroundColor: Colors.orange[50],
                        label: CustomText("#$e"),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(title,
        fontSize: SizeConfig.size18, fontWeight: FontWeight.bold);
  }

  Widget _nutritionCard(String title, String value) {
    return Column(
      children: [
        CustomText(value,
            fontSize: SizeConfig.size16, fontWeight: FontWeight.bold),
        const SizedBox(height: 4),
        CustomText(title, fontSize: SizeConfig.small, color: Colors.grey),
      ],
    );
  }
}
