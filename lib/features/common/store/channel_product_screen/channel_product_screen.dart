import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/features/common/store/channel_product_screen/product_card_widget.dart';
import 'package:BlueEra/features/common/store/controller/channel_product_controller.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/size_config.dart';

class ChannelProductScreen extends StatefulWidget {
  final String channelId;
  final bool isOwnChannel;
  const ChannelProductScreen({super.key, required this.channelId, required this.isOwnChannel,});

  @override
  State<ChannelProductScreen> createState() => _ChannelProductScreenState();
}

class _ChannelProductScreenState extends State<ChannelProductScreen> {
  late final String uniqueTag;
  late final ChannelProductController controller;

  @override
  void initState() {
    super.initState();
    uniqueTag = 'reel_product_details_${DateTime.now().millisecondsSinceEpoch}';
    Get.lazyPut<ChannelProductController>(() => ChannelProductController(), tag: uniqueTag);
    controller = Get.find<ChannelProductController>(tag: uniqueTag);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllChannelProduct(channelId: widget.channelId, isInitialLoad: true);
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<ChannelProductController>(tag: uniqueTag)) {
      Get.delete<ChannelProductController>(tag: uniqueTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   return Obx((){
      if(controller.allChannelProductsFirstLoading.isFalse){
        if(controller.channelAllProductResponse.status == Status.COMPLETE){

          if(controller.allChannelProducts.isEmpty){
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size80),
                child: EmptyStateWidget(
                  message: 'No products available.',
                ),
              ),
            );
          }

          return LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 16) / 2;
                final itemHeight = SizeConfig.size240;
                return GridView.builder(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemCount: controller.allChannelProducts.length,
                  itemBuilder: (context, index) {
                    final productItem = controller.allChannelProducts[index];
                    return ProductCardWidget(
                      channelId: widget.channelId,
                      productData: productItem,
                    );
                  },
                );
              }
          );
        }else{
          return LoadErrorWidget(
              errorMessage: 'Failed to load products',
              onRetry: ()=> controller.getAllChannelProduct(channelId: widget.channelId, isInitialLoad: true)
          );
        }
      }else{
        return Center(child: CircularProgressIndicator());
      }
    });


  }
} 