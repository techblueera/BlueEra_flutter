import 'dart:convert';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/view/widget/video_and_image_card_widget.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/features/common/map/model/food_service_model_response.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/common_box_shadow.dart';
import '../../../common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/order_controllar.dart';
import '../business_chat/widgets/rider_association_msg_card.dart';
import '../business_chat/widgets/rider_details_msg_card.dart';
import '../business_chat/widgets/rider_live_location_msg_card.dart';
import '../business_chat/widgets/rider_request_msg_card.dart';
import '../business_chat/widgets/self_pickup_msg_card.dart';
import '../business_chat/widgets/food_self_pickup_msg_card.dart';
import '../business_chat/widgets/product_self_pickup_msg_card.dart';
import '../media_view_page/medias_slider_page.dart';
import '../symbol_view/symbol_view_images.dart';
import '../orders_chat/widget/order_common_widgets.dart';
import 'audio_type_message_ui.dart';
import 'component_widgets.dart';
import 'document_message_card.dart';
import 'live_location_message_card.dart';

import 'call_message_card.dart';
import 'message_bubble.dart';
import 'message_context_menu.dart';

class MessageCard extends StatefulWidget {
  const MessageCard(
      {super.key,
      required this.message,
      this.conversationId,
      this.isFromOrderTab,
      this.userId,
      this.profileImage,
      this.name,
      required this.isInitialMessage,
      this.contactNo, this.isFromAiMessage,
      this.conversationName, this.conversationProfileImage,
      this.conversationUserId});

  final Messages message;
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? name;
  final bool isInitialMessage;
  final bool? isFromOrderTab;
  final bool? isFromAiMessage;
  final String? contactNo;
  final String? conversationName;
  final String? conversationProfileImage;
  final String? conversationUserId;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  AnimationController? _shakeController;
  final _messageKey = GlobalKey();

  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();

