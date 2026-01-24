import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../common/food/view/widget/food_product_card.dart';

class BusinessChatFoods extends StatefulWidget {
  final String businessId;
  final String conversationId;

  const BusinessChatFoods(
      {super.key, required this.businessId, required this.conversationId});

  @override
  State<BusinessChatFoods> createState() => _BusinessChatFoodsState();
}

class _BusinessChatFoodsState extends State<BusinessChatFoods> {
  final controller = Get.isRegistered<ViewBusinessDetailsController>()
      ? Get.find<ViewBusinessDetailsController>()
      : Get.put(ViewBusinessDetailsController());

  @override
  void initState() {
    controller.fetchFoods(visitBusinessId: widget.businessId, isSilent: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.businessFoodResponse.value.status == Status.COMPLETE) {
        return _buildGridView(controller);
      }
      return Center(child: CircularProgressIndicator());
    });
  }

  Widget _buildGridView(ViewBusinessDetailsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const crossSpacing = 6.0;
        const mainSpacing = 6.0;

        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                crossAxisCount;
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: mainSpacing,
          itemCount: controller.foods.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            final food = controller.foods[index];
            return FoodCardBusiness(
              isShowEnquiry: true,
              businessId: widget.businessId,
              conversationId: widget.conversationId,
              isShowChat: false,
              serviceData: food,
              isGridView: true,
              businessData: null,
              width: itemWidth,
            );
          },
        );
      },
    );
  }
}
