import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/rider_order_collect/items_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemsScreen extends StatelessWidget {
  final ItemsController controller = Get.put(ItemsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          isRejectButton: true,
          title: "Items",
          rejectButton: () {
            return Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.only(right: 8.0, top: 5, bottom: 5, left: 8),
              child: CustomText(
                "Reject",
                color: AppColors.red00,
                fontSize: SizeConfig.small,
              ),
              decoration: BoxDecoration(
                  color: AppColors.redLite.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.redLite)),
            );
          }),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) => _buildStoreCard(index),
              ),
            ),
            _buildBottomWarning(context),
            SizedBox(
              height: SizeConfig.size16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    List<String> filters = ["Suggested", "Cheapest", "Nearest", "Manually"];
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            decoration: BoxDecoration(
                border: Border.all(
                    color: index == 0
                        ? AppColors.transparent
                        : AppColors.shadowColor),
                color: index == 0 ? AppColors.primaryColor : AppColors.white,
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: CustomText(
              filters[index],
              color:
                  index == 0 ? AppColors.white : AppColors.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(int index) {
    return Obx(() => Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.cyan[100], child: Icon(Icons.person)),
            title:
                CustomText("Gupta General Store", fontWeight: FontWeight.bold),
            subtitle: CustomText("10 Items Available • ₹ 1000 Price"),
            trailing: Checkbox(
              value: controller.selectedStoreIndex.value == index,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => controller.toggleStore(index),
            ),
          ),
        ));
  }

  Widget _buildBottomWarning(BuildContext context) {
    return InkWell(
      onTap: () => _showMissingItemsSheet(context),
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText("10 Items Missing In Your Store",
                color: Colors.red[700]),
            CustomText("View",
                color: AppColors.primaryColor, fontWeight: FontWeight.bold),
          ],
        ),
      ),
    );
  }
}

void _showMissingItemsSheet(BuildContext context) {
  final ItemsController controller = Get.find();

  Get.bottomSheet(
    SafeArea(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText("Missing Items",
                    fontSize: 18, fontWeight: FontWeight.bold),
                IconButton(icon: Icon(Icons.close), onPressed: () => Get.back()),
              ],
            ),
            Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 3,
                itemBuilder: (context, index) => Obx(() => Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Image.network("https://via.placeholder.com/50",
                            width: 50),
                        title: CustomText("Supreme Traditional Basmat..."),
                        subtitle: CustomText("500 gm | ₹199"),
                        trailing: Checkbox(
                          value: controller.checkedItems[index] ?? false,
                          onChanged: (val) => controller.toggleItem(index),
                        ),
                      ),
                    )),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
      
                Expanded(child: PositiveCustomBtn(onTap: null, title: "Unable to Pick",borderColor: AppColors.primaryColor,bgColor: AppColors.white,textColor: AppColors.primaryColor,)),
                SizedBox(width: 12),
      
                Expanded(child: PositiveCustomBtn(onTap: null, title: "Call Customer",)),
                // Expanded(
                //   child: ElevatedButton(
                //     onPressed: () {},
                //     child: CustomText("Call Customer"),
                //     style: ElevatedButton.styleFrom(
                //         backgroundColor:AppColors.primaryColor, minimumSize: Size(0, 50)),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 16),
            
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
