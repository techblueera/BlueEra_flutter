import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/image_grid_view.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/getplace_list_controller.dart';
import '../controller/getstore_list_controller.dart';

class OtherProfileDetailsBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final bool isUserProfile;
  final bool isPlaceService;
  final String placeId;

  OtherProfileDetailsBottomSheet(
      {required this.scrollController,
      required this.isUserProfile,
      required this.isPlaceService,
        required this.placeId,
      super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
        scrollController: scrollController,
        isUserProfile: isUserProfile,
        isPlaceService: isPlaceService,
      placeId: placeId,
    );
  }
}

class _SheetBody extends StatefulWidget {
  final ScrollController scrollController;
  final bool isUserProfile;
  final bool isPlaceService;
  final String placeId;

  const _SheetBody(
      {required this.scrollController,
      required this.isUserProfile,
      required this.isPlaceService,
        required this.placeId,
      });

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late List<String> category;
  late List<String> placeCategory;
  int selectedIndex = 0;
  final PlaceController controller = Get.put(PlaceController());
  final StoreController storeController = Get.put(StoreController());


  @override
  void initState() {
    if(widget.isPlaceService){
      controller.fetchPlaceDetail(placeId: widget.placeId);
    }else{
      storeController.fetchStoreDetail(storeId: widget.placeId);
    }

    category = widget.isUserProfile
        ? ['Overview', 'Ratings', 'Posts', 'Contact']
        : ['Overview', 'Directions', 'Posts', 'Ratings', 'Contact'];
    placeCategory = ['Overview', 'Directions', 'Posts', 'Rate This Place'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(()=>SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isPlaceService) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              controller.allPlaces[0].name,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.extraLarge,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.uploadIcon,
                                  imgColor: AppColors.black,
                                  width: SizeConfig.size24,
                                  height: SizeConfig.size24),
                              SizedBox(width: SizeConfig.size8),
                              InkWell(
                                onTap: ()=> Get.back(),
                                child: Icon(
                                  Icons.close,
                                  size: SizeConfig.size24,
                                  // color: AppColors.black,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, size: 10, color: AppColors.yellow00),
                              SizedBox(width: 2),
                              CustomText(
                                "4.8 ",
                                fontSize: SizeConfig.extraSmall,
                                color: AppColors.yellow00,
                              ),
                              SizedBox(width: 4),
                              CustomText(
                                "(48 reviews) · ",
                                fontSize: SizeConfig.extraSmall,
                                color: AppColors.grey6D,
                              ),
                              CustomText(
                                'Hindu Temple',
                                fontSize: SizeConfig.extraSmall,
                                color: AppColors.black30,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: AppColors.black,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400),
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: LocalAssets(
                                    imagePath: AppIconAssets.pinIcon,
                                    imgColor: AppColors.black),
                              ),
                            ),
                            TextSpan(text: 'Pinned by '),
                            TextSpan(
                              text: '@Priya Sharma',
                              style: TextStyle(
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors
                                    .primaryColor, // You can change to your theme color
                              ),
                            ),
                            TextSpan(
                              text: ' on 12 June 2025',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: SizeConfig.size10),

                      // Continue with your tabs, description, etc.
                      //TODO: Remove according to new figma
                     /* HorizontalTabSelector<String>(
                        tabs: placeCategory,
                        selectedIndex: selectedIndex,
                        onTabSelected: (index, value) {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        labelBuilder: (String value) {
                          return value;
                        },
                      ),*/

                   // SizedBox(height: SizeConfig.size20),
                    //TODO: Remove according to new figma
                    /*  Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                                onTap: (){},
                                title: 'Joined',
                                bgColor: Colors.transparent,
                                borderColor: AppColors.secondaryTextColor,
                                textColor: AppColors.secondaryTextColor,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: CustomBtn(
                              onTap: (){},
                              title: 'Tell about place',
                              bgColor: AppColors.primaryColor,
                              borderColor: AppColors.primaryColor,
                              textColor: AppColors.white,
                            ),
                          ),
                        ],

                      )*/

                    ],
                  ),
                )
              ]
              else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CachedAvatarWidget(
                          size: SizeConfig.size42,
                          borderRadius: SizeConfig.size26,
                          imageUrl:
                              'https://randomuser.me/api/portraits/men/30.jpg',
                          borderColor: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "Alex John",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black30,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size3),
                            CustomText(
                              "(Exp- 5 years)",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey6D,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalAssets(
                              imagePath: AppIconAssets.uploadIcon,
                              imgColor: AppColors.black,
                              width: SizeConfig.size24,
                              height: SizeConfig.size24),
                          SizedBox(width: SizeConfig.size8),
                          InkWell(
                            onTap: ()=> Get.back(),
                            child: Icon(
                              Icons.close,
                              size: SizeConfig.size24,
                              // color: AppColors.black,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size5),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 10, color: AppColors.yellow00),
                          SizedBox(width: 2),
                          CustomText(
                            "4.8 ",
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.yellow00,
                          ),
                          SizedBox(width: 4),
                          CustomText(
                            "(48 reviews) · ",
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.grey6D,
                          ),
                          CustomText(
                            'Electrician',
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.black30,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      CustomText('Joined us 1 year ago',
                          fontSize: SizeConfig.small, color: AppColors.grey9A)
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size7),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText('Service Charge: 100 INR',
                          fontSize: SizeConfig.small, color: AppColors.grey9A),
                      SizedBox(height: SizeConfig.size10),
                      CustomText('10Kms Away',
                          fontSize: SizeConfig.small, color: AppColors.grey9A)
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size10),

                // Continue with your tabs, description, etc.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: HorizontalTabSelector<String>(
                    tabs: category,
                    selectedIndex: selectedIndex,
                    onTabSelected: (index, value) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    labelBuilder: (String value) {
                      return value;
                    },
                  ),
                ),
              ],

              SizedBox(height: SizeConfig.size20),
              if(widget.isPlaceService == false) ...[

                /// Image Grid with overlay
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: ImageGridView(
                    images: storeController.allStore[0].livePhotos!,
                    imageHeight: SizeConfig.size130,
                    maxVisible: 4,
                    appBarTitle: AppLocalizations.of(context)!.imageViewer,
                  ),
                ),

                SizedBox(height: SizeConfig.size20),

                /// Description
                _buildTitleWidget(title: "Description"),
                _buildDescriptionWidget(
                  description:
                  storeController.allStore[0].businessDescription!,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Location
                _buildTitleWidget(title: "Location"),
                _buildDescriptionWidget(
                    description:
                    storeController.allStore[0].address!),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Phone Number
                _buildTitleWidget(title: "Phone Number"),

                _buildDescriptionWidget(description: storeController.allStore[0].businessNumber!.officeMobNo!.number.toString()),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Distance
                _buildTitleWidget(title: "Distance From you"),
                _buildDescriptionWidget(
                    description: "2.3 km away from your location"),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Timings
                _buildTitleWidget(title: "Timings"),
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size20, right: SizeConfig.size20),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: AppColors.black30,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: 'Open ',
                          style: TextStyle(
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: Colors
                                .greenAccent, // You can change to your theme color
                          ),
                        ),
                        /*TextSpan(
                          text: " ${controller.allPlaces[0].visitingHours[0].startTime}AM - ${controller.allPlaces[0].visitingHours[0].endTime} PM",
                        ),*/
                      ],
                    ),
                  ),
                )
              ] else...[
                /// Image Grid with overlay
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: ImageGridView(
                    images: controller.allPlaces[0].photos,
                    imageHeight: SizeConfig.size130,
                    maxVisible: 4,
                    appBarTitle: AppLocalizations.of(context)!.imageViewer,
                  ),
                ),

                SizedBox(height: SizeConfig.size20),

                /// Description
                _buildTitleWidget(title: "Description"),
                /*_buildDescriptionWidget(
                  description:
                  controller.allPlaces[0].shortDescription,),*/
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Location
                _buildTitleWidget(title: "Location"),
                /*_buildDescriptionWidget(
                  description:
                  controller.allPlaces[0].location.address),*/
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Phone Number
                _buildTitleWidget(title: "Phone Number"),
