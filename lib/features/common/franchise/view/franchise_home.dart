import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/franchise/view/widget/franchise_header.dart';
import 'package:BlueEra/features/common/franchise/view/widget/franchise_req_dialoge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../../../widgets/expandable_text.dart';
import '../../../me/hospital/controller/hospital_model_controller.dart';

class FranchiseHome extends StatefulWidget {
  const FranchiseHome({super.key});

  @override
  State<FranchiseHome> createState() => _FranchiseHomeState();
}

class _FranchiseHomeState extends State<FranchiseHome> {
  int selectedTab = 0;
  final controller = getOrPut(() => HospitalModelController());
  late MapplsMapController mapController;

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
  }
@override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((val){
      showDialogs();
    });
    super.initState();
  }
  void showDialogs(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PartnerUnavailableDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: SizedBox(),
            expandedHeight: Get.height * 0.36,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.appBackgroundColor,
                child: FranchiseHeader(
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                    width: 128,
                                    height: 160,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10),
                                        ),
                                        image: DecorationImage(image: AssetImage(AppImageAssets.grocery_call_women),
                                            fit: BoxFit.fill
                                        )
                                    )),
                                Expanded(
                                  child: Padding(
                                    padding:  EdgeInsets.all(SizeConfig.size10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        CustomText("Morning Grocery - Door Step",fontSize: 14,fontWeight: FontWeight.w700,),
                                        SizedBox(height: SizeConfig.size10,),
                                        CustomText("Grocery -",fontSize: 10,fontWeight: FontWeight.w600,),
                                        SizedBox(height: SizeConfig.size2,),
                                        CustomText("Milk, Bread, Rice, Sugar, Salt, Ghee, Oil.....",fontSize: 10,color: AppColors.grayText,fontWeight: FontWeight.w400,),
                                        SizedBox(height: SizeConfig.size10,),
                                        CustomText("Vegetable & Fruit -",fontSize: 10,fontWeight: FontWeight.w600,),
                                        SizedBox(height: SizeConfig.size2,),
                                        CustomText("Potato, Onion, Tomato, Palak, Mango....",fontSize: 10,color: AppColors.grayText,fontWeight: FontWeight.w400,),
                                        SizedBox(height: SizeConfig.size10,),
                                        Row(mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            CustomBtn(
                                                isValidate: true,
                                                width: 68,
                                                height: 30,
                                                onTap: (){

                                                }, title: "Book Now"),

                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      CommonCardWidget(
                          padding: 10,
                          cardMargin: 0,
                          child:Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText("Book Your Home Service",fontSize: 16,fontWeight: FontWeight.w600,),
                              SizedBox(
                                height: SizeConfig.size10,
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for(int i=0;i<3;i++)
                                    Container(
                                      width: 114,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                      margin: EdgeInsets.only(right: 10),
                                      child: Stack(
                                        children: [
                                          CustomImageSlideshow(
                                            isLoading: false,
                                            width: double.infinity,
                                            height: SizeConfig.size130,
                                            imagePaths: [''],
                                            borderRadius: BorderRadius.circular(10),
                                            onPhotoIndex: (index) {

                                            },
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              child: Container(
                                                width: 114,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(10),
                                                        bottomRight: Radius.circular(10)),
                                                    gradient: LinearGradient(
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                        colors: [
                                                          AppColors.black.withOpacity(0.5),
                                                          AppColors.black.withOpacity(0.01),
                                                        ])
                                                ),
                                                padding: EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CustomText("Electrician",
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.white,),
                                                  ],
                                                ),
                                              ))
                                        ],
                                      ),
                                      // child: ,
                                    ),

                                ],
                              ),
                              SizedBox(height: SizeConfig.size10,),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for(int i=0;i<3;i++)
                                    Container(
                                      width: 114,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                      margin: EdgeInsets.only(right: 10),
                                      child: Stack(
                                        children: [
                                          CustomImageSlideshow(
                                            isLoading: false,
                                            width: double.infinity,
                                            height: SizeConfig.size130,
                                            imagePaths: [''],
                                            borderRadius: BorderRadius.circular(10),
                                            onPhotoIndex: (index) {

                                            },
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              child: Container(
                                                width: 114,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(10),
                                                        bottomRight: Radius.circular(10)),
                                                    gradient: LinearGradient(
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                        colors: [
                                                          AppColors.black.withOpacity(0.5),
                                                          AppColors.black.withOpacity(0.01),
                                                        ])
                                                ),
                                                padding: EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CustomText("Plumber",
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.white,),
                                                  ],
                                                ),
                                              ))
                                        ],
                                      ),
                                      // child: ,
                                    ),

                                ],
                              )
                            ],
                          )
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      CommonCardWidget(
                          padding: 10,
                          cardMargin: 0,
                          child:Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText("Bookings",fontSize: 16,fontWeight: FontWeight.w600,),
                              SizedBox(
                                height: SizeConfig.size14,
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for(int i=0;i<3;i++)
                                    Container(
                                      width: 114,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                      margin: EdgeInsets.only(right: 10),
                                      child: Stack(
                                        children: [
                                          CustomImageSlideshow(
                                            isLoading: false,
                                            width: double.infinity,
                                            height: SizeConfig.size130,
                                            imagePaths: [''],
                                            borderRadius: BorderRadius.circular(10),
                                            onPhotoIndex: (index) {

                                            },
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              child: Container(
                                                width: 114,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(10),
                                                        bottomRight: Radius.circular(10)),
                                                    gradient: LinearGradient(
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                        colors: [
                                                          AppColors.black.withOpacity(0.5),
                                                          AppColors.black.withOpacity(0.01),
                                                        ])
                                                ),
                                                padding: EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CustomText("Parcel/Courier",
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.white,),
                                                  ],
                                                ),
                                              ))
                                        ],
                                      ),
                                      // child: ,
                                    ),

                                ],
                              ),
                              SizedBox(height: SizeConfig.size10,),
                            ],
                          )
                      ),
                      SizedBox(height: SizeConfig.size10,),
                      CommonCardWidget(
                        padding: 10,
                        cardMargin: 0,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Complaints ",fontSize: 16,fontWeight: FontWeight.w600,),
                            SizedBox(
                              height: SizeConfig.size14,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.white,
                                  border: Border.all(
                                      color: AppColors.whiteE5
                                  )
                              ),
                              padding: EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ExpandableText(
                                      text:"Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio matter lore...",
                                      trimLines: 2,
                                      isReadMoreNewLine: false,
                                      expandMode: ExpandMode.dialog,
                                      style: TextStyle(
                                        color: AppColors.secondaryTextColor,
                                        fontSize: SizeConfig.large,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: AppConstants.OpenSans,
                                      ),
                                    ),
                                    SizedBox(height: 10,),
                                    Container(
                                      height: 1,
                                      color: AppColors.whiteE5,
                                    ),
                                    SizedBox(height: 10,),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: AppColors.whiteE5, width: 4),
                                                  // boxShadow: [
                                                  //   BoxShadow(color: Colors.black12, blurRadius: 10)
                                                  // ],
                                                  image:
                                                  DecorationImage(
                                                      image: AssetImage(AppIconAssets.hospitalHistoryIcon),
                                                      fit: BoxFit.fill)
                                              ),
                                            ),
                                            SizedBox(width: 10,),
                                            Column(crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CustomText("Dr. Rasmika Gupta",fontSize: 12,fontWeight: FontWeight.w600,),
                                                SizedBox(height: SizeConfig.size2,),
                                                CustomText("Supporting Team",fontSize: 10,color: AppColors.grayText,fontWeight: FontWeight.w600,),

                                              ],
                                            )
                                          ],
                                        ),
                                        Container(
                                          height: 24,
                                          width: 120,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: AppColors.primaryColor
                                              ),
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: Center(
                                            child: CustomText("Raise Your Complaint",fontSize: 10,),
                                          ),
                                        )
                                      ],
                                    )
                                  ]
                              ),
                            )

                          ],
                        ),),
                      SizedBox(height: SizeConfig.size10,),
                      CommonCardWidget(
                          padding: 10,
                          cardMargin: 0,
                          child:
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText("Contact Us",fontSize: 16,fontWeight: FontWeight.w600,),
                              SizedBox(
                                height: SizeConfig.size10,
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.whiteE5),
                                  boxShadow: [
                                    AppShadows.bottomShadow
                                  ]
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText("Francize Name",fontSize: 16,fontWeight: FontWeight.w600,),
                                    SizedBox(height: SizeConfig.size8,),
                                    Row(
                                      children: [
                                        LocalAssets(imagePath: AppIconAssets.link
                                          , height: 18, width: 18,),
                                        SizedBox(
                                          width: SizeConfig.size6,
                                        ),
                                        Expanded(child:
                                        CustomText(
                                          "https://dpsdehradun.com",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        )),
                                      ],
                                    ),

                                    SizedBox(height: SizeConfig.size8,),
                                    Row(
                                      children: [
                                        LocalAssets(
                                          imagePath: AppIconAssets.admission_cell
                                          , height: 18, width: 18,),
                                        SizedBox(
                                          width: SizeConfig.size6,
                                        ),
                                        Expanded(child:
                                        CustomText(
                                          "Admission Cell",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.black,
                                        )),
                                      ],
                                    ),
                                    SizedBox(height: SizeConfig.size8,),
                                    Row(
                                      children: [
                                        LocalAssets(
                                          imagePath: AppIconAssets.mail_new
                                          , height: 16, width: 16,),
                                        SizedBox(
                                          width: SizeConfig.size6,
                                        ),
                                        Expanded(child:
                                        CustomText(
                                          "dpsdehradun@gmail.com",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.black,
                                        )),
                                      ],
                                    ),
                                    SizedBox(height: SizeConfig.size8,),
                                    Row(
                                      children: [
                                        LocalAssets(
                                          imagePath: AppIconAssets.chat_call
                                          , height: 18, width: 18,),
                                        SizedBox(
                                          width: SizeConfig.size6,
                                        ),
                                        Expanded(child:
                                        CustomText(
                                          "+91 1234567890",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.black,
                                        )),
                                      ],
                                    ),

                                  ],
                                ),
                              ),
                              SizedBox(height: SizeConfig.size10,),
                              Row(
                                children: [
                                  LocalAssets(
                                    imagePath: AppIconAssets.location_new
                                    , height: 18, width: 18,),
                                  SizedBox(
                                    width: SizeConfig.size6,
                                  ),
                                  Expanded(child:
                                  CustomText(
                                    "Forem ipsum dolor sit amet, consectetur....",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.black,
                                  )),
                                ],
                              ),
                              SizedBox(height: SizeConfig.size10,),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: SizeConfig.size160,
                                    child: Stack(
                                      children: [
                                        MapplsMap(
                                          onMapCreated: _onMapCreated,
                                          initialCameraPosition: CameraPosition(
                                            target:LatLng(26.8311, 80.9244),
                                            zoom: 14.0,
                                          ),
                                          myLocationEnabled: false,
                                          compassEnabled: false,
                                          rotateGesturesEnabled: true,
                                          tiltGesturesEnabled: true,
                                          zoomGesturesEnabled: true,
                                          scrollGesturesEnabled: true,
                                        ),
                                      ],
                                    ),
                                  )
                              ),
                            ],
                          ))

                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size150,),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
