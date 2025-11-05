import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final PickUpTab selectedPickUp;
  const OrderCard({super.key, required this.selectedPickUp});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: '',
                    imageUrls: ['profileImage'],
                    initialIndex: 0,
                  ),
                ),
                child: CachedAvatarWidget(
                  imageUrl: 'profileImage',
                  size: SizeConfig.size40,
                  borderRadius: SizeConfig.size20,
                ),
              ),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Amit Kumar',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        'Item Name: Men Sports Shoe',
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w400,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  )
              ),
              SizedBox(width: SizeConfig.size6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    '9:52 PM',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey9A
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor
                      ),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100.0)
                    ),
                    child: CustomText(
                      'Review',
                      fontSize: SizeConfig.small11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: SizeConfig.size14),
          Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.whiteE5
                ),
                color: AppColors.whiteFE,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [AppShadows.textFieldShadow]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                            'Pick- Up: ',
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                          CustomText(
                            '2.5KM',
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        'Laxmi Nagar, Gupta General Store, 2.5K Orders, Lucknow Gomtinagar',
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                Container(
                  height: SizeConfig.size1,
                  width: double.infinity,
                  color: AppColors.whiteE5
                ),

                Padding(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                            'Drop Location: ',
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                          CustomText(
                            '10KM',
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        'Bishnupur, Lucknow Gomtinagar, +91 1234567890',
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                )

              ],
            ),
          ),
          SizedBox(height: SizeConfig.size14),
          Builder(
            builder: (BuildContext context) {
              switch (selectedPickUp) {
                case PickUpTab.newOrder:
                  return _buildNewPickupButtons();

                case PickUpTab.onGoing:
                  return _buildOnGoingPickupOrderButton();

                case PickUpTab.completed:
                  return SizedBox();

                case PickUpTab.cancel:
                  return SizedBox();

                case PickUpTab.rejected:
                  return SizedBox();
              }
            })
        ],
      ),
    );
  }

  Widget _buildNewPickupButtons() {
    return Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size8,
            ),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100.0)
            ),
            child: CustomText(
              'Fare: ₹ 89.0',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Spacer(),
          _buildActionButton(
           onTap: (){},
            text: 'Chat',
            bgColor: AppColors.whiteFE,
            borderColor: AppColors.secondaryTextColor,
            textColor: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size6),
          _buildActionButton(
            onTap: (){},
            text: 'Reject',
            bgColor: AppColors.redLite.withValues(alpha: 0.1),
            borderColor: AppColors.redLite,
            textColor: AppColors.redLite,
          ),
          SizedBox(width: SizeConfig.size6),
          _buildActionButton(
            onTap: (){},
            text: 'Accept',
            bgColor: AppColors.green0B.withValues(alpha: 0.1),
            borderColor: AppColors.green0B,
            textColor: AppColors.green0B,
          ),
     ]
    );
  }

  Widget _buildOnGoingPickupOrderButton() {
    return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              onTap: (){},
              icon: Icons.location_on_outlined,
              text: 'Pick-Up Location',
              bgColor: AppColors.whiteFE,
              borderColor: AppColors.secondaryTextColor,
              textColor: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: _buildActionButton(
              onTap: (){},
              icon: Icons.call,
              text: '1234567890',
              bgColor: AppColors.whiteFE,
              borderColor: AppColors.secondaryTextColor,
              textColor: AppColors.secondaryTextColor,
            ),
          ),
        ]
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    IconData? icon,
  }){
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor
            ),
            borderRadius: BorderRadius.circular(100.0)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(icon!=null)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Icon(icon, color: textColor),
            ),
            CustomText(
              text,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
