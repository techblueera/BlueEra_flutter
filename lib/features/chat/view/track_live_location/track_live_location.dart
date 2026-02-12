import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/getx_utils.dart';
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
  GoogleMapController? mapController;
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
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
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


  Marker? _userMarker;
  Marker? _myProfileMarker;
  final Set<Marker> _markers = {};

  void _addMyOwnProfile(LatLng latLng) {
    _myProfileMarker = Marker(
      markerId: MarkerId('my_profile_marker'),
      position: latLng,
    );
    _markers.add(_myProfileMarker!);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "View Live location",
      ),
      body:  Obx(() {
            Future.delayed(Duration.zero,(){
              if(_userMarker!=null){
                setState(() {
                  _userMarker = _userMarker!.copyWith(
                    positionParam: LatLng(chatThemeController.senderLiveLocation.value.latitude??0, chatThemeController.senderLiveLocation.value.longitude??0),
                  );
                  _markers.add(_userMarker!);
                });
              } else {
                setState(() {
                  _userMarker = Marker(
                    markerId: MarkerId('user_marker'),
                    position: LatLng(chatThemeController.senderLiveLocation.value.latitude??0, chatThemeController.senderLiveLocation.value.longitude??0),
                  );
                  _markers.add(_userMarker!);
                });
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
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
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
                myLocationEnabled: true,
                markers: _markers,
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
