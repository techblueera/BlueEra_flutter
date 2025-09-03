import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/store/controller/channel_product_controller.dart';
import 'package:BlueEra/features/common/store/models/get_channel_product_model.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';

class ProductPopUpMenu extends StatelessWidget {
  final String channelId;
  final ProductData productData;
  const ProductPopUpMenu({super.key, required this.channelId, required this.productData});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(-6, 36),
        color: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (value) async {
          if (value == 'Edit Product') {
            Get.toNamed(
                RouteHelper.getAddUpdateProductScreenRoute(),
                arguments: {
                  ApiKeys.channelId: channelId,
                  ApiKeys.argProductData: productData
                }
            );
          } else if (value == 'Delete Product') {
            await showCommonDialog(
                context: context,
                text: 'Are you sure you want to delete this product?',
                confirmCallback: () {
                  Get.find<ChannelProductController>().deleteChannelProduct(productId: productData.sId??'');
                },
                cancelCallback: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                confirmText: AppLocalizations.of(context)!.yes,
                cancelText: AppLocalizations.of(context)!.no);
          }
        },
        icon: Icon(Icons.more_vert, color: AppColors.white),
        itemBuilder: (context) => popupProductMenuItems(),
      ),
    );
  }
}