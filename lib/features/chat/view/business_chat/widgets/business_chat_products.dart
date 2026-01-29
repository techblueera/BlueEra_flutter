import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../../../widgets/custom_text_cm.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../common/product_listing/widgets/product_card_business.dart';

class BusinessChatProducts extends StatefulWidget {
  final String businessId;
  final String conversationId;

  const BusinessChatProducts(
      {super.key, required this.businessId, required this.conversationId});

  @override
  State<BusinessChatProducts> createState() => _BusinessChatProductsState();
}

class _BusinessChatProductsState extends State<BusinessChatProducts> {
  final controller = Get.isRegistered<ViewBusinessDetailsController>()
      ? Get.find<ViewBusinessDetailsController>()
      : Get.put(ViewBusinessDetailsController());

  @override
  void initState() {
    // TODO: implement initState
    controller.fetchProducts(
        visitBusinessId: widget.businessId, isSilent: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.businessProductResponse.value.status == Status.COMPLETE) {
        return _buildGridView(controller);
      }
      return Center(child: CircularProgressIndicator());
    });
  }

  Widget _buildGridView(ViewBusinessDetailsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const crossSpacing = 10.0;
        const mainSpacing = 12.0;

        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                crossAxisCount;

        return controller.products.isEmpty
            ? Center(
                child: CustomText(AppStrings.noProductFound),
              )
            : MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                itemCount: controller.products.length,
                shrinkWrap: true,
                // physics: const NeverScrollableScrollPhysics(),
                // let parent scroll handle it
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final product = controller.products[index];
                  return ProductCardBusiness(
                      businessId: widget.businessId,
                      conversationId: widget.conversationId,
                      isShowEnquiry: true,
                      isShowChat: false,
                      productData: product,
                      businessData: null,
                      width: itemWidth,
                      isShowKM: true);
                },
              );
      },
    );
  }
}
