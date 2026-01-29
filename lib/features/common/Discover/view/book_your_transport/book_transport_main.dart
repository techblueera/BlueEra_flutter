import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
class BookTransportMain extends StatefulWidget {
  const BookTransportMain({super.key});

  @override
  State<BookTransportMain> createState() => _BookTransportMainState();
}

class _BookTransportMainState extends State<BookTransportMain> {

 int selectedHorizontalTab=0;
 int selectedVehicleOptionIndex=0;
 List<TransportCategoryDetailsModel> inCityVehicleList = [
   TransportCategoryDetailsModel(
     name: "Bike",
     svgImage: AppIconAssets.transport_bike,
     charge: 100,
   ),
   TransportCategoryDetailsModel(
     name: "Taxi",
     svgImage: AppIconAssets.transport_taxi,
     charge: 500.0,
   ),
   TransportCategoryDetailsModel(
     name: "Auto",
     svgImage: AppIconAssets.transport_auto,
     charge: 200.0,
   ),
   TransportCategoryDetailsModel(
     name: "Big Auto",
     svgImage: AppIconAssets.transport_big_auto,
     charge: 250.0,
   ),
 ];
 List<TransportCategoryDetailsModel> inOutStationVehicleList = [
   TransportCategoryDetailsModel(
     name: "4 Seater",
     svgImage: AppIconAssets.transport_taxi,
   ),
   TransportCategoryDetailsModel(
     name: "7 Seater",
     svgImage: AppIconAssets.transport_7_seater,
   ),
 ];
 List<TransportCategoryDetailsModel> inParcelVehicleList = [
   TransportCategoryDetailsModel(
     name: "Lorem Ip",
     svgImage: AppIconAssets.transport_load_auto,
   ),
   TransportCategoryDetailsModel(
     name: "Lorem Ip",
     svgImage: AppIconAssets.transport_truck,
   ),
   TransportCategoryDetailsModel(
     name: "Lorem Ip",
     svgImage: AppIconAssets.transport_container,
   ),
 ];
 MapplsMapController? mapController;