  /// Lazily create the shake animation only when needed (swipe-to-reply).
  AnimationController get shakeController {
    _shakeController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    return _shakeController!;
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final text = widget.message.message ?? '';

    bool isReceive;

    if (widget.message.myMessage != null) {
      isReceive = !(widget.message.myMessage ?? true);
   } else {
      final currentUserId = widget.userId;
      final senderId = widget.message.senderId;
      isReceive = currentUserId != senderId;
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
      case "live_location":
        messageWidget =
            LiveLocationMessageCard(
              messages:widget.message,
              message:"${widget.message.live_location_validity}",
              lat:  double.parse(widget.message.latitude ?? "0"),
              long:  double.parse(widget.message.longitude ?? "0"),
              time: time,
              isReceiveMsg: isReceive,
              chatThemeController: chatThemeController,
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

        return (widget.message.visible_to!=null&&widget.message.visible_to!='')?
        (widget.message.visible_to==userId)?
        _buildDateDivider(formatChatHistoryTime(text)):
        SizedBox():
        _buildDateDivider(formatChatHistoryTime(text));
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
        messageWidget = FoodCardMessageCardBusiness(time: time,
          isFromOrderTab: widget.isFromOrderTab??false,
          photos: url,
          conversationId: widget.conversationId??'',
          userId: widget.userId??'',
          message: widget.message,
          isFromChatCard: true,
          serviceData: GetFoodDetailsModel(
              subCategory: widget.message.metadata?.subCategory,
              id: widget.message.metadata?.foodId,
              userId: widget.userId,
              type: AppConstants.food,
              title: widget.message.metadata?.title,
              priceType: "single",
              singlePrice: widget.message.metadata?.price,
              photos:url,
              vegType:widget.message.metadata?.vegType,
              nutritionalSummaryPer100g: NutritionalSummaryPer100g(
                  caloriesKcal: widget.message.metadata?.calories
              )
          ),
          isGridView: false,
          isShowChat: false,
          isShowKM: false,
          isShowBusinessInfo: true,
        );

      case "service":
        List<String> url=[];
        url = widget.message.url?.map((e) => e.url.toString()).toList()??[];
          messageWidget = ServiceMessageCardBusiness(
            isFromOrderTab: widget.isFromOrderTab??false,
            userId: widget.userId??'',
            message: widget.message,
            isFromChatCard: true,
            serviceData: GetServiceModel(
              business: BusinessService(
                businessName:widget.message.metadata?.variant ,
                categoryOfBusiness: CategoryOfBusiness(name:widget.message.metadata?.subCategory)
              ),
                id: widget.message.metadata?.serviceId,
                discounts: [Discounts(amountOff: num.tryParse(widget.message.metadata?.discount ?? '0'))],
                userId: widget.userId,
                type: AppConstants.service,
                title: widget.message.metadata?.title,
                priceType: "single",
                photos:url,
            ),
            isGridView: false,
            isShowChat: false,
            isShowKM: false,
            isShowBusinessInfo: true, conversationId: widget.conversationId??'',
          );

      case "product":
        List<String> url=[];
        url = widget.message.url?.map((e) => e.url.toString()).toList()??[];
          messageWidget = ProductCard(ProductListing(
              image: url,
              name: widget.message.metadata?.title??'',
              id: widget.message.metadata?.productId??'',
            discount:widget.message.metadata?.discount ,
            mrp: widget.message.metadata?.mrp,
            price: widget.message.metadata?.price,
            selectedVariants: (widget.message.metadata?.variant?.contains("{")??false)?jsonDecode(widget.message.metadata?.variant??'{}'):{},
          ),

              width: SizeConfig.screenWidth*0.68,
            time: time
          );
      case "order_request":
        messageWidget = RiderRequestMsgCard(message: widget.message,);
      case "rider":
        messageWidget = RiderDetailsMsgCard(time: time,message: widget.message,);
      case"rider_map":
        messageWidget = RiderLiveLocationMsgCard(message: widget.message, time: time,);
      case "selfpickup":
        messageWidget = SelfPickupMsgCard(message: widget.message, time: time, conversationId: widget.conversationId);

      case "food_selfpickup":
        messageWidget = FoodSelfPickupMsgCard(message: widget.message, time: time, conversationId: widget.conversationId);

      case "product_selfpickup":
        messageWidget = ProductSelfPickupMsgCard(message: widget.message, time: time, conversationId: widget.conversationId);

      case "rider_association":
        messageWidget = RiderAssociationMsgCard(message: widget.message, time: time);

      case "audio_call":
      case "video_call":
        // For outgoing call messages, sender == me, so widget.userId/name/image
        // would point back at the current user. Use the conversation-level
        // partner details (same source as the appbar call button) instead.
        final isMineCall = widget.message.myMessage ?? false;
        return CallMessageCard(
          message: widget.message,
          isReceive: isReceive,
          time: time,
          conversationId: widget.conversationId,
          otherUserId:
              isMineCall ? widget.conversationUserId : widget.userId,
          otherUserName:
              isMineCall ? widget.conversationName : widget.name,
          otherUserImage: isMineCall
              ? widget.conversationProfileImage
              : widget.profileImage,
        );

      case "reply_to_symbol":
        messageWidget = _buildReplyToSymbolMessage(
          widget.message,
          text,
          time,
          isReceive,
        );
        break;

      default:

        messageWidget = (widget.message.visible_to!=null&&widget.message.visible_to!='')?
        (widget.message.visible_to==userId)?
        _buildReceivedMessage(
          widget.message,
          text,
          time,
          isReceive,
        ):SizedBox():_buildReceivedMessage(
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
            animation: _shakeController ?? const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onLongPress: (){
                if (chatThemeController.isMessageSelectionActive.value) {
                  chatThemeController.selectMoreMessage(widget.message);
                } else {
                  showMessageContextMenu(
                    context: context,
                    message: widget.message,
                    messageKey: _messageKey,
                    isReceive: isReceive,
                    messageWidget: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.4),
                      child: messageWidget,
                    ),
                    conversationId: widget.conversationId,
                    userId: widget.userId,
                    name: widget.name,
                    profileImage: widget.profileImage,
                    conversationName: widget.conversationName,
                    conversationProfileImage: widget.conversationProfileImage,
                  );
                }
              },
              onTap: (){

                FocusScope.of(context).unfocus();
                if (chatThemeController.isMessageSelectionActive.value) {
                  chatThemeController.selectMoreMessage(widget.message);
                }else{
                  if(widget.message.messageType=="video"||widget.message.messageType=="image"){
                    if(widget.message.url?.length == 1){
                      Get.to(()=>MediaSliderPage(conversationId: widget.conversationId??'', conversationPersonName: widget.name??"", seletedUrl: widget.message.url?.first.url??'',));
                    }
                  } else if (widget.message.messageType == "reply_to_symbol") {
                    final sym = widget.message.metadata?.symbol;
                    if (sym != null) {
                      // When I sent the reply, my conversation partner IS the
                      // symbol author — use the screen's conversation name/image
                      // as a fallback if the snapshot didn't carry the user.
                      final isMine = widget.message.myMessage ?? false;
                      final fallbackName =
                          isMine ? widget.conversationName : null;
                      final fallbackImage =
                          isMine ? widget.conversationProfileImage : null;
                      Get.to(() => SymbolViewImages(
                            initialSymbol: sym,
                            userId: sym.userId,
                            name: sym.user?.name ?? fallbackName,
                            profileImage:
                                sym.user?.profileImage ?? fallbackImage,
                          ));
                    }
                  } else if (widget.message.messageType == "text" && (widget.message.message?.contains("https://") ?? false)) {
                    final regExp = RegExp(r'(https?:\/\/[^\s]+)');
                    final match = regExp.firstMatch(widget.message.message ?? '');
                    if (match != null) {
                      final url = match.group(0)!;
                      final isBlueEra = url.contains('blueera');
                      launchUrl(Uri.parse(url), mode: isBlueEra ? LaunchMode.inAppBrowserView : LaunchMode.inAppWebView);
                    }
                  }
                }
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset = (_dragOffset + details.delta.dx)
                      .clamp(0, 35); // slide limit
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragOffset > 25) {
                  chatViewController.setReplyMessage(widget.message);
                }
                setState(() => _dragOffset = 0);
              },
              child: Padding(
                key: _messageKey,
                padding: const EdgeInsets.symmetric(vertical: 1.4),
                child: messageWidget,
              ),
            ),
          ),
        ),
        (chatThemeController.isMessageSelectionActive.value &&
                chatThemeController.selectedMessageIds
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
                        .withValues(alpha: 0.4),
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
        required String time
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
            Container(
              color: const Color.fromRGBO(242, 254, 254, 1),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    CustomText(
                      product.name,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),

                    // Price Row
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomText(
                              '₹${product.price}',
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              ' ₹${product.mrp}',
                              fontSize: SizeConfig.small11,
                              color: AppColors.grayText,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: CustomText(
                            "${time}",
                            fontSize: SizeConfig.size10,
                            fontWeight: FontWeight.w400,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.grayText,
                            maxLines: 1,
                          ),
                        )
                      ],
                    ),

                  ],
                ),
              ),
            ),
             const Divider(height: 1,color: Colors.grey,),
            (!(widget.message.myMessage??false))?
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                        ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Unavailable",
                        ApiKeys.message_type: "text",
                      };
                      chatViewController.sendMessage(data);
                    },
                    icon: const Icon(Icons.close, color: Colors.red,),
                    label:  CustomText(
                      'Unavailable',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const VerticalDivider(width: 2,color: Colors.grey,),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                        ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Available",
                        ApiKeys.message_type: "text",
                      };

                      chatViewController.sendMessage(data);
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
                    },
                    icon: Icon(Icons.check,size: 22,),
                    label:   CustomText(
                      'Available',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ):(widget.isFromOrderTab??false)?
            (widget.message.metadata?.is_cancelled??false)? Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: Colors.red,),
                    label:  CustomText(
                      'Canceled',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),


              ],
            ):
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.red, size: 60),
                                  const SizedBox(height: 15),
                                  CustomText(
                                    'Are you sure you want to cancel the order?',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child:  CustomBtn(
                                            bgColor: AppColors.primaryColor,
                                            onTap: ()async{
                                              final controller = Get.put(OrderNowController());
                                              await controller.cancelOrderApi(widget.message.metadata?.order?.orderId??'',widget.message.conversationId??"");
                                              Get.back();
                                            }, title: "Yes"),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomBtn(onTap: (){
                                          Get.back();
                                        }, title: "No"),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: CustomText(
                      'Cancel',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () async{
                      final url = Uri.parse(widget.message.metadata?.order?.trackingUrl ?? '');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppWebView);
                      }
                    },
                    icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
                    label:   CustomText(
                      'Track Order',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ) :(widget.message.metadata?.orderStatus??false)?
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Expanded(
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.close, color: Colors.red,),
                //     label:  CustomText(
                //       'Cancel',
                //       color: Colors.red,
                //       fontWeight: FontWeight.w900,
                //     ),
                //   ),
                // ),
                // const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {

                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
                    },
                    icon: Icon(Icons.check,color: Colors.green,),
                    label:   CustomText(
                      'Order Placed',
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ):Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Expanded(
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.close, color: Colors.red,),
                //     label:  CustomText(
                //       'Cancel',
                //       color: Colors.red,
                //       fontWeight: FontWeight.w900,
                //     ),
                //   ),
                // ),
                // const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // OrderNowDialog.showDialogBox(widget.userId??'',widget.message.id??'',widget.conversationId??"");
                      orderNow(context,widget.message.seller?.id??"",widget.message);

                    },
                    icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
                    label:   CustomText(
                      'Order Now',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void showProductDetailsBottomSheet(BuildContext context, ProductListing product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Product details",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image Carousel
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomImageSlideshow(
                  isLoading: false,
                  height: 430,
                  width: double.infinity,
                  imagePaths: product.image,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),
              Container(

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft: Radius.circular(10),),
                  boxShadow: [
                    AppShadows.bottomShadow,
                    AppShadows.topShadow,
                  ],
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      CustomText(
                        product.name,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),

                      // Price Row
                      Row(
                        children: [
                          CustomText(
                            '₹${product.price}',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.large,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            ' ₹${product.mrp}',
                            fontSize: SizeConfig.medium,
                            color: AppColors.grayText,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.lineThrough,
                          ),
                          CustomText(
                            ' ${product.discount}% off',
                            fontSize: SizeConfig.medium,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:(){

                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                        // selectedOption == null
                        //     ? Colors.grey.shade300
                        //     :
                        Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        "Cancel",
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:(){

                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                        // selectedOption == null
                        //     ? Colors.grey.shade300
                        //     :
                        AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        "Next",
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
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

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black87;
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return Colors.black87;
    return Color(int.parse(h, radix: 16));
  }

  Widget _buildSymbolPreviewThumb(SymbolDetailsModel symbol, {double size = 40}) {
    final type = symbol.type;
    final content = symbol.content ?? '';

    Widget inner;
    if (type == 'photo' ||
        (type == 'video' && !content.toLowerCase().contains('.mp4'))) {
      inner = Container(
        width: size,
        height: size,
        color: Colors.black12,
        child: content.isNotEmpty
            ? Image.network(
                content,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_outlined, color: Colors.white, size: 18),
              )
            : const Icon(Icons.image_outlined, color: Colors.white, size: 18),
      );
    } else if (type == 'video') {
      inner = Container(
        width: size,
        height: size,
        color: Colors.black54,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 22),
      );
    } else if (type == 'text') {
      inner = Container(
        width: size,
        height: size,
        color: _hexToColor(symbol.backgroundColor),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(3),
        child: CustomText(
          content,
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    } else if (type == 'embeddedUrl') {
      inner = Container(
        width: size,
        height: size,
        color: AppColors.primaryColor.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: const Icon(Icons.link, color: AppColors.primaryColor, size: 20),
      );
    } else {
      return const SizedBox.shrink();
    }

    // WhatsApp-style status ring around the thumbnail.
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF25D366),
            Color(0xFF128C7E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: inner,
        ),
      ),
    );
  }

  Widget _buildReplyToSymbolMessage(
      Messages message, String text, String time, bool isReceive) {
    final symbol = message.metadata?.symbol;
    if (symbol == null) {
      // Defensive fallback: no snapshot → render as plain text bubble.
      return _buildReceivedMessage(message, text, time, isReceive);
    }

    final authorName = symbol.user?.name ??
        (isReceive ? (widget.name ?? AppStrings.unknownLabel.tr) : 'You');
    final subtitle = (symbol.caption?.isNotEmpty ?? false)
        ? symbol.caption!
        : (symbol.type == 'text' || symbol.type == 'embeddedUrl')
            ? (symbol.content ?? '')
            : _humanReadableSymbolType(symbol.type);

    // WhatsApp-style status reply header:
    //   ↩  "Replied to <name>'s status"  (or "your status" when I'm the author)
    final isMine = message.myMessage ?? false;
    final headerLabel = isReceive
        ? "Replied to your symbol"
        : "You replied to ${isMine ? '' : authorName + "'s "}symbol".trim();

    return Container(
      // Compact, status-reply style (smaller than a normal text bubble).
      constraints: BoxConstraints(maxWidth: SizeConfig.screenWidth * 0.72),
      margin: EdgeInsets.only(
          left: isReceive ? 0 : 40, right: isReceive ? 40 : 0),
      child: Align(
        alignment: isReceive ? Alignment.centerLeft : Alignment.centerRight,
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: isReceive
                  ? chatThemeController.receiveMessageBgColor.value
                  : chatThemeController.myMessageBgColor.value,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomRight: Radius.circular(isReceive ? 12 : 2),
                bottomLeft: Radius.circular(isReceive ? 2 : 12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Replied to status" indicator row (curved arrow + label).
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply,
                      size: 12,
                      color: chatThemeController.isDarkMode.value
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: CustomText(
                        headerLabel,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: chatThemeController.isDarkMode.value
                            ? Colors.white70
                            : Colors.black54,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Quoted status snippet — compact pill with status-ring thumb.
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 5, 8, 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isReceive
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.18),
                    border: Border(
                      left: BorderSide(
                        color: isReceive
                            ? AppColors.primaryColor
                            : Colors.white70,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSymbolPreviewThumb(symbol, size: 36),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              authorName,
                              fontWeight: FontWeight.w600,
                              color: isReceive
                                  ? AppColors.primaryColor
                                  : Colors.white,
                              fontSize: 12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _iconForSymbolType(symbol.type),
                                  size: 11,
                                  color: isReceive
                                      ? AppColors.grayText
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: CustomText(
                                    subtitle,
                                    color: isReceive
                                        ? AppColors.grayText
                                        : Colors.white70,
                                    fontSize: 11,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact link preview — shown when the quoted symbol is a
                // link (embeddedUrl or content with http), otherwise when the
                // reply text itself contains a URL. Symbol takes precedence.
                Builder(builder: (_) {
                  final symbolHasLink = (symbol.type == 'embeddedUrl' ||
                          (symbol.content?.contains('http') ?? false)) &&
                      (symbol.content?.isNotEmpty ?? false);
                  final String? previewUrl = symbolHasLink
                      ? _firstUrl(symbol.content!)
                      : (text.contains('http') ? _firstUrl(text) : null);
                  if (previewUrl == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: _buildCompactLinkPreview(previewUrl, isReceive),
                  );
                }),
                // Reply text + time
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: CustomText(
                          text,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.5,
                          color: chatThemeController.isDarkMode.value
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      timeAndReadInfoWidget(
                        indicateColor: chatThemeController.isDarkMode.value
                            ? const Color(0xFFE9EDEF)
                            : Colors.black,
                        message: message,
                        isMyMessage: message.myMessage ?? false,
                        time: time,
                        timeColor: chatThemeController.chatTimeColor.value,
                      ),
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

  /// Extracts the first http(s) URL from [text], or null when none exists.
  String? _firstUrl(String text) {
    final match = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(text);
    return match?.group(0);
  }

  /// Compact, single-row link card sized for the narrow status-reply bubble.
  /// ~56 px tall with a small thumb on the left and title/domain stacked.
  Widget _buildCompactLinkPreview(String link, bool isReceive) {
    String domain = link;
    try {
      domain = Uri.parse(link).host;
      if (domain.startsWith('www.')) domain = domain.substring(4);
    } catch (_) {}

    final bgColor = isReceive
        ? Colors.white
        : Colors.white.withValues(alpha: 0.92);
    final titleColor = Colors.black87;
    final domainColor = Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        final isBlueEra = link.contains('blueera');
        launchUrl(Uri.parse(link),
            mode: isBlueEra
                ? LaunchMode.inAppBrowserView
                : LaunchMode.inAppWebView);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: AnyLinkPreview.builder(
            link: link,
            cache: const Duration(days: 7),
            placeholderWidget: SizedBox(
              height: 88,
              child: Row(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      domain,
                      fontSize: 12,
                      color: domainColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            errorWidget: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: domainColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        domain,
                        fontSize: 12,
                        color: domainColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            itemBuilder: (context, metadata, imageProvider, svgImage) {
              final title = (metadata.title?.isNotEmpty ?? false)
                  ? metadata.title!
                  : domain;
              final desc = metadata.desc;
              return SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: imageProvider != null
                          ? Image(image: imageProvider, fit: BoxFit.cover)
                          : svgImage ??
                              Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: Icon(Icons.link,
                                    color: domainColor, size: 26),
                              ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              title,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              height: 1.25,
                            ),
                            if (desc != null && desc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              CustomText(
                                desc,
                                fontSize: 11,
                                color: Colors.black54,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                height: 1.25,
                              ),
                            ],
                            const SizedBox(height: 2),
                            CustomText(
                              domain,
                              fontSize: 10.5,
                              color: domainColor,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _humanReadableSymbolType(String? type) {
    switch (type) {
      case 'photo':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'text':
        return 'Text';
      case 'embeddedUrl':
        return 'Link';
      default:
        return 'Status';
    }
  }

  IconData _iconForSymbolType(String? type) {
    switch (type) {
      case 'photo':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'text':
        return Icons.text_fields_outlined;
      case 'embeddedUrl':
        return Icons.link;
      default:
        return Icons.auto_awesome_outlined;
    }
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
          child: CustomText(text,
             color: Colors.grey.shade700, fontSize: 12),
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


  Widget _buildMapMessage(Messages? messages, String? message, double lat,
      double long, String time, bool isReceiveMsg) {
    _currentPosition = LatLng(lat, long);
    Theme.of(context);
    return Container(
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
                            GoogleMap(
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
                            Positioned(
                              right: SizeConfig.size10,
                              bottom: SizeConfig.size10,
                              child: InkWell(
                                onTap: () async {
                                  final Uri googleMapUrl = Uri.parse(
                                      "https://www.google.com/maps/search/?api=1&query=${_currentPosition?.latitude},${_currentPosition?.longitude}");

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
                            maxLines: 1,
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
                            maxLines: 1,
                            "${message.split('\n').isEmpty?"":message.split('\n').length<2?"":message.split('\n')[1]}",
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
    );
  }

  Widget _buildContactMessage(Messages? message, String name, String number,
      String time, bool isReceiveMsg) {
    final theme = Theme.of(context);
    final displayName = name.trim().isEmpty ? 'Unknown' : name;
    final displayNumber = number.trim().isEmpty ? 'No number' : number;
    final String? profileImage = message?.sharedContactProfileImage;
    final bool hasProfileImage =
        profileImage != null && profileImage.isNotEmpty;

    return Align(
      alignment:
          (isReceiveMsg) ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 270,
        clipBehavior: Clip.antiAlias,
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
            // Contact info section
            Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 8),
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
                          color:
                              (isReceiveMsg) ? Colors.black87 : Colors.white,
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
                        if (displayNumber != 'No number') {
                          _launchSms(displayNumber);
                        }
                      },
                      child: Center(
                        child: CustomText(
                          "Message",
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
                        if (displayNumber != 'No number') {
                          _launchCall(displayNumber);
                        }
                      },
                      child: Center(
                        child: CustomText(
                          "Call",
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
                  // Save / View button
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        saveContactWithEditor(displayName, displayNumber);
                      },
                      child: Center(
                        child: CustomText(
                          "Save",
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

  Future<void> saveContactWithEditor(String name, String phoneNumber) async {
    // Request contact permission
    var permissionStatus = await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      final contact = Contact()
        ..name = Name(first: name)
        ..phones = [Phone(phoneNumber)];

      // Opens the native contact editor with prefilled data so user can review/edit
      await FlutterContacts.openExternalInsert(contact);
    } else {
      // Permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact permission denied')),
      );
    }
  }
}

class FoodCardMessageCardBusiness extends StatefulWidget {
  final GetFoodDetailsModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final Messages message;
  final String userId;
  final String time;
  final  bool isFromOrderTab;
  final String conversationId;
  final List<String> photos;
  final bool isShowKM;
  final bool isFromChatCard;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const FoodCardMessageCardBusiness({
    Key? key,
    required this.serviceData,
    required this.isFromOrderTab,
    this.isGridView = false,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isFromChatCard= false,
    this.isShowBusinessInfo = false,
    this.businessData, required this.message, required this.userId, required this.conversationId, required this.photos, required this.time,
  }) : super(key: key);

  @override
  State<FoodCardMessageCardBusiness> createState() => _FoodCardMessageCardBusinessState();
}

class _FoodCardMessageCardBusinessState extends State<FoodCardMessageCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  GetFoodDetailsModel? serviceData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    final priceOptions = serviceData?.priceOptions;
    String priceText = "N/A";
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return InkWell(
      onTap: () {
        if(widget.isFromChatCard==false){
          Get.to(FoodDetailsViewScreen(
            productPriceFormat:(serviceData?.priceType == "single")?"${serviceData?.singlePrice ?? "0"}": "$priceText",
            data: serviceData ?? GetFoodDetailsModel(),
          ));
        }
      },
      child: Container(
        margin: EdgeInsets.only(right:widget.isFromChatCard? 0:20,bottom: 2),
        width: widget.isFromChatCard?SizeConfig.screenWidth*0.68:MediaQuery.of(context).size.width * 0.45,
        // height: 310,
        // responsive width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: 170,
                imagePaths: widget.photos,
                borderRadius: BorderRadius.zero,
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size50,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.title ?? "N/A",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                children: [
                  (serviceData?.vegType == null)
                      ? SizedBox()
                      : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: (serviceData?.vegType == "veg")
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomText("${serviceData?.vegType ?? "veg"}",
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                  (serviceData?.vegType == null)
                      ? SizedBox()
                      : const SizedBox(
                    width: 6,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.food_bank_outlined,
                        size: 19,
                      ),
                      CustomText(
                        serviceData?.subCategory ?? "N/A",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                "Energy : ${serviceData?.nutritionalSummaryPer100g?.caloriesKcal ?? "N/A"} Cal/100gm",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (serviceData?.priceType == "single")
                    ? Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: CustomText(
                    "Price : ₹ ${serviceData?.singlePrice ?? "0"}",
                    fontSize: SizeConfig.small,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    color: AppColors.primaryColor,
                  ),
                )
                    : Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: CustomText(
                    "Price : ₹ ${priceText}",
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: CustomText(
                    "${widget.time}",
                    fontSize: SizeConfig.size10,
                    fontWeight: FontWeight.w400,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.grayText,
                    maxLines: 1,
                  ),
                )
              ],
            ),
            SizedBox(height: SizeConfig.size5),

            KmAwayTextWidget(
                lat: serviceData?.business?.businessLocation?.lat.toString() ??
                    "",
                long:
                serviceData?.business?.businessLocation?.lon?.toString() ??
                    ""),
            const Divider(height: 1,color: Colors.grey,),

            (!(widget.message.myMessage??false))?
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                        ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Unavailable",
                        ApiKeys.message_type: "text",
                      };

                      chatViewController.sendMessage(data);
                    },
                    icon: const Icon(Icons.close, color: Colors.red,),
                    label:  CustomText(
                      'Unavailable',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const VerticalDivider(width: 2,color: Colors.grey,),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                          ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Available",
                        ApiKeys.reply_id: "${widget.message.id}",
                        ApiKeys.message_type: "text",
                      };

                      chatViewController.sendMessage(data);
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
                    },
                    icon: Icon(Icons.check,size: 22,),
                    label:   CustomText(
                      'Available',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ):(widget.isFromOrderTab)?
            (widget.message.metadata?.is_cancelled??false)? Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: Colors.red,),
                    label:  CustomText(
                      'Canceled',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),


              ],
            ):
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.red, size: 60),
                                  const SizedBox(height: 15),
                                  CustomText(
                                    'Are you sure you want to cancel the order?',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child:  CustomBtn(
                                            bgColor: AppColors.primaryColor,
                                            onTap: ()async{
                                              final controller = Get.put(OrderNowController());
                                              await controller.cancelOrderApi(widget.message.metadata?.order?.orderId??'',widget.message.conversationId??"");
                                              Get.back();
                                            }, title: "Yes"),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomBtn(onTap: (){
                                          Get.back();
                                        }, title: "No"),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: CustomText(
                      'Cancel',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () async{
                      final url = Uri.parse(widget.message.metadata?.order?.trackingUrl ?? '');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppWebView);
                      }
                    },
                    icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
                    label:   CustomText(
                      'Track Order',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ) :(widget.message.metadata?.orderStatus??false)?
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Expanded(
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.close, color: Colors.red,),
                //     label:  CustomText(
                //       'Cancel',
                //       color: Colors.red,
                //       fontWeight: FontWeight.w900,
                //     ),
                //   ),
                // ),
                // const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {

                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
                    },
                    icon: Icon(Icons.check,color: Colors.green,),
                    label:   CustomText(
                      'Order Placed',
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            )  :
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Expanded(
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.close, color: Colors.red,),
                //     label:  CustomText(
                //       'Cancel',
                //       color: Colors.red,
                //       fontWeight: FontWeight.w900,
                //     ),
                //   ),
                // ),
                // const VerticalDivider(width: 1,color: Colors.grey,),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // _openBusinessToRiderOTP(context);
                      orderNow(context,widget.message.seller?.id??"",widget.message);
                    },
                    icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
                    label:   CustomText(
                      'Order Now',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
class ServiceMessageCardBusiness extends StatefulWidget {
  final GetServiceModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isFromOrderTab;
  final bool isFromChatCard;
  final Messages message;
  final String userId;
  final String conversationId;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const ServiceMessageCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isFromChatCard= false,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
    required this.message, required this.userId, required this.conversationId, required this.isFromOrderTab,
  }) : super(key: key);

  @override
  State<ServiceMessageCardBusiness> createState() => _ServiceMessageCardBusinessState();
}

class _ServiceMessageCardBusinessState extends State<ServiceMessageCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  GetServiceModel? serviceData;

  // var kmAway;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    // Find max discount
    Discounts? maxDiscount;
    if ((serviceData?.discounts?.length ?? 0) > 0)
      maxDiscount = serviceData?.discounts
          ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

    return InkWell(
      onTap: () {
        if(widget.isFromChatCard==false){
          Get.to(()=> ServiceDetailsScreen(
            service: serviceData ?? GetServiceModel(),
          ));
        }

      },
      child: Container(
        margin: EdgeInsets.only(right: widget.isFromChatCard? 0:20),
        width: widget.isFromChatCard?SizeConfig.screenWidth*0.68:MediaQuery.of(context).size.width * 0.45,
        // responsive width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: 170,
                imagePaths: serviceData?.photos ?? [],
                borderRadius: BorderRadius.zero,
              ),
            ),

            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.title ?? "N/A",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.business?.categoryOfBusiness?.name ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            SizedBox(height: SizeConfig.size5),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.business?.businessName ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            Container(
              // alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(30)),
              child: CustomText(
                (maxDiscount?.amountOff != null)
                    ? "${maxDiscount?.amountOff.toString()}% Off"
                    : "0% Off",
                fontSize: SizeConfig.size10,
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            KmAwayTextWidget(
                lat: serviceData?.business?.businessLocation?.lat.toString() ??
                    "",
                long:
                serviceData?.business?.businessLocation?.lon?.toString() ??
                    ""),

            (!(widget.message.myMessage??false))?const Divider(height: 1,color: Colors.grey,):SizedBox(),
            (!(widget.message.myMessage??false))?
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                        ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Unavailable",
                        ApiKeys.message_type: "text",
                      };

                      chatViewController.sendMessage(data);
                    },
                    icon: const Icon(Icons.close, color: Colors.red,),
                    label:  CustomText(
                      'Unavailable',
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const VerticalDivider(width: 2,color: Colors.grey,),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Map<String,dynamic> data = {
                        ApiKeys.conversation_id: widget.conversationId,
                        ApiKeys.message: "Available",
                        ApiKeys.message_type: "text",
                      };

                      chatViewController.sendMessage(data);
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
                    },
                    icon: Icon(Icons.check,size: 22,),
                    label:   CustomText(
                      'Available',
                      color: Colors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ):
            SizedBox(),
          ],
        ),
      ),
    );
  }
}
void orderNow(BuildContext context,String businessId,Messages message){
  OrderCommonWidget.showEnterOrderValueDialog(context,businessId,message);

}