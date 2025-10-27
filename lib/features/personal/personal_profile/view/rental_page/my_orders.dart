import 'package:flutter/material.dart';


import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_card_widget.dart';
import '../../../../../widgets/custom_text_cm.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool isGoLive = true;
  int selectedTab = 1; // My Orders active
  int selectedFilter = 0; // All

  final List<String> filters = ["All", "Product", "Food", "Home Services", "Rental"];

  final List<Map<String, dynamic>> orders = [
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Active"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Active"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Active"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Cancelled"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Cancelled"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Cancelled"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Completed"},
    {"title": "Banerjee Inn", "desc": "3BHK, with swimming pool, a big garden...", "status": "Completed"},
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      "Go Live",
                      color: Colors.blue,
                      fontSize: SizeConfig.size15,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(width: 6),
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
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.black),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab("My Products", 0),
                    const SizedBox(width: 40),
                    _buildTab(" ", 1),
                  ],
                ),
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 4),
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: MediaQuery.of(context).size.width / 2,
                        color: selectedTab == 0 ? Colors.blue : Colors.transparent,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: MediaQuery.of(context).size.width / 2,
                        color: selectedTab == 1 ? Colors.blue : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: Row(
              children: List.generate(filters.length, (index) {
                final selected = selectedFilter == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedFilter = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white,
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: CustomText(
                      filters[index],
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size14,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 10),

          // Orders List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return CommonCardWidget(
                //  padding: SizeConfig.heading,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          "assets/diwali_card/rentalhome.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              order["title"],
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.size15,
                            ),
                            const SizedBox(height: 3),
                            CustomText(
                              order["desc"],
                              color: Colors.black54,
                              fontSize: SizeConfig.size13,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            "9:52 PM",
                            color: Colors.black54,
                            fontSize: SizeConfig.size12,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: _getStatusColor(order["status"])),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: CustomText(
                              order["status"],
                              color: _getStatusColor(order["status"]),
                              fontSize: SizeConfig.size13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
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
