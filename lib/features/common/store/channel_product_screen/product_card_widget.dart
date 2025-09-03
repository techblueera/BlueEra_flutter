import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/reel/widget/product_popup_menu.dart';
import 'package:BlueEra/features/common/store/models/get_channel_product_model.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';

class ProductCardWidget extends StatelessWidget {
  final String channelId;
  final ProductData productData;

  const ProductCardWidget({
    super.key,
    required this.channelId,
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // Increase as needed for your layout
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: CachedNetworkImage(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size130,
                  fit: BoxFit.cover,
                  imageUrl: productData.image ??'',
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white, width: 1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: LocalAssets(
                        imagePath: AppIconAssets.blueEraIcon,
                        boxFix: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              if (channelId == channelId)
                ProductPopUpMenu(
                    channelId: channelId,
                    productData: productData)
            ],
          ),

          // Text Section
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  productData.name,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size5),

                CustomText(
                  productData.description,
                  fontSize: SizeConfig.extraSmall,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size5),

                CustomText(
                  productData.price,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size5),

                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 12,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: SizeConfig.size4),
                    Expanded(
                      child: CustomText(
                        productData.link,
                        fontSize: SizeConfig.extraSmall,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

} 