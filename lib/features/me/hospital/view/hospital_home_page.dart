import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/hospital/view/widget/slider_others_details.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_card_widget.dart';
import '../../../../widgets/expandable_text.dart';
import '../controller/hospital_model_controller.dart';
import 'widget/hospital_header_view.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  State<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  int selectedTab = 0;
  final controller = getOrPut(() => HospitalModelController());

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: Get.height * 0.35,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.appBackgroundColor,
              child: HospitalHeaderView(
              ),
            ),
            collapseMode: CollapseMode.parallax,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _quickActions(),
                CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Doctors"),
                        SizedBox(height: 12,),
                        _doctorList(),
                        SizedBox(height: 10,),
                        Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomText("View All",color: AppColors.primaryColor,)
                          ],
                        )
                      ],
                    )),
                SizedBox(height: 10,),
                CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("IPD"),
                        SizedBox(height: 12,),
                        _doctorList(),
                        SizedBox(height: 10,),
                        Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomText("View All",color: AppColors.primaryColor,)
                          ],
                        )
                      ],
                    )),
                SizedBox(height: 10,),
                CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Emergency & Critical Care"),
                        SizedBox(height: 12,),
                        _emergencyList(),


                      ],
                    )),
                SizedBox(height: 10,),
            CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child:Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Other Services"),
                  SizedBox(height: SizeConfig.size20,),
                  OtherServicesSlider(
                    items: [
                      ServiceSliderModel(
                        image: "https://example.com/ambulance.jpg",
                        title: "Ambulance",
                        description:
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                        icon: Icons.local_hospital,
                      ),
                      ServiceSliderModel(
                        image: "https://example.com/emergency.jpg",
                        title: "Emergency",
                        description:
                        "24x7 emergency medical services available.",
                        icon: Icons.emergency,
                      ),
                    ],
                  ),

                ],
              )
            ),
                SizedBox(height: 10,),

            CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sectionTitle("About Us"),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size20,),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            LocalAssets(height: 25,width:25,imagePath: AppIconAssets.hospitalVisionIcon),
                            SizedBox(width: SizeConfig.size10,),
                            CustomText("Vision & Mission",fontSize: 18,fontWeight: FontWeight.w600,),
                          ],
                        ),
                        SizedBox(height: 10,),
                        Container(
                          height: 1,
                          color: AppColors.whiteE5,
                        ),
                        SizedBox(height: 10,),
                        ExpandableText(
                          text: "Worem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis",
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            LocalAssets(height: 25,width:25,imagePath: AppIconAssets.hospitalHistoryIcon),
                            SizedBox(width: SizeConfig.size10,),
                            CustomText("History",fontSize: 18,fontWeight: FontWeight.w600,),
                          ],
                        ),
                        SizedBox(height: 10,),
                        Container(
                          height: 1,
                          color: AppColors.whiteE5,
                        ),
                        SizedBox(height: 10,),
                        ExpandableText(
                          text: "Worem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis",
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
                _sectionTitle("Management"),
                _managementList(),
                _sectionTitle("Gallery"),
                _galleryGrid(),
                _sectionTitle("Testimonials"),
                _testimonialCard(),
                _sectionTitle("Contact Us"),
                _contactCard(),
                const SizedBox(height: 24),
                ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return CustomText(
      title,
     fontSize: 16, fontWeight: FontWeight.bold
    );
  }

  Widget _doctorList() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (_, index) {
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
                 imagePaths: [''],
                 borderRadius: BorderRadius.circular(10),
                 onPhotoIndex: (index) {
                   // productPhotoIndex = index;
                 },
               ),
               Positioned(
                   bottom: 0,
                   child: Container(
                     width:210,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),

                       color: AppColors.black.withOpacity(0.5)
                     ),
                     padding: EdgeInsets.all(10),
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                       CustomText("Dr. Soumya Darshan S...",
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: AppColors.white,),
                      SizedBox(
                        height: 10,
                      ),
                         CustomText("ChilsSopacjilsi",
                           fontSize: 12,
                           fontWeight: FontWeight.w400,
                           color: AppColors.white,),
                         SizedBox(
                           height: 10,
                         ),
                         CustomText("General & Laparoscopic Surgeon MBBS. MS (General Surgery)",
                           fontSize: 12,
                           fontWeight: FontWeight.w400,
                           color: AppColors.white, )
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

  Widget _emergencyList() {
    final items = [
      "Emergency / Casualty",
      "Trauma Care",
      "ICU",
      "CCU",
      "NICU",
      "PICU",
    ];
    return Column(
      children: items.map((e) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.whiteE5
              ),
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("$e",fontWeight: FontWeight.w600,fontSize: 16,),
             SizedBox(height: 10,),
              CustomText("Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet...",
                color: AppColors.chat_input_icon_color,
                fontWeight: FontWeight.w400,fontSize: 12,),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _managementList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 30),
                SizedBox(height: 8),
                Text("Dr. James Gupta"),
                Text("Managing Director",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _galleryGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _testimonialCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            Text("- Dr. Ramesh Gupta"),
          ],
        ),
      ),
    );
  }

  Widget _contactCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.phone),
            title: Text("+91 9876543210"),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text("support@missionhospital.com"),
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text("Near XYZ Road, City"),
          ),
        ],
      ),
    );
  }
}
