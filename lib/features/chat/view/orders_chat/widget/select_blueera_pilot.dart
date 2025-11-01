import 'dart:typed_data';          // For Uint8List
import 'package:flutter/services.dart';  // For rootBundle and ByteData
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/get_blueera_piolot_model.dart';

class DeliveryPilotScreen extends StatefulWidget {
  const DeliveryPilotScreen(
      {super.key, required this.lat, required this.long, required this.shopName});

  final double lat;
  final double long;
  final String shopName;

  @override
  State<DeliveryPilotScreen> createState() => _DeliveryPilotScreenState();
}

class _DeliveryPilotScreenState extends State<DeliveryPilotScreen> {
  final orderController = Get.find<OrderNowController>();
  MapplsMapController? mapController;

  Future<void> _showMarkerAndZoom() async {
    if (mapController == null) return;

    // 1️⃣ Load your marker image bytes from assets
    final ByteData bytes = await rootBundle.load('assets/svg/2_wheeler.svg');
    final Uint8List list = bytes.buffer.asUint8List();

    // 2️⃣ Add the image to the map style with a custom name
    await mapController!.addImage('customMarker', list);

    // 3️⃣ Add the marker symbol
    await mapController!.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.lat, widget.long),
        iconImage: 'customMarker', // must match the name above
        iconSize: 1.8,
      ),
    );

    // 4️⃣ Move camera to marker position
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(widget.lat, widget.long), 14.0),
    );
  }


  List<int> selectedIndexes = [];

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Delivery Pilot Near to ${widget.shopName}",
      ),
      body: Obx(() {
        if(orderController.getRidersListResponse.value.status==Status.COMPLETE){
          GetBlueeraPiolotModel data=orderController.getBlueeraPiolotModel.value;
          Future.delayed(Duration.zero,(){
            selectedIndexes = List.generate(data.users?.length ?? 0, (index) => index);

          });
          return Column(
            children: [
              // Map section
              // ClipRRect(
              //   borderRadius: BorderRadius.circular(10),
              //   child: Image.asset(
              //     "assets/map_sample.png", // replace with your map image
              //     height: 200,
              //     width: double.infinity,
              //     fit: BoxFit.cover,
              //   ),
              // ),
              Container(
                  height: 240,
                  color: Colors.white,

                  child: MapplsMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.lat, widget.long),
                      zoom: 14.0,
                    ),
                    myLocationEnabled: true,
                    onMapCreated: (controller) async {
                      mapController = controller;
                    },
                    onStyleLoadedCallback: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _showMarkerAndZoom();
                    },
                  )

              ),
              SizedBox(height: SizeConfig.size20),

              // Grid of pilots
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GridView.builder(
                    itemCount: data.users?.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final pilot = data.users?[index];
                      final isSelected = selectedIndexes.contains(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedIndexes.remove(index);
                            } else {
                              selectedIndexes.add(index);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppColors.grayText.withOpacity(0.3),
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight:Radius.circular(12) ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Center(child: Icon(Icons.person, size: 50)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            CustomText(
                                              pilot?.riderData?.personalInformation?.name,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(CupertinoIcons.location,
                                                    size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                CustomText(
                                                  '0.4Km',
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: SizeConfig.size4),
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            CustomText(
                                              "0 Orders",
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star,
                                                    color: Colors.orange, size: 14),
                                                CustomText(
                                                  " ${pilot?.riderData?.ratings?.average} (${pilot?.riderData?.ratings?.count} reviews)",
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: SizeConfig.size4),

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ Checkbox on top-left
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedIndexes.remove(index);
                                    } else {
                                      selectedIndexes.add(index);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    color: isSelected ? Colors.blue : Colors.white,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),

                            // if (isSelected)
                            //   const Positioned(
                            //     top: 8,
                            //     right: 8,
                            //     child: CircleAvatar(
                            //       radius: 12,
                            //       backgroundColor: Colors.blue,
                            //       child:
                            //       Icon(Icons.check, size: 14, color: Colors.white),
                            //     ),
                            //   ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Book button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Book Delivery Pilot NOW",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }
}
