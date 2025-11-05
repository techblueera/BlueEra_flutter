import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
class RiderRequestMsgCard extends StatelessWidget {
  const RiderRequestMsgCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth*0.7,
      // height: 310,
      // responsive width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size10,),

            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: SizeConfig.size10,),
                CustomText(
                  "Hello,  You’ve received a new delivery order.",
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size10,),
                CustomText(
                  "Please proceed to the pickup point and confirm the delivery status in the app once collected.",
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.primaryColor,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size8),
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.blueLightShade,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.greyE5
                      ),
                      boxShadow: [
                        AppShadows.bottomShadow
                      ]
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Pickup Location: 2.5 KM,\nLaxmi Nagar, Gupta General Store, 2.5K Orders, Lucknow Gomtinagar",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      CustomText(
                        "Drop Location: 10KM.\nBishnupur, Lucknow Gomtinagar, Shiva Samaddar",
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    CustomText(
                      "Ride Charge  - ",
                      fontSize: SizeConfig.size12,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      color: AppColors.secondaryTextColor,
                    ),
                    CustomText(
                      "₹108",
                      fontSize: SizeConfig.size16,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          const Divider(height: 1,color: Colors.grey,),
          SizedBox(height: SizeConfig.size8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: SizeConfig.size4,),
                      const Icon(Icons.close, color: Colors.red,),
                      SizedBox(width: SizeConfig.size8,),
                      CustomText(
                        'Reject Order',
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                ),
                 VerticalDivider(width: 2,color: Colors.grey,),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: SizeConfig.size4,),
                      const Icon(Icons.check,color: AppColors.primaryColor, ),
                      SizedBox(width: SizeConfig.size8,),
                      CustomText(
                        'Accept Order',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size10,)

        ],
      ),
    );
  }
}
