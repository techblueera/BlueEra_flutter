import 'dart:async';
import 'dart:developer';
// For Uint8List
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/waiting_for_payment_dialog.dart';
import 'package:flutter/services.dart';  // For rootBundle and ByteData
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/common_methods.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetBlueeraPiolotModel.dart';
import '../../../auth/stream/rider_response_stream.dart';

class DeliveryPilotScreen extends StatefulWidget {
  const DeliveryPilotScreen(
      {super.key, required this.dropLat, required this.dropLong, required this.shopName, required this.startLat, required this.startLng});

  final double dropLat;
  final double startLat;
  final double dropLong;
  final double startLng;
  final String shopName;

  @override
  State<DeliveryPilotScreen> createState() => _DeliveryPilotScreenState();
}

class _DeliveryPilotScreenState extends State<DeliveryPilotScreen> {
  final orderController = Get.find<OrderNowController>();
  MapplsMapController? mapController;
  late Stream<dynamic> _stream;
  StreamSubscription? _subscription;
  List<dynamic> orders = [];
  Future<void> _showMarkerAndZoom() async {
    if (mapController == null) return;
    final ByteData bytes = await rootBundle.load('assets/svg/2_wheeler.svg');
    final Uint8List list = bytes.buffer.asUint8List();
    await mapController!.addImage('customMarker', list);
    await mapController!.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget. dropLat, widget. dropLong),
        iconImage: 'customMarker', // must match the name above
        iconSize: 1.8,
      ),
    );
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(widget. dropLat, widget. dropLong), 14.0),
    );
  }
  bool paymentDialogShow=false;
  void _showPaymentDialog(
      BuildContext context,
      String orderId, {
        required String driverImageUrl,
        required String driverName,
        required String driverPhone,
        required String driverDistanceKm,
      }) {


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WaitingForPaymentDialog(
          orderId: orderId,
          driverPhone: driverPhone,
            driverName: driverName,
          driverImageUrl: driverImageUrl,
          context: context,
          driverDistanceKm: driverDistanceKm,

        );
      },
    );
  }


  Future<void> fetchStream()async{


  _stream = await riderOrderStream(userId);
  _subscription = _stream.listen((event) {
    log('event is --> $event');
    if (event is List) {
      log('status-->JJJaskncxk  ${event.isEmpty}');
      if(event.isEmpty){
        if(paymentDialogShow==true){
          Get.back();
        }
      }else{
        log('status--> ${event.length}');
        for (final item in event) {
          final status = item['status'];
          log('status--> $status');
          if (status == 'payment-pending') {

            log('paymentDialogShow--> $paymentDialogShow');

            // if(paymentDialogShow==false){
              _showPaymentDialog(Get.context!,item['_id'],
                  driverImageUrl: '${item['assignedRider']['profile_image']}',
                  driverName: '${item['assignedRider']['name']}',
                  driverPhone: '${item['assignedRider']['contact_no']}',
                  driverDistanceKm: item['distanceToPickup']
              );
              paymentDialogShow = true;
            // }
            break; // stop after first match
          }else if(status == 'rejected'){
            if(paymentDialogShow==true){
              Get.back();
            }
            commonSnackBar(message: "Your order rejected by rider choose any other available riders please");

          }
        }
      }

    } else if (event is Map) {
      final status = event['status'];

      if (status == 'payment-pending') {
        // _showPaymentDialog(Get.context!,event['_id']);
      }
    } else {
    }
  }, onError: (error) {
    print('❌ Stream error: $error');
  }, onDone: () {
    print('ℹ️ Stream closed');
  });

}

  @override
  void initState() {
    fetchStream();
    super.initState();
  }


  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Delivery Pilot Near to ${widget.shopName}",
      ),
      body: Obx(() {
        if(orderController.getRidersListResponse.value.status==Status.COMPLETE&&orderController.getFaireAmountResponse.value.status==Status.COMPLETE){
          GetBlueeraPiolotModel data=orderController.getBlueeraPiolotModel.value;
          return
            SafeArea(
            child: Column(

            children: [
              Container(
                  height: 240,
                  color: AppColors.white,
                  child: MapplsMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget. dropLat, widget. dropLong),
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
                      childAspectRatio: 0.83,
                    ),
                    itemBuilder: (context, index) {
                      final pilot = data.users?[index];
                      final isSelected = orderController.selectedIndexes.contains(pilot);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              orderController.selectedIndexes.remove(pilot);
                            } else {
                              orderController.selectedIndexes.add(pilot);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppColors.grayText.withOpacity(0.3),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: CachedNetworkImage(
                                        imageUrl:pilot?.user?.profileImage??'', // replace with your image url
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Center(
                                          child: Icon(Icons.person, size: 50),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: CustomText(
                                                pilot?.riderData?.personalInformation?.name,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                             SizedBox(height: SizeConfig.size4),
                                            Row(
                                              children: [
                                                const Icon(CupertinoIcons.location,
                                                    size: 14, color: Colors.grey),
                                                SizedBox(width: SizeConfig.size4),
                                                CustomText(
                                                  pilot?.distance,
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
                                              "${pilot?.totalOrders} Orders",
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
                                      orderController.selectedIndexes.remove(pilot);
                                    } else {
                                      orderController.selectedIndexes.add(pilot);
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
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async{
                        List<String?> userIdList=orderController.selectedIndexes.map((e)=>e?.userId).toList();
                        String? pickupLocation= await orderController.getAddressFromLatLngAsString(lat: widget.startLat,lng: widget.startLng);
                        String? dropLocation= await orderController.getAddressFromLatLngAsString(lat: widget.dropLat,lng: widget.dropLong);
                        Map<String,dynamic> params={
                          ApiKeys.selectedRiders: userIdList,
                          ApiKeys.pickupLocation: {
                            ApiKeys.address: pickupLocation,
                            ApiKeys.latitude: widget.startLat,
                            ApiKeys.longitude: widget.startLng
                          },
                          ApiKeys.dropLocation: {
                            ApiKeys.address: dropLocation,
                            ApiKeys.latitude: widget.dropLat,
                            ApiKeys.longitude: widget.dropLong
                          },
                          ApiKeys.orderId: "${(orderController.openedMessage?.metadata?.foodId!=null&&orderController.openedMessage?.metadata?.foodId!='')?
                          orderController.openedMessage?.metadata?.foodId
                              :(orderController.openedMessage?.metadata?.productId!=null&&orderController.openedMessage?.metadata?.productId!='')?
                          orderController.openedMessage?.metadata?.productId: orderController.openedMessage?.metadata?.serviceId}",
                          ApiKeys.receiverUserId: "${orderController.openedMessage?.seller?.id}"
                        };
                        showAwaitingForRider(context);
                        await orderController.sendOrderRequestToRider(params);

                        // final razorpayService =
                        // RazorpayService();
                        //
                        // razorpayService.openCheckout(
                        //   name:"${orderController.openedMessage?.buyer?.name}",
                        //   subscriptionId: "",
                        //   description: '',
                        //   amount:double.parse(orderController.fare.value.toString()),
                        //   contact: "${orderController.openedMessage?.buyer?.contact}",
                        //   email:
                        //   'admin@bluecs.in',
                        //   onPaymentSuccess:
                        //       (response) async {
                        //     debugPrint(
                        //         "Payment Suzzz: ${response.data}");
                        //
                        //     List<String?> userIdList=orderController.selectedIndexes.map((e)=>e?.userId).toList();
                        //     Map<String,dynamic> params={
                        //       ApiKeys.selectedRiders: userIdList,
                        //       ApiKeys.pickupLocation: {
                        //         ApiKeys.latitude: widget.startLat,
                        //         ApiKeys.longitude: widget.startLng
                        //       },
                        //       ApiKeys.dropLocation: {
                        //         ApiKeys.latitude: widget.lat,
                        //         ApiKeys.longitude: widget.long
                        //       },
                        //       ApiKeys.orderId: "${(orderController.openedMessage?.metadata?.foodId!=null&&orderController.openedMessage?.metadata?.foodId!='')?
                        //       orderController.openedMessage?.metadata?.foodId
                        //           :(orderController.openedMessage?.metadata?.productId!=null&&orderController.openedMessage?.metadata?.productId!='')?
                        //       orderController.openedMessage?.metadata?.productId: orderController.openedMessage?.metadata?.serviceId}",
                        //       ApiKeys.receiverUserId: "${orderController.openedMessage?.seller?.id}"
                        //     };
                        //     await orderController.sendOrderRequestToRider(params);
                        //     commonSnackBar(
                        //         message:
                        //         "Wait Our Pilot Little Bit Busy \nWe Will Notify You Soon..");
                        //     Get.back();
                        //     Get.back();
                        //
                        //   },
                        //   onPaymentError: (response) {
                        //     debugPrint(
                        //         "Payment Failed: ${response.message}");
                        //     commonSnackBar(
                        //         message:
                        //         "Payment Failed ${response.message}");
                        //   },
                        // );
                      },
                      child:  CustomText(
                        "Book Delivery Pilot NOW",
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size18),

            ],
          ));
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }
  void showAwaitingForRider(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ cannot close manually
      barrierColor: Colors.black.withOpacity(0.4), // dim background
      builder: (BuildContext context) {

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: staggeredDotsWaveLoading(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const CustomText(
                  "Our rider will accept soon,\n Dont close this page",
                  textAlign: TextAlign.center,
                  // style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  // ),
                ),
                const SizedBox(height: 12),

              ],
            ),
          ),
        );
      },
    );
  }
}
