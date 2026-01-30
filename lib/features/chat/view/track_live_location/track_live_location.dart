import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:BlueEra/features/common/Discover/widget/tooltip_generator.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../common/auth/controller/auth_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/socket/live_location_track_socket.dart';

class TrackLiveLocationPage extends StatefulWidget {
  const TrackLiveLocationPage({super.key, required this.messages});

  final Messages? messages;

  @override
  State<TrackLiveLocationPage> createState() => _TrackLiveLocationPageState();
}

class _TrackLiveLocationPageState extends State<TrackLiveLocationPage> {
  MapplsMapController? mapController;
  final chatThemeController = getOrPut(() => ChatThemeController());
  final chatviewController = getOrPut(() => ChatViewController());
  LatLng? currentLatLng;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    super.dispose();
    LiveTrackingSocketService().disconnectSocket();
  }

  Future<void> _determinePosition() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        // chatThemeController.senderLiveLocation.value =
        //     SharedPersonsLiveLocationModel(
        //       latitude: pos.latitude,
        //       longitude: pos.longitude,
        //       availabilityStatus: "OPEN",
        //     );
        currentLatLng = LatLng(pos.latitude, pos.longitude);
        _addMyOwnProfile(currentLatLng!);
      });

      chatThemeController.viewLiverLocationReceivedUserId.value =
          widget.messages?.senderId ?? '';
      chatThemeController.connectSocket(
         widget.messages?.senderId ?? '');
    }
  }


  Symbol? _userSymbol;
  Symbol? _myProfileSymbol;
  bool _isImageAdded = false;
  bool _isMyImageAdded = false;

  Future<void> _onStyleLoadedCallback() async {
    try {
      if (!_isImageAdded) {
        final Uint8List profileBytes =
        await ProfileLocationMarkerGenerator.createMarker(
          imageUrl: widget.messages?.sender?.profileImage ?? "",
          imageSize: 160,
        );
        await mapController?.addImage(
          "profile-circle-icon",
          profileBytes,
        );

        _isImageAdded = true;
      }

      if (_userSymbol == null &&
          chatThemeController.senderLiveLocation.value.latitude != null) {
        _userSymbol = await mapController?.addSymbol(
          SymbolOptions(
            geometry: LatLng(
              chatThemeController.senderLiveLocation.value.latitude ?? 0,
              chatThemeController.senderLiveLocation.value.longitude ?? 0,
            ),
            iconImage: "profile-circle-icon",
            iconSize: 1.0,
          ),
        );
      }
    } catch (e) {
      debugPrint("Marker error: $e");
    }
  }

  Future<void> _addMyOwnProfile(LatLng latLng) async {
    try {
      if (!_isMyImageAdded) {
        final Uint8List profileBytes =
        await ProfileLocationMarkerGenerator.createMarker(
          imageUrl: Get.find<AuthController>().imgPath.value,
          imageSize: 160,
        );
        await mapController?.addImage(
          "my_profile-circle-icon",
          profileBytes,
        );
        _isMyImageAdded = true;
      }
      _myProfileSymbol = await mapController?.addSymbol(
          SymbolOptions(
            geometry: latLng,
            iconImage: "my_profile-circle-icon",
            iconSize: 1.0,
          ),
        );
    } catch (e) {
      debugPrint("Marker error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "View Live location",
      ),
      body:  Obx(() {
            Future.delayed(Duration.zero,(){
              if(_userSymbol!=null){
                mapController?.updateSymbol(
                  _userSymbol!,
                  SymbolOptions(
                    geometry: LatLng(chatThemeController.senderLiveLocation.value.latitude??0, chatThemeController.senderLiveLocation.value.longitude??0),
                  ),
                );
              }

            });
            if(chatThemeController.senderLiveLocation.value.longitude==null){

            }
        return ((widget.messages?.myMessage==true)?
        (currentLatLng!=null):
        (chatThemeController.senderLiveLocation.value.longitude!=null)
        )?
        Column(
          children: [
            Expanded(
              child: MapplsMap(
                myLocationTrackingMode: MyLocationTrackingMode.tracking,
                onMapCreated: (MapplsMapController controller) async {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target:(widget.messages?.myMessage==true)?
                  currentLatLng!: LatLng(
                      chatThemeController.senderLiveLocation.value.latitude ??
                          0,
                      chatThemeController.senderLiveLocation.value.longitude ??
                          0),
                  zoom: 15.0,
                ),
                myLocationEnabled: false,
                onUserLocationUpdated: (userLocation) {
                  final LatLng newPos = LatLng(
                    userLocation.position.latitude,
                    userLocation.position.longitude,
                  );
                    mapController?.updateSymbol(
                      _myProfileSymbol!,
                      SymbolOptions(
                        geometry: newPos,
                      ),
                    );
                    setState(() {

                    });
                },
                onStyleLoadedCallback: () {
                  if(!(widget.messages?.myMessage==true)){
                    _onStyleLoadedCallback();
                  }

                },
                zoomGesturesEnabled: true,
                compassEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
                // onSymbolTapped: _onSymbolTapped,
              ),
            ),
            const SizedBox(height: 6,),

          ],
        ):Center(
          child: CircularProgressIndicator(),
        );
      }),
    );
  }
}
