import 'dart:convert';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/widget/video_and_image_card_widget.dart';
import 'package:BlueEra/features/common/map/model/food_service_model_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/custom_carousel_slider.dart';
import '../../../../widgets/common_box_shadow.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../common/business_service/model/get_service_model.dart';
import '../../../common/business_service/widget/service_card.dart';
import '../../../common/food/model/get_food_details_model.dart';
import '../../../common/food/view/widget/food_product_card.dart';
import '../../../personal/personal_profile/view/inventory/controller/product_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'audio_type_message_ui.dart';
import 'component_widgets.dart';
import 'document_message_card.dart';
import 'message_bubble.dart';

class MessageCard extends StatefulWidget {
  const MessageCard(
      {super.key,
      required this.message,
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
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
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
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
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
      isReceive = !(widget.message.myMessage ?? true);
      print(
          'MessageCard: Using myMessage field - myMessage: ${widget.message.myMessage}, isReceive: $isReceive');
    } else {
      final currentUserId = widget.userId;

      final senderId = widget.message.senderId;
      isReceive = currentUserId != senderId;
      print(
          'MessageCard: Using fallback logic - currentUserId: "$currentUserId", senderId: "$senderId", isReceive: $isReceive');
    }

    final time = formatChatTime(widget.message.createdAt ?? '');

    Widget messageWidget;

    switch (widget.message.messageType) {
      case "location":
        messageWidget = _buildMapMessage(
          widget.message,
          widget.message.message,
          double.parse(widget.message.latitude ?? "0"),
          double.parse(widget.message.longitude ?? "0"),
          time,
          isReceive,
        );
        break;
      case "contact":
        messageWidget = _buildContactMessage(
          widget.message,
          widget.message.sharedContactName ?? '',
          widget.message.sharedContactNumber ?? '',
          time,
          isReceive,
        );
        break;
      case "video":
      case "image":
        messageWidget = VideoAndImageCardWidget(

          message: widget.message,
          time: time,
          isReceive: isReceive,
          theme: theme,
          userId: widget.userId.toString(),
          conversationId: widget.conversationId.toString(),
          name: widget.name,
          isInitialMessage: widget.isInitialMessage,
        );
        break;
      case "audio":
        if (widget.message.url != null &&
            (widget.message.url?.isNotEmpty ?? false)) {
          messageWidget = AudioMessageWidget(
            message: widget.message,
            audioUrl: widget.message.url?.first,
            isReceiveMsg: isReceive,
          );
        } else {
          messageWidget = SizedBox();
        }

        break;
      case "date":
        return _buildDateDivider(formatChatHistoryTime(text));
      case "document":
        messageWidget = PdfPreviewCard(
          message: widget.message,
          chatThemeController: chatThemeController,
          isMyMessage: isReceive,
          pdfUrl:
              '${(widget.message.url == null) ? widget.message.docFileName : widget.message.url?.first.url}',
          fileName:
              '${(widget.message.url == null) ? widget.message.docFileName : widget.message.url?.first.name}',
          time: time,
        );
      case "food":
      List<String> url=[];

      url = widget.message.url?.map((e) => e.url.toString()).toList()??[];
      List<String> message=widget.message.message?.split('.')??[];
      if(message.isNotEmpty){
        messageWidget = FoodCardBusiness(
          isFromChatCard: true,
          serviceData: GetFoodDetailsModel(
              subCategory: message[2],
              id: widget.message.metadata?.foodId,
              userId: widget.userId,
              type: "food",
              title: message.first,
              priceType: "single",
              singlePrice: widget.message.metadata?.price,
              photos:url,
              vegType: message[1],
              nutritionalSummaryPer100g: NutritionalSummaryPer100g(
                  caloriesKcal: message.last
              )
          ),
          isGridView: false,
          isShowChat: false,
          isShowKM: false,
          isShowBusinessInfo: true,
        );
      }else{
        messageWidget=SizedBox();
      }
      case "service":
        List<String> url=[];

        url = widget.message.url?.map((e) => e.url.toString()).toList()??[];
        List<String> message=widget.message.message?.split('.')??[];
        if(message.isNotEmpty){
          messageWidget = ServiceCardBusiness(
            isFromChatCard: true,
            serviceData: GetServiceModel(
              business: BusinessService(
                businessName:message.last ,
                categoryOfBusiness: CategoryOfBusiness(name:message[1])
              ),

                id: widget.message.metadata?.serviceId,
                discounts: [Discounts(amountOff: num.tryParse(widget.message.metadata?.discount ?? '0'))],
                userId: widget.userId,
                type: "service",
                title: message.first,
                priceType: "single",
                photos:url,

            ),
            isGridView: false,
            isShowChat: false,
            isShowKM: false,
            isShowBusinessInfo: true,
          );
        }else{
          messageWidget=SizedBox();
        }
      case "product":
        List<String> url=[];

        url = widget.message.url?.map((e) => e.url.toString()).toList()??[];
        List<String> message=widget.message.message?.split('.')??[];
        if(message.isNotEmpty){
          messageWidget = ProductCard(ProductListing(
              image: url,
              name: message.first,
              id: widget.message.metadata?.productId??'',
            discount:widget.message.metadata?.discount ,
            mrp: message[1],
            price: widget.message.metadata?.price,
            selectedVariants: (message.last.contains("{"))?jsonDecode(message.last):{},
          ),

              width: 172
          );
        }else{
          messageWidget=SizedBox();
        }
      default:
        messageWidget = _buildReceivedMessage(
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
          alignment: isReceive ? Alignment.centerLeft : Alignment.centerRight,
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
                  _dragOffset = (_dragOffset + details.delta.dx)
                      .clamp(0, 60); // slide limit
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
                padding: const EdgeInsets.symmetric(vertical: 1.4),
                child: messageWidget,
              ),
            ),
          ),
        ),

        (chatThemeController.isMessageSelectionActive.value &&
                chatThemeController.selectedId
                    .contains(widget.message.id ?? ""))
            ? Positioned.fill(
                child: InkWell(
                onTap: () {
                  chatThemeController.selectMoreMessage(widget.message);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular((!isReceive) ? 12 : 0),
                      bottomLeft: Radius.circular((isReceive) ? 0 : 12),
                    ),
                    color: chatThemeController.myMessageBgColor.value
                        .withOpacity(0.4),
                  ),
                ),
              ))
            : SizedBox()
      ],
    );
  }
  Widget _buildIconBox(Widget child) {
    return Container(
      height: 25,
      width: 25,
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow]),
      alignment: Alignment.center,
      child: child,
    );
  }
  void showSelectedVariantsDialog(
      BuildContext context, Map<String, dynamic>? selectedVariants) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.only(
                top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        "Selected Variants",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size5),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),

                // Variants list
                if (selectedVariants != null && selectedVariants.isNotEmpty)
                  buildVariantsList(selectedVariants)
                else
                  const Text(
                    "No variants selected",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildVariantsList(Map<String, dynamic> selectedVariants) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectedVariants.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: _buildVariantRow(entry.key, entry.value)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _buildVariantRow(String key, dynamic value) {
    // Handle color variant specially
    if (key == 'color' && value is Map<String, dynamic>) {
      final color = SelectedColor.fromJson(value);

      return Row(
        children: [
          CustomText(
            "$key : ",
            fontSize: SizeConfig.large,
          ),
          CustomText(
            color.name,
            fontSize: SizeConfig.medium,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 6),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greyE5, width: 2.0),
            ),
          ),
        ],
      );
    }

    // Default text-only variant
    return Row(
      children: [
        CustomText(
          "$key : ",
          fontSize: SizeConfig.large,
        ),
        CustomText(
          "$value",
          fontSize: SizeConfig.medium,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  Widget ProductCard(
      ProductListing product, {
        required double width,
      }) {
    return GestureDetector(
      onTap: () {

      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.whiteFE,
          boxShadow:  [AppShadows.cardShadow],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.transparent,
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1.2, // square-ish image (adjust if needed)
              child: Stack(
                children: [
                  CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: double.infinity,
                    imagePaths: product.image,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildIconBox(InkWell(
                        onTap: () => showSelectedVariantsDialog(
                            context, product.selectedVariants),
                        child: Icon(Icons.remove_red_eye_outlined,
                            color: Colors.white, size: 16))),
                  ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    product.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price Row
                  Row(
                    children: [
                      CustomText(
                        '₹${product.price}',
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.small,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        ' ₹${product.mrp}',
                        fontSize: SizeConfig.small11,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.lineThrough,
                      ),
                      CustomText(
                        ' ${product.discount}% off',
                        fontSize: SizeConfig.small11,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Status
                  CustomText(
                    'Active Products',
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small11,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReceivedMessage(
      Messages message, String text, String time, bool isReceive) {

    return MessageBubble(
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

  Widget _buildMapMessage(Messages? messages, String? message, double lat,
      double long, String time, bool isReceiveMsg) {
    MapplsMapController? mapController;
    LatLng _currentPosition = LatLng(lat, long);
    Theme.of(context);
    // Marker _currentMarker = Marker(
    //   markerId: const MarkerId('me'),
    //   position: _currentPosition,
    //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    //   infoWindow: const InfoWindow(title: 'You are here'),
    // );

    return GestureDetector(
      onLongPress: () {
        chatThemeController.activateSelection(messages);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if (chatThemeController.isMessageSelectionActive.value) {
          chatThemeController.selectMoreMessage(messages);
        }
      },
      child: Container(
        height: 260,
        width: 257,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isReceiveMsg
                ? chatThemeController.receiveMessageBgColor.value
                : chatThemeController.myMessageBgColor.value),
        padding: EdgeInsets.all(2),
        child: Align(
          alignment:
              isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
          child: ClipRRect(
            // Optional: Rounded corners
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: isReceiveMsg
                      ? chatThemeController.receiveMessageBgColor.value
                      : chatThemeController.myMessageBgColor.value),
              child: Stack(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 240,
                    width: 252,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: (message != null) ? 160 : 238,
                          width: 254,
                          child: Stack(
                            children: [
                              MapplsMap(
                                onStyleLoadedCallback: () async {
                                  if (_currentPosition.latitude != 0.0 &&
                                      _currentPosition.longitude != 0.0) {
                                    await mapController?.addSymbol(
                                      SymbolOptions(
                                        geometry: _currentPosition,
                                        iconSize: 1.2,
                                        // iconImage: "marker-15"
                                      ),
                                    );
                                    setState(() {});
                                  }
                                },
                                onMapCreated:
                                    (MapplsMapController controller) async {
                                  mapController = controller;
                                },
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition,
                                  zoom: 15.0,
                                ),
                                myLocationEnabled: false,
                                compassEnabled: false,
                                rotateGesturesEnabled: true,
                                tiltGesturesEnabled: true,
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                              ),
                              Positioned(
                                right: SizeConfig.size10,
                                bottom: SizeConfig.size10,
                                child: InkWell(
                                  onTap: () async {
                                    final Uri googleMapUrl = Uri.parse(
                                        "https://www.google.com/maps/search/?api=1&query=${_currentPosition.latitude},${_currentPosition.longitude}");

                                    if (await canLaunchUrl(googleMapUrl)) {
                                      await launchUrl(googleMapUrl,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      throw "Could not open Google Maps";
                                    }
                                  },
                                  child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      height: SizeConfig.size40,
                                      width: SizeConfig.size40,
                                      child: Icon(
                                        Icons.directions,
                                        color: AppColors.white,
                                      )),
                                ),
                              )
                            ],
                          ),

                          // GoogleMap(
                          //   initialCameraPosition: CameraPosition(
                          //     target: _currentPosition,
                          //     zoom: 15,
                          //   ),
                          //   markers: {_currentMarker},
                          //   // myLocationEnabled: true,
                          //   zoomControlsEnabled: false,
                          //   myLocationButtonEnabled: false,
                          //   mapType: MapType.terrain,
                          //   onMapCreated: (controller) {
                          //     controller.setMapStyle(
                          //         mapLightCode); // If you're using a style
                          //   },
                          // ),
                        ),
                        if (message != null)
                          const SizedBox(
                            height: 10,
                          ),
                        if (message != null)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CustomText(
                              "${message.split('\n')[0]}",
                              fontWeight: FontWeight.w600,
                              color: (isReceiveMsg)
                                  ? Colors.black87
                                  : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        if (message != null)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CustomText(
                              "${message.split('\n')[1]}",
                              fontWeight: FontWeight.w400,
                              color: (isReceiveMsg)
                                  ? Colors.black87
                                  : Colors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: timeAndReadInfoWidget(
                          message: messages!,
                          isMyMessage: messages.myMessage ?? false,
                          time: time,
                          timeColor:
                              (!isReceiveMsg) ? Colors.white : Colors.black54,
                          indicateColor: messages.messageRead == 1
                              ? Colors.blue
                              : Colors.grey),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactMessage(Messages? message, String name, String number,
      String time, bool isReceiveMsg) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () {
        chatThemeController.activateSelection(message);
      },
      onTap: () {
        FocusScope.of(context).unfocus();
        if (chatThemeController.isMessageSelectionActive.value) {
          chatThemeController.selectMoreMessage(message);
        } else {}
      },
      child: Align(
        alignment:
            (isReceiveMsg) ? Alignment.centerLeft : Alignment.centerRight,
        child: IntrinsicWidth(
          child: Container(
            width: 256,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isReceiveMsg
                  ? Colors.white
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.8),
                      radius: 18,
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.inverseSurface,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 180,
                          child: CustomText(
                            name,
                            fontWeight: FontWeight.w500,
                            color:
                                (isReceiveMsg) ? Colors.black87 : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: CustomText(
                            number,
                            color:
                                (!isReceiveMsg) ? Colors.white : Colors.black54,
                            fontSize: 12,
                          ),
                        )
                      ],
                    )
                  ],
                ),
                (isReceiveMsg)
                    ? const SizedBox(
                        height: 10,
                      )
                    : SizedBox(),
                (isReceiveMsg)
                    ? InkWell(
                        onTap: () async {
                          saveContactWithEditor(name, number);
                        },
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: (isReceiveMsg)
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.secondary
                                      .withOpacity(0.6)),
                          child: Center(
                            child: CustomText(
                              "Save",
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: timeAndReadInfoWidget(
                          message: message!,
                          isMyMessage: message.myMessage ?? false,
                          time: time,
                          timeColor:
                              (!isReceiveMsg) ? Colors.white : Colors.black54,
                          indicateColor: message.messageRead == 1
                              ? Colors.blue
                              : Colors.grey),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> saveContactWithEditor(String name, String phoneNumber) async {
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
        SnackBar(content: Text('Contact permission denied')),
      );
    }
  }
}