 Future<void> _onMapCreated(MapplsMapController controller) async {
   mapController = controller;
   await mapController?.addSymbol(
     SymbolOptions(
       geometry: LatLng(26.7836, 80.9013),
       iconSize: 1.2,
       iconImage: "marker-icon",
     ),
   );
   setState(() {});
 }
 get  optionList => selectedHorizontalTab==0?inCityVehicleList:selectedHorizontalTab==3?inParcelVehicleList:inOutStationVehicleList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.blueLightShade,
              borderRadius: BorderRadius.circular(10),
            ),
            height: 160,
            child: MapplsMap(
              onMapCreated: (controller) => _onMapCreated(controller),
              initialCameraPosition: CameraPosition(
                target: LatLng(26.7836, 80.9013),
                zoom: 14.0,
              ),
              myLocationEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              HorizontalTabSelector(
                  unSelectedBackgroundColor: AppColors.white,
                  tabs: ['In City', "Out Station","Hourly Rental","Parcel"],
                  selectedIndex: selectedHorizontalTab,
                  onTabSelected: (index,d){
                    selectedHorizontalTab=index;
                    setState(() {

                    });
                  }, labelBuilder: (value)=>value),
             SizedBox(
               height: 60,
             ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                    color: AppColors.white
                ),
                padding: EdgeInsets.symmetric(horizontal: 8,vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.size10,),
                    Container(

                      decoration: BoxDecoration(
                        boxShadow: [
                          AppShadows.bottomShadow
                        ],
                          color: AppColors.white

                      ),
                      padding: EdgeInsets.all(10),
                      child:Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                LocalAssets(imagePath: AppIconAssets.transport_from_location,),
                                SizedBox(height: SizeConfig.size4,),
                                LocalAssets(imagePath: AppIconAssets.tranport_location_pointer,),
                                SizedBox(height: SizeConfig.size2,),
                                LocalAssets(
                                  imagePath: AppIconAssets.location_new,
                                  imgColor: AppColors.red00,
                                )
                              ],
                            ),
                          ),

                          /// ✅ FIXED HERE
                          Expanded(
                            child: Column(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  "F8WV+X7R, Ambagan, Gopinathpur, Indus lore.....",
                                  fontSize: 12,
                                ),
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: AppColors.whiteE5,
                                ),
                                CustomText(
                                  "F8WV+X7R, Ambagan, Gopinathpur, Indus lore.....",
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: SizeConfig.size6,),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [AppShadows.bottomShadow],
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            padding: EdgeInsets.all(10),
                            child: LocalAssets(imagePath: AppIconAssets.transport_location_exchange),
                          )
                        ],
                      ),

                    ),
                    SizedBox(height: SizeConfig.size16,),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for(int i=0;i<optionList.length;i++)
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: (){
                                selectedVehicleOptionIndex=i;
                                selectedVehicleOptionIndex=0;
                                setState(() {

                                });
                              },
                              child: Container(
                                height: 82,
                                width: 86,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                       Border.all(color:selectedVehicleOptionIndex==i?
                                  AppColors.primaryColor:AppColors.whiteE5)
                                      ,
                                  boxShadow: AppShadows.lightBottomShadow
                                ),

                                child: Stack(
                                  children: [
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      left: 0,
                                      child: Container(
                                        // height: 0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient:selectedVehicleOptionIndex==i? LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.primaryColor.withOpacity(0.0),
                                              AppColors.primaryColor.withOpacity(0.2),
                                            ],
                                          ):null,
                                        ),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Center(child: LocalAssets(imagePath: optionList[i].svgImage)),
                                            const SizedBox(height: 2),
                                            CustomText((optionList[i].charge!=null)?"₹${optionList[i].charge}":"${optionList[i].name}",textAlign: TextAlign.center,fontSize: 12,fontWeight: FontWeight.w600,),
                                            const SizedBox(height: 6),
                                          ],
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size16,),
                    CustomText("Choose Your Rider",fontSize: 16,fontWeight: FontWeight.w600,),
                    SizedBox(height: SizeConfig.size16,),
                    for(int i=0;i<optionList.length;i++)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.whiteE5),
                      ),
                      child: Row(
                        children: [
                          /// Profile image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              "https://randomuser.me/api/portraits/men/32.jpg",
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// Name + rating + bike
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  "Rakesh Sharma",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.greyE4,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          CustomText(
                                            "4.8",
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.greyE4,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: CustomText(
                                        "RX 100",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// Divider
                          Container(
                            height: 50,
                            width: 1,
                            margin: const EdgeInsets.only(right: 26),
                            color: AppColors.whiteE5,
                          ),

                          /// Distance
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                "Distance",
                                fontSize: 12,
                                color: AppColors.grayText,
                                fontWeight: FontWeight.w600,
                              ),
                               SizedBox(height: SizeConfig.size15),
                              Row(
                                children: [
                                LocalAssets(imagePath: AppIconAssets.location_new),
                                   SizedBox(width:SizeConfig.size2 ),
                                  CustomText(
                                    "1.2 km",
                                    fontSize: 12,
                                    color: AppColors.grayText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    )

                  ],
                ),
              )
            ],
          ),


        ],
      ),
    );
  }
}
class TransportCategoryDetailsModel {
  final String? name;
  final String svgImage;
  final double? charge;

  TransportCategoryDetailsModel({
    required this.name,
    required this.svgImage,
     this.charge,
  });

  factory TransportCategoryDetailsModel.fromJson(Map<String, dynamic> json) {
    return TransportCategoryDetailsModel(
      name: json['name'] ?? '',
      svgImage: json['svgImage'] ?? '',
      charge: json['charge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'svgImage': svgImage,
      'charge': charge,
    };
  }
}

