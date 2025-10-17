import 'package:BlueEra/features/common/reel/controller/channel_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class ChannelProductListing extends StatefulWidget {
  final ChannelController channelController;

  const ChannelProductListing({
    super.key,
    required this.channelController,
  });

  @override
  State<ChannelProductListing> createState() => _ChannelProductListingState();
}

class _ChannelProductListingState extends State<ChannelProductListing> {
  late final InventoryController inventoryController;

  @override
  void initState() {
    super.initState();

    // Register or find controller
    if (Get.isRegistered<InventoryController>()) {
      inventoryController = Get.find<InventoryController>();
    } else {
      inventoryController = Get.put(InventoryController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.channelController.fetchOwnChannelProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final productList = widget.channelController.ownProductDataList;

      if (widget.channelController.isOwnProductDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (productList.isEmpty) {
        return const EmptyStateWidget(message: 'No product found');
      }

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: productList.length,
              itemBuilder: (context, index) {
                final productData = productList[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size10),
                  child: OwnProductCard(
                    product: productData,
                    controller: inventoryController,
                    isGridShow: false
                  ),
                );
              },
            ),
          ),
          if (widget.channelController.isOwnProductDataLoadingMore.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    });
  }
}
