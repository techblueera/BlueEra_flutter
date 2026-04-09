import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'audio_type_message_ui.dart';
import 'component_widgets.dart';
import 'group_chat_message_bubble.dart';
import 'group_document_message_view.dart';
import 'group_video_and_image_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupMessageCard extends StatefulWidget {
  const GroupMessageCard({super.key, required this.message,
    this.conversationId,
    this.userId,
    this.profileImage,
    this.name,
    required this.isInitialMessage,
    this.contactNo});
  final Messages message;
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? name;
  final bool isInitialMessage;
  final String? contactNo;

  @override
  State<GroupMessageCard> createState() => _GroupMessageCardState();
}

class _GroupMessageCardState extends State<GroupMessageCard>  with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final chatViewController = Get.find<ChatViewController>();

  final chatThemeController = Get.find<ChatThemeController>();
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.message.message ?? '';
    bool isReceive;
    if (widget.message.myMessage != null) {
      isReceive = !(widget.message.myMessage ?? false);
    } else {
     final currentUserId = userId; // Global variable from shared_preference_utils.dart
      final senderId = widget.message.senderId;
      isReceive = currentUserId != senderId;
    }
    final time = formatChatTime(
        widget.message.createdAt ?? '');
    Widget messageWidget;
    switch (widget.message.messageType) {
      case "location":
        messageWidget = _buildMapMessage(
          widget.message,
          widget.message.message,
          double.parse(
              widget.message.latitude ?? "0"),
          double.parse(
              widget.message.longitude ?? "0"),
          time,
          isReceive,
        );
        break;
      case "contact":
        messageWidget =
            _buildContactMessage(widget.message,
              widget.message.sharedContactName ??
                  '',
              widget.message
                  .sharedContactNumber ??
                  '',
              time,
              isReceive,
            );
        break;
      case "video":
      case "image":
        messageWidget =
            GroupVideoAndImageCardWidget(
              message:widget.message,
              time:time,
              isReceive:isReceive,
              theme:theme,
              userId:widget.userId.toString(),
              conversationId:widget.conversationId
                  .toString(), name: widget.name,
              isInitialMessage: widget.isInitialMessage,);
        break;
      case "audio":
        if(widget.message.url!=null&&(widget.message.url?.isNotEmpty??false)){

          messageWidget =
              AudioMessageWidget(
                message: widget.message,
                audioUrl: widget.message.url
                    ?.first,
                isReceiveMsg: isReceive,
              );
        }else{
          messageWidget=SizedBox();
        }

        break;
      case "date":
        return _buildDateDivider(
            formatChatHistoryTime(text));
      case "document":
        messageWidget = GroupPdfPreviewCard(
          message: widget.message,
          chatThemeController: chatThemeController,
          isMyMessage: isReceive,
          pdfUrl:
          '${(widget.message.url==null)?widget.message.docFileName:widget.message.url?.first.url}',
          fileName:
          '${(widget.message.url==null)?widget.message.docFileName:widget.message.url?.first.name}',
          time: time,
        );
      default:
        messageWidget =
            _buildReceivedMessage(
              widget.message,
              text,
              time,
              isReceive,
            );
        break;
    }

    return Stack(
      children: [
        Align(
          alignment: isReceive
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragOffset + _shakeAnimation.value, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset = (_dragOffset + details.delta.dx).clamp(0, 60); // slide limit
                });
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  chatViewController.setReplyMessage(widget.message);
                }
                if (_dragOffset > 40) {
                  // Trigger reply
                  chatViewController.setReplyMessage(widget.message);

                  // Trigger shake animation
                  _shakeController.forward(from: 0);
                }
                // Reset position after drag
                setState(() => _dragOffset = 0);
              },
              child: Padding(
                padding: const EdgeInsets
                    .symmetric(
                    vertical: 1.4),
                child: messageWidget,
              ),
            ),
          ),
        ),
        (chatThemeController
            .isMessageSelectionActive
            .value &&
            chatThemeController
                .selectedMessageIds
                .contains(
                widget.message.id ?? ""))
            ? Positioned.fill(
            child: InkWell(
              onTap: (){
                chatThemeController.selectMoreMessage(widget.message);
              },
              child: Container(
                margin: EdgeInsets
                    .symmetric(
                    vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular((!isReceive) ? 12 : 0),
                    bottomLeft: Radius.circular((isReceive) ? 0 : 12),
                  ),
                  color: chatThemeController
                      .myMessageBgColor
                      .value
                      ..withValues(alpha: 0.4),
                ),

              ),
            ))
            : SizedBox()
      ],
    );
  }

  Widget _buildReceivedMessage(Messages message, String text, String time,
      bool isReceive) {
    return GroupChatMessageBubble(
      messages: message,
      message: text,
      time: time,
      isReceiveMsg: isReceive,
    );
  }

  Widget _buildDateDivider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ),
      ),
    );
  }


  GoogleMapController? mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    if(_currentPosition!=null && _currentPosition?.latitude != 0.0 && _currentPosition?.longitude != 0.0){
      try {
        final BitmapDescriptor customIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(30, 30)),
          AppImageAssets.markerBlue,
        );

        final Marker customMarker = Marker(
          markerId: const MarkerId("custom_marker_id"),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: customIcon,
        );

        setState(() {
          _markers.add(customMarker);
        });

        await mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0),
        );

      } catch (e) {
        debugPrint("Error loading marker: $e");
      }
    }

  }

  Widget _buildMapMessage(Messages? messages,String? message, double lat, double long, String time,
      bool isReceiveMsg) {
    _currentPosition = LatLng(lat, long);
    Theme.of(context);
    // Marker _currentMarker = Marker(
    //   markerId: const MarkerId('me'),
    //   position: _currentPosition,
    //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    //   infoWindow: const InfoWindow(title: 'You are here'),
    // );

    return GestureDetector(
      onLongPress: (){
        chatThemeController.activateSelection(messages);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if(chatThemeController.isMessageSelectionActive.value){
          chatThemeController.selectMoreMessage(messages);
        }
      },
      child: Row(
        mainAxisAlignment: (!isReceiveMsg)?MainAxisAlignment.end:MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          (!isReceiveMsg) ? SizedBox():Container(
            margin: EdgeInsets.only(right: 6),
            height: 26,
            width: 26,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown",0.1)
            ),
            child: Center(child: CustomText("${widget.message.sender?.name?.split('')[0]}",fontSize: 13.2,color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown"),)),
          ),
          Container(
            height: isReceiveMsg?273:258,
            width:  SizeConfig.screenWidth*0.72,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isReceiveMsg
                    ? chatThemeController.getColorForSender(widget.message.senderId ?? "unknown")
                    : chatThemeController.myMessageBgColor.value),
            padding: EdgeInsets.all(2),
            child: Align(
              alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
              child: ClipRRect(
                // Optional: Rounded corners
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: isReceiveMsg
                          ? chatThemeController.getColorForSender(widget.message.senderId ?? "unknown")
                          : chatThemeController.myMessageBgColor.value),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      (isReceiveMsg)? const SizedBox(height: 1,):SizedBox(),
                      (isReceiveMsg)?Container(
                        margin: EdgeInsets.only(left: 8),
                        child:CustomText(
                          "${messages?.sender?.name}",
                          fontWeight: FontWeight.w400,
                          color: chatThemeController.getDarkColorForSender(widget.message.senderId ?? "unknown"),
                          fontFamily: "Rounded Mplus 1c",
                          fontSize: 13.3,
                        ),
                      ):SizedBox(),
                      (isReceiveMsg)?SizedBox(
                        height: 4,
                      ):SizedBox(),
                      SizedBox(
                        height:isReceiveMsg? 225:218,
                        width:  SizeConfig.screenWidth*0.72,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: (message != null) ? 154 : 218,
                              width:  SizeConfig.screenWidth*0.72,
                              child: GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition ?? LatLng(lat, long),
                                  zoom: 15.0,
                                ),
                                myLocationEnabled: false,
                                compassEnabled: false,
                                rotateGesturesEnabled: true,
                                tiltGesturesEnabled: true,
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                              ),
                            ),

                            // SizedBox(
                            //   height: (message != null) ? 150 : 218,
                            //   width: 254,
                            //   child: GoogleMap(
                            //     initialCameraPosition: CameraPosition(
                            //       target: _currentPosition,
                            //       zoom: 15,
                            //     ),
                            //     markers: {_currentMarker},
                            //     // myLocationEnabled: true,
                            //     zoomControlsEnabled: false,
                            //     myLocationButtonEnabled: false,
                            //     mapType: MapType.terrain,
                            //     onMapCreated: (controller) {
                            //       controller.setMapStyle(
                            //           mapLightCode); // If you're using a style
                            //     },
                            //   ),
                            // ),


                            if (message != null)
                              const SizedBox(
                                height: 8,
                              ),
                            if (message != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: CustomText(
                                  "${message.split('\n')[0]}",
                                  fontWeight: FontWeight.w600,
                                  color:
                                  (isReceiveMsg) ? Colors.black87 : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            if (message != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: CustomText(
                                  "${message.split('\n')[1]}",
                                  fontWeight: FontWeight.w400,
                                  color:
                                  (isReceiveMsg) ? Colors.black87 : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            if (message != null)
                              const SizedBox(
                                height: 10,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0,right: 10,top: 4),
                              child:  timeAndReadInfoWidget(message: messages!,isMyMessage: messages.myMessage??false,time: time,timeColor: (!isReceiveMsg) ? Colors.white : Colors.black54,indicateColor:messages.messageRead==1?Colors.blue:Colors.grey),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMessage(Messages? message, String name, String number,
      String time, bool isReceiveMsg) {
    final theme = Theme.of(context);
    final displayName = name.trim().isEmpty ? AppStrings.unknownLabel.tr : name;
    final displayNumber = number.trim().isEmpty ? AppStrings.noNumber.tr : number;
    final String? profileImage = message?.sharedContactProfileImage;
    final bool hasProfileImage =
        profileImage != null && profileImage.isNotEmpty;

    return GestureDetector(
      onLongPress: () {
        chatThemeController.activateSelection(message);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if (chatThemeController.isMessageSelectionActive.value) {
          chatThemeController.selectMoreMessage(message);
        }
      },
      child: Row(
        mainAxisAlignment:
            (!isReceiveMsg) ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          (!isReceiveMsg)
              ? SizedBox()
              : Container(
                  margin: EdgeInsets.only(right: 6),
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: chatThemeController.getDarkColorForSender(
                        widget.message.senderId ?? "unknown", 0.1),
                  ),
                  child: Center(
                    child: CustomText(
                      "${widget.message.sender?.name?.split('')[0]}",
                      fontSize: 13.2,
                      color: chatThemeController.getDarkColorForSender(
                          widget.message.senderId ?? "unknown"),
                    ),
                  ),
                ),
          Container(
            width: 270,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isReceiveMsg
                  ? chatThemeController.getColorForSender(
                      widget.message.senderId ?? "unknown")
                  : chatThemeController.myMessageBgColor.value,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular((isReceiveMsg) ? 12 : 0),
                bottomLeft: Radius.circular((isReceiveMsg) ? 0 : 12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name in group
                if (isReceiveMsg)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: CustomText(
                      "${message?.sender?.name}",
                      fontWeight: FontWeight.w400,
                      color: chatThemeController.getDarkColorForSender(
                          widget.message.senderId ?? "unknown"),
                      fontFamily: "Rounded Mplus 1c",
                      fontSize: 13.3,
                    ),
                  ),
                // Contact info section
                Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                        radius: 22,
                        backgroundImage:
                            hasProfileImage ? NetworkImage(profileImage) : null,
                        child: hasProfileImage
                            ? null
                            : Icon(
                                Icons.person,
                                size: 24,
                                color: theme.colorScheme.inverseSurface,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              displayName,
                              fontWeight: FontWeight.w600,
                              color: (isReceiveMsg)
                                  ? Colors.black87
                                  : Colors.white,
                              fontSize: 15,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              displayNumber,
                              color: (isReceiveMsg)
                                  ? Colors.black54
                                  : Colors.white70,
                              fontSize: 12.5,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Time row
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      timeAndReadInfoWidget(
                        message: message!,
                        isMyMessage: message.myMessage ?? false,
                        time: time,
                        timeColor:
                            (!isReceiveMsg) ? Colors.white70 : Colors.black45,
                        indicateColor: message.messageRead == 1
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isReceiveMsg
                      ? Colors.grey.shade300
                      : Colors.white.withValues(alpha: 0.3),
                ),
                // Action buttons row
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Message button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (displayNumber != AppStrings.noNumber.tr) {
                              _launchSms(displayNumber);
                            }
                          },
                          child: Center(
                            child: CustomText(
                              AppStrings.messageLabel.tr,
                              color: isReceiveMsg
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                      // Vertical divider
                      Container(
                        width: 0.5,
                        height: 24,
                        color: isReceiveMsg
                            ? Colors.grey.shade300
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      // Call button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (displayNumber != AppStrings.noNumber.tr) {
                              _launchCall(displayNumber);
                            }
                          },
                          child: Center(
                            child: CustomText(
                              AppStrings.callLabel.tr,
                              color: isReceiveMsg
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                      // Vertical divider
                      Container(
                        width: 0.5,
                        height: 24,
                        color: isReceiveMsg
                            ? Colors.grey.shade300
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      // Save button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            saveContactWithEditor(displayName, displayNumber);
                          },
                          child: Center(
                            child: CustomText(
                              AppStrings.saveLabel.tr,
                              color: isReceiveMsg
                                  ? theme.colorScheme.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSms(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String formatChatHistoryTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (today == messageDay) {
        return 'Today';
      } else if (today.subtract(Duration(days: 1)) == messageDay) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d').format(dateTime); // e.g. Jul 17
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> saveContactWithEditor(String name, String phoneNumber) async
  {
    // Request contact permission
    var permissionStatus = await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      final contact = Contact()
        ..name = Name(first: name)
        ..phones = [Phone(phoneNumber)];

      // Opens the native contact editor with prefilled data
      await contact.insert();
    } else {
      // Permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.contactPermissionDenied.tr)),
      );
    }
  }
}
