import 'dart:convert';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/widget/message_bubble.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';

class StoreMessageCard extends StatefulWidget {
  const StoreMessageCard(
      {super.key,
        required this.message,
        this.profileImage,
        this.name,
        this.contactNo});

  final Messages message;
  final String? profileImage;
  final String? name;
  final String? contactNo;

  @override
  State<StoreMessageCard> createState() => _StoreMessageCardState();
}

class _StoreMessageCardState extends State<StoreMessageCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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

    Theme.of(context);
    final text = widget.message.message ?? '';


    // final currentUserId = widget.userId;
    // final senderId = widget.message.senderId;
    // bool isReceive = currentUserId != senderId;
    bool isReceive = true;

    final time = formatChatTime(widget.message.createdAt ?? '');
    Widget messageWidget;
    switch (widget.message.messageType) {

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
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragOffset + _shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.4),
              child: messageWidget,
            ),
          ),
        ),
      ],
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
            const Divider(height: 1,color: Colors.grey),

            // (!(widget.message.myMessage??false))?
            // Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {
            //           Map<String,dynamic> data = {
            //             ApiKeys.conversation_id: widget.conversationId,
            //             ApiKeys.message: "Unavailable",
            //             ApiKeys.message_type: "text",
            //           };
            //           chatViewController.sendMessage(data);
            //         },
            //         icon: const Icon(Icons.close, color: Colors.red,),
            //         label:  CustomText(
            //           'Unavailable',
            //           color: Colors.red,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //     const VerticalDivider(width: 2,color: Colors.grey,),
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {
            //           Map<String,dynamic> data = {
            //             ApiKeys.conversation_id: widget.conversationId,
            //             ApiKeys.message: "Available",
            //             ApiKeys.message_type: "text",
            //           };
            //
            //           chatViewController.sendMessage(data);
            //           // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
            //         },
            //         icon: Icon(Icons.check,size: 22,),
            //         label:   CustomText(
            //           'Available',
            //           color: Colors.blue,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //   ],
            // ):(widget.isFromOrderTab??false)?
            // (widget.message.metadata?.is_cancelled??false)? Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {},
            //         icon: const Icon(Icons.close, color: Colors.red,),
            //         label:  CustomText(
            //           'Canceled',
            //           color: Colors.red,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //
            //
            //   ],
            // ):
            // Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {
            //           showDialog(
            //             context: context,
            //             builder: (context) {
            //               return Dialog(
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(16),
            //                 ),
            //                 child: Padding(
            //                   padding: const EdgeInsets.all(20.0),
            //                   child: Column(
            //                     mainAxisSize: MainAxisSize.min,
            //                     children: [
            //                       const Icon(Icons.warning_amber_rounded,
            //                           color: Colors.red, size: 60),
            //                       const SizedBox(height: 15),
            //                       CustomText(
            //                         'Are you sure you want to cancel the order?',
            //                         fontWeight: FontWeight.w700,
            //                         fontSize: 16,
            //                         textAlign: TextAlign.center,
            //                       ),
            //                       const SizedBox(height: 25),
            //                       Row(
            //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //                         children: [
            //                           Expanded(
            //                             child:  CustomBtn(
            //                                 bgColor: AppColors.primaryColor,
            //                                 onTap: ()async{
            //                                   final controller = Get.put(OrderNowController());
            //                                   await controller.cancelOrderApi(widget.message.metadata?.order?.orderId??'',widget.message.conversationId??"");
            //                                   Get.back();
            //                                 }, title: "Yes"),
            //                           ),
            //                           const SizedBox(width: 10),
            //                           Expanded(
            //                             child: CustomBtn(onTap: (){
            //                               Get.back();
            //                             }, title: "No"),
            //                           ),
            //                         ],
            //                       )
            //                     ],
            //                   ),
            //                 ),
            //               );
            //             },
            //           );
            //         },
            //         icon: const Icon(Icons.close, color: Colors.red),
            //         label: CustomText(
            //           'Cancel',
            //           color: Colors.red,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //     const VerticalDivider(width: 1,color: Colors.grey,),
            //
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () async{
            //           final url = Uri.parse(widget.message.metadata?.order?.trackingUrl ?? '');
            //           if (await canLaunchUrl(url)) {
            //             await launchUrl(url, mode: LaunchMode.inAppWebView);
            //           }
            //         },
            //         icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
            //         label:   CustomText(
            //           'Track Order',
            //           color: Colors.blue,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //   ],
            // ) :(widget.message.metadata?.orderStatus??false)?
            // Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     // Expanded(
            //     //   child: TextButton.icon(
            //     //     onPressed: () {},
            //     //     icon: const Icon(Icons.close, color: Colors.red,),
            //     //     label:  CustomText(
            //     //       'Cancel',
            //     //       color: Colors.red,
            //     //       fontWeight: FontWeight.w900,
            //     //     ),
            //     //   ),
            //     // ),
            //     // const VerticalDivider(width: 1,color: Colors.grey,),
            //
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {
            //
            //           // Navigator.push(context, MaterialPageRoute(builder: (context)=>PayoutScreen()));
            //         },
            //         icon: Icon(Icons.check,color: Colors.green,),
            //         label:   CustomText(
            //           'Order Placed',
            //           color: Colors.green,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //   ],
            // ):Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     // Expanded(
            //     //   child: TextButton.icon(
            //     //     onPressed: () {},
            //     //     icon: const Icon(Icons.close, color: Colors.red,),
            //     //     label:  CustomText(
            //     //       'Cancel',
            //     //       color: Colors.red,
            //     //       fontWeight: FontWeight.w900,
            //     //     ),
            //     //   ),
            //     // ),
            //     // const VerticalDivider(width: 1,color: Colors.grey,),
            //
            //     Expanded(
            //       child: TextButton.icon(
            //         onPressed: () {
            //           // OrderNowDialog.showDialogBox(widget.userId??'',widget.message.id??'',widget.conversationId??"");
            //           orderNow(context,widget.message.seller?.id??"",widget.message);
            //
            //         },
            //         icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
            //         label:   CustomText(
            //           'Order Now',
            //           color: Colors.blue,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

}