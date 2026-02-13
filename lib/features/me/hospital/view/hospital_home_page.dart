import 'dart:io';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_gallery_photo_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/slider_others_details.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../../../widgets/expandable_text.dart';
import '../controller/hospital_model_controller.dart';
import '../model/hospital_home_page_details_model.dart';
import 'widget/hospital_header_view.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  State<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  int selectedTab = 0;
  final controller = getOrPut(() => HospitalModelController());
  late GoogleMapController mapController;
  Set<Marker> _markers = {};

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)),
        AppImageAssets.markerBlue,
      );

      final Marker customMarker = Marker(
        markerId: const MarkerId("custom_marker_id"),
        position: LatLng(26.7836, 80.9013),
        icon: customIcon,
      );

      setState(() {
        _markers.add(customMarker);
      });

      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(26.7836, 80.9013), 15.0),
      );

    } catch (e) {
      debugPrint("Error loading marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if(controller.getHospitalHomePageResponse.value.status==Status.COMPLETE){
        HospitalHomePageDetailsModel details=controller.hospitalHomePageDetailsModel.value;


        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: Get.height * 0.36,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.appBackgroundColor,
                  child: HospitalHeaderView(details: details.hospitalInfo,
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
                        // _quickActions(),
                        CommonCardWidget(
                            padding: 10,
                            cardMargin: 0,
                            child: Column(crossAxisAlignment: CrossAxisAlignment
                                .start,
                              children: [
                                _sectionTitle("Doctors"),
                                SizedBox(height: 12,),
                                _doctorList(details.doctors??[]),
                                SizedBox(height: 10,),
                                Row(mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: (){
                                        controller.onChangeTab(1);
                                      },
                                      child: CustomText(
                                        "View All", color: AppColors.primaryColor,),
                                    )
                                  ],
                                )
                              ],
                            )),
                        SizedBox(height: 10,),
                        CommonCardWidget(
                            padding: 10,
                            cardMargin: 0,
                            child: Column(crossAxisAlignment: CrossAxisAlignment
                                .start,
                              children: [
                                _sectionTitle("IPD"),
                                SizedBox(height: 12,),
                                _doctorIPDList(details.ipd??[]),
                                SizedBox(height: 10,),
                                Row(mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: (){
                                        controller.onChangeTab(1);
                                      },
                                      child: CustomText(
                                        "View All", color: AppColors.primaryColor,),
                                    )
                                  ],
                                )
                              ],
                            )),
                        SizedBox(height: 10,),
                        CommonCardWidget(
                            padding: 10,
                            cardMargin: 0,
                            child: Column(crossAxisAlignment: CrossAxisAlignment
                                .start,
                              children: [
                                _sectionTitle("Emergency & Critical Care"),
                                SizedBox(height: 12,),
                                _emergencyList(details.emergency??[]),
                                SizedBox(height: 10,),
                                Row(mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: (){
                                        controller.onChangeTab(1);
                                      },
                                      child: CustomText(
                                        "View All", color: AppColors.primaryColor,),
                                    )
                                  ],
                                )
                              ],
                            )),
                        SizedBox(height: 10,),
                        CommonCardWidget(
                            padding: 10,
                            cardMargin: 0,
                            child: Column(crossAxisAlignment: CrossAxisAlignment
                                .start,
                              children: [
                                _sectionTitle("Other Services"),
                                SizedBox(height: SizeConfig.size20,),
                                if(details.otherServices?.isEmpty??false)
                                  noDetailsWidget(title: 'No Other Service Updated Yet', btnText: 'Add More'),
                                if(details.otherServices?.isNotEmpty??false)
                                OtherServicesSlider(
                                  items: [
                                    ...details.otherServices?.map((e){
                                    return ServiceSliderModel(
                                    image: "",
                                    title: "${e.name}",
                        description:
                        "${e.description}",
                        icon: Icons.local_hospital,
                        );
                                    }).toList()??[]
                                  ],
                                ),

                              ],
                            )
                        ),
                        SizedBox(height: 10,),

                        CommonCardWidget(
                            padding: 10,
                            cardMargin: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _sectionTitle("About Us"),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size20,),
                                if(details.aboutUs?.visionMission==""&&details.aboutUs?.history=="")
                                noDetailsWidget(title: 'No About Us Details', btnText: 'Add More'),
                                if(details.aboutUs?.visionMission!="")
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.45),
                                        blurRadius: 12,
                                        spreadRadius: -6,
                                      ),
                                    ],
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          LocalAssets(height: 25,
                                              width: 25,
                                              imagePath: AppIconAssets
                                                  .hospitalVisionIcon),
                                          SizedBox(width: SizeConfig.size10,),
                                          CustomText(
                                            "Vision & Mission", fontSize: 18,
                                            fontWeight: FontWeight.w600,),
                                        ],
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        height: 1,
                                        color: AppColors.whiteE5,
                                      ),
                                      SizedBox(height: 10,),
                                      ExpandableText(
                                        text: "${details.aboutUs?.visionMission}",
                                        trimLines: 6,
                                        isReadMoreNewLine: false,
                                        expandMode: ExpandMode.dialog,
                                        style: TextStyle(
                                          color: AppColors.secondaryTextColor,
                                          fontSize: SizeConfig.large,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppConstants.OpenSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: SizeConfig.size10,),
                                if(details.aboutUs?.history!="")
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.45),
                                        blurRadius: 12,
                                        spreadRadius: -6,
                                      ),
                                    ],
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          LocalAssets(height: 25,
                                              width: 25,
                                              imagePath: AppIconAssets
                                                  .hospitalHistoryIcon),
                                          SizedBox(width: SizeConfig.size10,),
                                          CustomText("History", fontSize: 18,
                                            fontWeight: FontWeight.w600,),
                                        ],
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        height: 1,
                                        color: AppColors.whiteE5,
                                      ),
                                      SizedBox(height: 10,),
                                      ExpandableText(
                                        text: "${details.aboutUs?.history}",
                                        trimLines: 6,
                                        isReadMoreNewLine: false,
                                        expandMode: ExpandMode.dialog,
                                        style: TextStyle(
                                          color: AppColors.secondaryTextColor,
                                          fontSize: SizeConfig.large,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: AppConstants.OpenSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                        ),
                        SizedBox(height: 10,),
                        CommonCardWidget(
                            padding: 0,
                            cardMargin: 0,
                            child: Column(
                              children: [
                                HospitalGalleryPhotoWidget(photos: details.gallery??[],),
                              ],
                            )),
                        SizedBox(height: 10,),
                        // _contactCard(),
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
                                      // boxShadow: [
                                      //   AppShadows.bottomShadow
                                      // ]
                                  ),
                                  child: Column(mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 4),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black12, blurRadius: 10)
                                            ],
                                            image:
                                            (controller.pickedHospitalLogo.value==null)?
                                            (details.hospitalInfo?.logo!=null&&details.hospitalInfo?.logo!='')?DecorationImage(
                                                image:
                                                NetworkImage(details.hospitalInfo?.logo??''),
                                                fit: BoxFit.cover
                                            ):null:
                                            DecorationImage(
                                                image:
                                                FileImage(controller.pickedHospitalLogo.value ?? File("")),
                                                fit: BoxFit.cover
                                            )
                                        ),
                                      ),
                                      SizedBox(height: 6,),
                                      CustomText("${details.contactUs?.hospitalName}",fontSize: 16,fontWeight: FontWeight.w600,),
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
                                            "${details.contactUs?.website}",
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
                                            "${details.contactUs?.email}",
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
                                            "${details.contactUs?.emergencyPhone}",
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
                                            imagePath: AppIconAssets.location_new
                                            , height: 18, width: 18,),
                                          SizedBox(
                                            width: SizeConfig.size6,
                                          ),
                                          Expanded(child:
                                          CustomText(
                                            "${details.contactUs?.address}",
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
                                // ClipRRect(
                                //     borderRadius: BorderRadius.circular(10),
                                //     child: SizedBox(
                                //       width: double.infinity,
                                //       height: SizeConfig.size160,
                                //       child: Stack(
                                //         children: [
                                //           GoogleMap(
                                //             onMapCreated: _onMapCreated,
                                //             initialCameraPosition: CameraPosition(
                                //               target:LatLng(26.8311, 80.9244),
                                //               zoom: 14.0,
                                //             ),
                                //             markers: _markers,
                                //             myLocationEnabled: false,
                                //             compassEnabled: false,
                                //             rotateGesturesEnabled: true,
                                //             tiltGesturesEnabled: true,
                                //             zoomGesturesEnabled: true,
                                //             scrollGesturesEnabled: true,
                                //           ),
                                //         ],
                                //       ),
                                //     )
                                // ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  // CommonCardWidget(
                  //     bgColor: AppColors.blueGrayShade,
                  //     padding: 10,
                  //     cardMargin: 0,
                  //     borderRadius: 0,
                  //     child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         SizedBox(height: 18,),
                  //         Row(mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             CustomText("Testimonials", fontSize: 20,
                  //               fontWeight: FontWeight.w700,),
                  //           ],
                  //         ),
                  //         SizedBox(height: 18,),
                  //         _testimonialCard(),
                  //       ],
                  //     )),

                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        );
      }else if(controller.getHospitalHomePageResponse.value.status==Status.ERROR){
        return Center(
          child:CustomText("${controller.getHospitalHomePageResponse.value.message}"),
        );
      }else{
        return Center(
          child:CircularProgressIndicator() ,
        );
      }

    });
  }

  Widget _sectionTitle(String title) {
    return CustomText(
        title,
        fontSize: 16, fontWeight: FontWeight.bold
    );
  }

  Widget _doctorList(List<DoctorModel> doctors) {
    return SizedBox(
      height: 260,
      child: (doctors.isEmpty)?
      noDetailsWidget(title: 'No Doctors Details Updated Yet', btnText: 'Add More Doctors')
          :ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        itemBuilder: (_, index) {
          DoctorModel doctor=doctors[index];
          return Container(
            width: 210,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10)
            ),
            child: Stack(
              children: [
                CustomImageSlideshow(
                  isLoading: false,
                  width: double.infinity,
                  height: SizeConfig.size260,
                  imagePaths: [doctor.photo??''],
                  borderRadius: BorderRadius.circular(10),
                  onPhotoIndex: (index) {

                  },
                ),
                Positioned(
                    bottom: 0,
                    child: Container(
                      width: 210,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10)),

                          color: AppColors.black.withOpacity(0.5)
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText("${doctor.name}",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,),
                          SizedBox(
                            height: 6,
                          ),
                          CustomText("${doctor.specialization}",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,),
                          SizedBox(
                            height: 6,
                          ),
                          CustomText(
                            "${doctor.departmentName}",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,)
                        ],
                      ),
                    ))
              ],
            ),
            // child: ,
          );
        },
      ),
    );
  }

 Widget _doctorIPDList(List<IpdModel> ipdWard) {
    return SizedBox(
      height: 260,
      child: (ipdWard.isEmpty)?
      noDetailsWidget(title: 'No IPD Details Updated Yet', btnText: 'Add More Details')
      :ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ipdWard.length,
        itemBuilder: (_, index) {
          IpdModel ipd=ipdWard[index];
          return InkWell(
            onTap: (){
              Get.toNamed(
                  RouteHelper.getHospitalWardViewCategory(),
                  arguments: {
                    ApiKeys.category_id:ipd.id,
                    ApiKeys.title:ipd.name
                  }
              );
            },
            child: Container(
              width: 210,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Stack(
                children: [
                  CustomImageSlideshow(
                    isLocal: true,
                    isLoading: false,
                    width: double.infinity,
                    height: SizeConfig.size260,
                    imagePaths: [AppImageAssets.hospitalIpd_ward],
                    borderRadius: BorderRadius.circular(10),
                    onPhotoIndex: (index) {
                      // productPhotoIndex = index;
                    },
                  ),
                  Positioned(
                      bottom: 0,
                      child: Container(
                        width: 210,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10)),

                            color: AppColors.black.withOpacity(0.5)
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("${ipd.name}",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,),
                            SizedBox(
                              height: 6,
                            ),
                            CustomText("Available Beds: ${ipd.availableBeds}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white,),
                            SizedBox(
                              height: 6,
                            ),
                            CustomText("Total Beds: ${ipd.totalBeds}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white,),
                            SizedBox(
                              height: 6,
                            ),
                            CustomText(
                              "${ipd.type}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white,)
                          ],
                        ),
                      ))
                ],
              ),
              // child: ,
            ),
          );
        },
      ),
    );
  }

  Widget _emergencyList(List<EmergencyModel> emergency) {

    return Column(
      children: [
        if(emergency.isEmpty)
          noDetailsWidget(title: 'No Emergency Details Updated Yet', btnText: 'Add More'),
        ...emergency.map((emergency) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.whiteE5
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText("${emergency.name}", fontWeight: FontWeight.w600, fontSize: 16,),
                SizedBox(height: 6,),
                CustomText(
                  "${emergency.description}",
                  color: AppColors.chat_input_icon_color,
                  fontWeight: FontWeight.w400, fontSize: 14,),
              ],
            ),
          );
        }).toList(),

      ],
    );
  }
  Widget noDetailsWidget(
  {
    required String title,
    required String btnText,
}
      ){
    return  Container(
      width: double.infinity,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.whiteE5
          )
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText("${title}"),
          SizedBox(height: 20,),
          CustomBtn(
              isValidate: true,
              width: 80,
              height: 28,
              onTap: (){
                controller.onChangeTab(1);
              }, title: "${btnText}")
        ],
      ),
      // child: ,
    );
  }


//dont remove this code by Prabha
  // Widget _testimonialCard() {
  //   return Card(
  //     margin: const EdgeInsets.all(12),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         children: const [
  //           Text(
  //             "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  //             style: TextStyle(fontStyle: FontStyle.italic),
  //           ),
  //           SizedBox(height: 8),
  //           Text("- Dr. Ramesh Gupta"),
  //         ],
  //       ),
  //     ),
  //   );
  // }


}
