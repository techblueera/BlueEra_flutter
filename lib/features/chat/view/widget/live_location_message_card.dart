import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mappls_gl/mappls_gl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../track_live_location/track_live_location.dart';
import 'component_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/tooltip_generator.dart';
import 'package:flutter/services.dart';
import '../../../common/auth/controller/auth_controller.dart';

class LiveLocationMessageCard extends StatefulWidget {
  final Messages? messages;
  final String? message;
  final double lat;
  final double long;
  final String time;
  final bool isReceiveMsg;
  final ChatThemeController chatThemeController;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveLocationMessageCard({
    super.key,
    required this.messages,
    required this.message,
    required this.lat,
    required this.long,
    required this.time,
    required this.isReceiveMsg,
    required this.chatThemeController,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<LiveLocationMessageCard> createState() =>
      _LiveLocationMessageCardState();
}
class _LiveLocationMessageCardState extends State<LiveLocationMessageCard> {
  MapplsMapController? mapController;
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition =(widget.messages?.myMessage==true)?
    LatLng(widget.lat, widget.long)
        : LatLng(double.parse("${widget.messages?.latitude??"0"}"), double.parse("${widget.messages?.longitude??"0"}"));
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: Container(
        height: 256,
        width: 257,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: widget.isReceiveMsg
              ? widget.chatThemeController.receiveMessageBgColor.value
              : widget.chatThemeController.myMessageBgColor.value,
        ),
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: widget.isReceiveMsg
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMapView(context),
                      if (widget.message != null) const SizedBox(height: 10),
                      if (widget.message != null) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMessageText(),
                          timeAndReadInfoWidget(
                            message: widget.messages!,
                            isMyMessage: widget.messages?.myMessage ?? false,
                            time: widget.time,
                            timeColor: AppColors.black,
                            indicateColor:
                            widget.messages?.messageRead == 1
                                ? Colors.blue
                                : Colors.grey,
                          )
                        ],
                      ),
                      if (widget.message != null) const SizedBox(height: 10),
                      // if (widget.messages?.myMessage == true)
                      //   InkWell(
                      //     onTap: (){
                      //
                      //     },
                      //     child: Container(
                      //       decoration: BoxDecoration(
                      //           borderRadius: BorderRadius.circular(10),
                      //           color: AppColors.red.shade50
                      //       ),
                      //       padding: EdgeInsets.symmetric(vertical: 12),
                      //       margin: EdgeInsets.symmetric(horizontal: 6),
                      //       child: Center(
                      //         child: CustomText("Stop Live Sharing",fontWeight: FontWeight.w600,color: Colors.red,),
                      //       ),
                      //     ),
                      //   )
                      // else
                      InkWell(
                        onTap: (){
                           Get.to(()=>TrackLiveLocationPage(messages: widget.messages,));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          child: Center(
                            child: CustomText("View Live Location",fontWeight: FontWeight.w600,),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
        final Uint8List profileBytes =
        await ProfileLocationMarkerGenerator.createMarker(
          imageUrl:(widget.messages?.myMessage==true)?
          Get.find<AuthController>().imgPath.value:
          widget.messages?.sender?.profileImage ?? "",
          imageSize: 130,
        );
        await mapController?.addImage(
          "profile-circle-icon",
          profileBytes,
        );

        await mapController?.addSymbol(
          SymbolOptions(
            geometry: _currentPosition,
            iconImage: "profile-circle-icon",
            iconSize: 1.0,
          ),
        );

    } catch (e) {
      debugPrint("Marker error: $e");
    }
  }
  Widget _buildMapView(BuildContext context) {
    return SizedBox(
      height: widget.message != null ? 160 : 238,
      width: 254,
      child: MapplsMap(onMapClick: (lat,long) {
        Get.to(()=>TrackLiveLocationPage(messages: widget.messages,));
      },
        onMapCreated: (controller) {
          mapController = controller;
        },
        onStyleLoadedCallback: () async {
          _onStyleLoadedCallback();
        },
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
        myLocationEnabled: false,
        compassEnabled: false,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        scrollGesturesEnabled: true,
      ),
    );
  }
  String calculateExpiredAtTime({
    required String createdAtIso,
    required String durationLabel,
  }) {
    // parse created time
    final createdAt = DateTime.parse(createdAtIso).toLocal();

    // convert string to Duration
    Duration duration;
    if (durationLabel.endsWith("min")) {
      final mins = int.parse(durationLabel.replaceAll("min", ""));
      duration = Duration(minutes: mins);
    } else if (durationLabel.endsWith("h")) {
      final hrs = int.parse(durationLabel.replaceAll("h", ""));
      duration = Duration(hours: hrs);
    } else {
      duration = Duration.zero;
    }

    // calculate expiry
    final expiredAt = createdAt.add(duration);

    // format like 1:15 PM
    final hour = expiredAt.hour % 12 == 0 ? 12 : expiredAt.hour % 12;
    final minute = expiredAt.minute.toString().padLeft(2, '0');
    final period = expiredAt.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  Widget _buildMessageText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share_location_rounded,size: 16,color: AppColors.black,),
              SizedBox(width: 6,),
              CustomText(
               "Live Until ${calculateExpiredAtTime(createdAtIso: widget.messages?.createdAt??'',durationLabel: widget.message??'')}",
                maxLines: 1,
                fontWeight: FontWeight.w500,
                color:
                AppColors.black,
                fontSize: 14,
              ),
            ],
          ),

        ],
      ),
    );
  }

}
