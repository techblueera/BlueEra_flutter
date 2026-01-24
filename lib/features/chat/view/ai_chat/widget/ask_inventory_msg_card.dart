
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/inventory_ask_ai_model.dart';

class AskInventoryMsgCard extends StatelessWidget {
  final InventoryAskAiModel response;

  const AskInventoryMsgCard({Key? key, required this.response}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productList = response.products ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -----------------------------------
          /// 1. REPLY TEXT
          /// -----------------------------------
          CustomText(
            response.reply ?? "",
              fontSize: 12,
              fontWeight: FontWeight.w600,

          ),

          const SizedBox(height: 20),

          /// -----------------------------------
          /// 2. PRODUCT CARDS (GRID)
          /// -----------------------------------
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productList.length > 6 ? 6 : productList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 272,
            ),
            itemBuilder: (_, i) {
              final item = productList[i];
              final business = item.product;
              final product = item.product?.details;
              return InkWell(
                onTap: (){
                  Get.toNamed(
                    RouteHelper.getStoreProductPreviewScreenProductRoute(),
                    arguments: {
                      ApiKeys.argProductData: business,
                      // "isShowBusinessInfo": widget.isShowBusinessInfo,
                      ApiKeys.id: business?.businessId??'',
                      ApiKeys.providerType:ProviderType.business
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    // border: Border.all(color: Colors.grey.shade300),
                    color: Colors.transparent,

                  ),

                  /// -----------------------------------
                  /// PRODUCT CARD CONTENT
                  /// -----------------------------------
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// BUSINESS LOGO + NAME
                      ///
                      Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: business?.business_logo==null?null: NetworkImage(
                              business?.business_logo ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              business?.business_name ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                            
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Container(
                        // width: width,
                        // padding: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.whiteFE,
                          boxShadow:  [AppShadows.cardShadow],
                          borderRadius: BorderRadius.circular(10),

                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            AspectRatio(
                              aspectRatio: 1.8, // square-ish image (adjust if needed)
                              child: Stack(
                                children: [
                                  CustomImageSlideshow(
                                    isLoading: false,
                                    width: double.infinity,
                                    height: 110,
                                    imagePaths: product?.media??[],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _buildIconBox(InkWell(
                                        onTap: (){

                                        },
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
                                      product?.name,
                                      fontSize: SizeConfig.size12,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),

                                    // Price Row
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            if(product?.mrpPerUnit!=null)
                                            CustomText(
                                              '₹${product?.mrpPerUnit}',
                                              fontWeight: FontWeight.w700,
                                              fontSize: SizeConfig.medium,
                                              color: AppColors.mainTextColor,
                                            ),
                                            // const SizedBox(width: 8),
                                            // CustomText(
                                            //   ' ₹${product.mrp}',
                                            //   fontSize: SizeConfig.small11,
                                            //   color: AppColors.grayText,
                                            //   fontWeight: FontWeight.w400,
                                            //   decoration: TextDecoration.lineThrough,
                                            // ),
                                            // CustomText(
                                            //   ' ${product.discount}% off',
                                            //   fontSize: SizeConfig.small11,
                                            //   color: Colors.green[600],
                                            //   fontWeight: FontWeight.w400,
                                            // ),
                                          ],
                                        ),
                                        // Padding(
                                        //   padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        //   child: CustomText(
                                        //     "${time}",
                                        //     fontSize: SizeConfig.size10,
                                        //     fontWeight: FontWeight.w400,
                                        //     overflow: TextOverflow.ellipsis,
                                        //     color: AppColors.grayText,
                                        //     maxLines: 1,
                                        //   ),
                                        // )
                                      ],
                                    ),
                                    CustomText(
                                      '${product?.brand}',
                                      fontWeight: FontWeight.w700,
                                      fontSize: SizeConfig.size12,
                                      color: AppColors.primaryColor,
                                    ),

                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1,color: Colors.grey,),
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
                            // ):
                            Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async{
                                      final chatViewController = Get.find<ChatViewController>();
                                      Map<String, dynamic> detas = {
                                        ApiKeys.user_id: business?.user_id
                                      };
                                      chatViewController.newVisitContactApiResponse?.value;
                                      await chatViewController.checkChatConnection(detas);
                                      List<Map<String, String>>? urlList =
                                      product?.media.map((e) => {"url": e}).toList();
                                     Map<String, dynamic> data = {
                                        ApiKeys.product_id:"${product?.id}",

                                        ApiKeys.price: "${product?.mrpPerUnit}",
                                        ApiKeys.discount: "",
                                        if ((chatViewController.newVisitContactApiResponse
                                            ?.value?.data?.conversationId ==
                                            '' ||
                                            chatViewController.newVisitContactApiResponse
                                                ?.value?.data?.conversationId ==
                                                null))
                                          ApiKeys.other_user_id: (chatViewController
                                              .newVisitContactApiResponse
                                              ?.value
                                              ?.data
                                              ?.otherUserId ??
                                              '')
                                        else
                                          ApiKeys.conversation_id: (chatViewController
                                              .newVisitContactApiResponse
                                              ?.value
                                              ?.data
                                              ?.conversationId ??
                                              ''),
                                        ApiKeys.message:
                                        "${product?.name}",
                                        ApiKeys.message_type: "product",
                                        ApiKeys.title: product?.name,
                                        ApiKeys.mrp :'',
                                        ApiKeys.url: urlList,
                                      };
                                      chatViewController.
                                      openAnyOneChatFunction(
                                        shareProductParams: data,
                                        isWithProductSend: true,
                                        profileImage: business?.business_logo,
                                        otherUserId: (chatViewController.newVisitContactApiResponse
                                            ?.value?.data?.conversationId ??
                                            '') ==
                                            ""
                                            ? chatViewController.newVisitContactApiResponse?.value
                                            ?.data?.otherUserId ??
                                            ''
                                            : null,
                                        // businessId: widget
                                        //     .productStore?.sellerClassification?.owner?.id,
                                        type: AppConstants.business_Chat_Type,
                                        isInitialMessage: (chatViewController
                                            .newVisitContactApiResponse
                                            ?.value
                                            ?.data
                                            ?.conversationId ??
                                            '') ==
                                            ""
                                            ? true
                                            : false,
                                        userId: business?.user_id,
                                        conversationId: (chatViewController
                                            .newVisitContactApiResponse
                                            ?.value
                                            ?.data
                                            ?.conversationId ??
                                            ''),
                                        contactName: business?.business_name,
                                        contactNo: business?.mobile_no,
                                      );
                                    },
                                    icon: SvgPicture.asset(AppIconAssets.chat,color: AppColors.primaryColor,),
                                    label:   CustomText(
                                      'Chat Now',
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

                      /// PRODUCT DETAILS

                    ],
                  ),
                ),
              );
            },
          ),

          /// SEE MORE BUTTON
          if (productList.length > 6)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "See More",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
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
}