/*
              _buildDescriptionWidget(description: controller.allPlaces[0].phone),
*/
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Distance
                _buildTitleWidget(title: "Distance From you"),
                _buildDescriptionWidget(
                    description: "2.3 km away from your location"),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  child: CommonHorizontalDivider(
                    color: AppColors.greyCA,
                  ),
                ),

                /// Timings
                _buildTitleWidget(title: "Timings"),
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size20, right: SizeConfig.size20),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: AppColors.black30,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: 'Open ',
                          style: TextStyle(
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: Colors
                                .greenAccent, // You can change to your theme color
                          ),
                        ),
                        TextSpan(
                          text: " ${controller.allPlaces[0].visitingHours[0].startTime}AM - ${controller.allPlaces[0].visitingHours[0].endTime} PM",
                        ),
                      ],
                    ),
                  ),
                )
              ],

            ],
          ),
        ),
      ),),
    );
  }

  Widget _buildTitleWidget({required String title}) {
    return Padding(
      padding: EdgeInsets.only(
          top: SizeConfig.size15,
          bottom: SizeConfig.size8,
          left: SizeConfig.size20,
          right: SizeConfig.size20),
      child: CustomText(
        title,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDescriptionWidget({required String description, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: SizeConfig.size8,
          left: SizeConfig.size20,
          right: SizeConfig.size20),
      child: CustomText(
        description,
        color: color ?? AppColors.black30,
      ),
    );
  }
}
