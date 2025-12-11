import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_card_widget.dart';
import '../../../../../widgets/custom_text_cm.dart';


class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  bool isGoLive = true;
  int selectedTab = 0;
  int selectedFilter = 0;

  final List<String> filters = [
    "Product",
    "Food",
    "Home Service",
    "Rental Service"
  ];

  final List<Map<String, String>> products = List.generate(8, (index) {
    return {
      "title": "Banerjee Inn - ${index + 1}",
      "desc": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "phone": "+91 1234567890",
      "image": "assets/diwali_card/rentalhome.png"
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 20),
              ),
              const Spacer(),
              CustomText(
                AppStrings.goLive,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: SizeConfig.size15,
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isGoLive,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.blue,
                  inactiveTrackColor: Colors.grey.shade300,
                  onChanged: (v) => setState(() => isGoLive = v),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab("My Products", 0),
                    const SizedBox(width: 40),
                    _buildTab("My Orders", 1),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 2,
                      color: Colors.grey.shade300,
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      left: selectedTab == 0
                          ? MediaQuery.of(context).size.width * 0.25 - 40
                          : MediaQuery.of(context).size.width * 0.75 - 90,
                      child: Container(
                        height: 2,
                        width: 100,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: Row(
              children: List.generate(filters.length, (index) {
                final selected = selectedFilter == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedFilter = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.grey.shade400,
                      ),
                    ),
                    child: CustomText(
                      filters[index],
                      color: selected ? Colors.white : Colors.black,
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 10),

          // Product Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                itemBuilder: (context, index) {
                  final item = products[index];
                  return CommonCardWidget(
                  //  padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                item["image"]!,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CustomText(
                          item["title"]!,
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.size14,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        CustomText(
                          item["desc"]!,
                          color: Colors.black54,
                          fontSize: SizeConfig.size12,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        const Divider(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 15, color: Colors.blue),
                            const SizedBox(width: 4),
                            CustomText(
                              item["phone"]!,
                              color: Colors.blue,
                              fontSize: SizeConfig.size12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final selected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: CustomText(
        title,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: Colors.black,
        fontSize: SizeConfig.size15,
      ),
    );
  }
}
