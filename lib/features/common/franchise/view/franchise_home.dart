import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/franchise/view/widget/franchise_header.dart';
import 'package:BlueEra/features/common/franchise/view/widget/franchise_req_dialoge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/expandable_text.dart';

class FranchiseHome extends StatefulWidget {
  final Function? onBackPressed;
  const FranchiseHome({super.key, this.onBackPressed});

  @override
  State<FranchiseHome> createState() => _FranchiseHomeState();
}

class _FranchiseHomeState extends State<FranchiseHome> {
  int selectedTab = 0;
  late GoogleMapController mapController;
  Set<Marker> _markers = {};

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)),
        AppImageAssets.markerBlue,
      );

      // 2. Create Marker
      final Marker customMarker = Marker(
        markerId: const MarkerId("custom_marker_id"),
        position: LatLng(26.2389, 73.0243),
        icon: customIcon,
      );

      setState(() {
        _markers.add(customMarker);
      });

      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(26.2389, 73.0243), 14.0),
      );

    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((val){
      showDialogs();
    });
    super.initState();
  }

  void showDialogs(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartnerUnavailableDialog(
        backPressed: (){
          if(widget.onBackPressed==null){
            Navigator.pop(context);
          } else{
            widget.onBackPressed!();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.onBackPressed==null) ? CommonBackAppBar() : null,
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
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
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

                      SizedBox(height: SizeConfig.paddingXSL),

                      CustomFormCard(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _title("Book Your Home Service")
                                  ),
                                  SizedBox(
                                    width: SizeConfig.size8,
                                  ),
                                  CustomText(
                                      'View All',
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              MasonryGridView.count(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                itemCount: Get.find<AuthController>().individualOnboardingSkillWorkList
                                    .take(6)
                                    .length,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  var item =
                                  Get.find<AuthController>().individualOnboardingSkillWorkList[index];
                                  return _commonCard(icon: getIndividualProfessionIcon(item.tagId), text: item.name ?? '');
                                },
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: SizeConfig.paddingXSL),

                      CustomFormCard(

                          padding: EdgeInsets.all(SizeConfig.size10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             _title('Bookings'),

                              SizedBox(height: SizeConfig.paddingXSL),

                              MasonryGridView.count(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                itemCount: bookingList.length,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  var item = bookingList[index];
                                  return _commonCard(icon: item.icon??'', text: item.name);
                                },
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                              ),
                            ],
                          )
                      ),

                      SizedBox(height: SizeConfig.paddingXSL),

                      CustomFormCard(
                        padding: EdgeInsets.all(SizeConfig.size10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title("Complaints"),
                            SizedBox(
                              height: SizeConfig.paddingXSL,
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
                      SizedBox(height: SizeConfig.paddingXSL),

                      CustomFormCard(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          child:
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _title("Contact Us"),
                              SizedBox(
                                height: SizeConfig.paddingXSL,
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

                                        GoogleMap(
                                          onMapCreated: _onMapCreated,
                                          initialCameraPosition: CameraPosition(
                                            target: LatLng(26.2389, 73.0243),
                                            zoom: 14.0,
                                          ),
                                          markers: _markers,
                                          compassEnabled: false,
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
                SizedBox(height: SizeConfig.size150),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String title) {
    return CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600);
  }

  Widget _commonCard({required String icon, required String text}) {
    return Container(
      height: SizeConfig.size130,
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5)),
      child: Stack(
        children: [

          // 1. Background Image
          Positioned.fill( // Use Positioned.fill to ensure it covers the card
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: LocalAssets(
                imagePath: icon,
                height: SizeConfig.size130,
                boxFix: BoxFit.cover, // Ensures image fills without stretching
              ),
            ),
          ),

          // 2. Bottom Gradient Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: SizeConfig.size40, // Reduced height for better balance
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                  gradient: LinearGradient(
                      colors: [
                        AppColors.black.withOpacity(0.0),
                        AppColors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter
                  )),
            ),
          ),

          // 3. Text Label
          Positioned(
            left: 5.0,
            right: 5.0,
            bottom: 5.0,
            child: CustomText(
              text,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

}
