import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class AskInventoryProductMsgCard extends StatelessWidget {
  final InventoryAskAiModel response;

  AskInventoryProductMsgCard({Key? key, required this.response}) : super(key: key);

  final chatThemeController = getOrPut(() => ChatThemeController());

  bool hasValidLogo(String? url) {
    return url != null &&
        url.isNotEmpty &&
        url.toLowerCase() != "null";
  }
  Widget _fallbackAvatar() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.store,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productList = response.data?.products ?? [];


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -----------------------------------
          /// 1. REPLY TEXT
          /// -----------------------------------
          Container(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            margin: EdgeInsets.only(right: 50),
            decoration: BoxDecoration(
              color: chatThemeController.receiveMessageBgColor.value,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(0.0)
              ),
            ),
            child: CustomText(
              response.message ?? "",
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,

            ),
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
                      ApiKeys.id: business?.businessId??'',
                      ApiKeys.providerType:ProviderType.business
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                          ClipOval(
                            child: hasValidLogo(business?.business_logo)
                                ? Image.network(
                              business!.business_logo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _fallbackAvatar();
                              },
                            )
                                : _fallbackAvatar(),
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
                                          ],
                                        ),

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

                            Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async{
                                      final chatViewController = Get.find<ChatViewController>();
                                      Map<String, dynamic> detas = {
                                        ApiKeys.user_id: business?.user_id
                                      };
                                      Map<String,dynamic>? userDetailsMap= await chatViewController.checkChatConnection(detas);
                                     if(userDetailsMap!=null){
                                       List<Map<String, String>>? urlList =
                                       product?.media.map((e) => {ApiKeys.url: e}).toList();
                                       final conversationId = userDetailsMap[ApiKeys.conversation_id];

                                       final hasConversation = conversationId != null &&
                                           conversationId.toString().isNotEmpty &&
                                           conversationId.toString().toLowerCase() != 'null';
                                       Map<String, dynamic> data = {
                                         ApiKeys.product_id:"${product?.id}",
                                         ApiKeys.price: "${product?.mrpPerUnit}",
                                         ApiKeys.discount: "",
                                         if (!hasConversation)
                                           ApiKeys.other_user_id: (userDetailsMap[ApiKeys.other_user_id] ??
                                               '')
                                         else
                                           ApiKeys.conversation_id: (userDetailsMap[ApiKeys.conversation_id] ??
                                               ''),
                                         ApiKeys.message:
                                         "${product?.name}",
                                         ApiKeys.message_type:AppConstants.product,
                                         ApiKeys.title: product?.name,
                                         ApiKeys.mrp :'${product?.mrpPerUnit}',
                                         ApiKeys.url: urlList,
                                       };
                                       chatViewController.
                                       openAnyOneChatFunction(
                                         shareProductParams: data,
                                         isWithProductSend: true,
                                         profileImage: business?.business_logo,
                                         otherUserId: (!hasConversation)?
                                         userDetailsMap[ApiKeys.other_user_id] ??
                                             ''
                                             : null,
                                         // businessId: widget
                                         //     .productStore?.sellerClassification?.owner?.id,
                                         type: AppConstants.business_Chat_Type,
                                         isInitialMessage: (!hasConversation)? true
                                             : false,
                                         userId: business?.user_id,
                                         conversationId: (userDetailsMap[ApiKeys.conversation_id] ??
                                             ''),
                                         contactName: business?.business_name,
                                         contactNo: business?.mobile_no,
                                       );
                                     }

                                    },
                                    icon: LocalAssets(
                                      imagePath: AppIconAssets.chat,
                                      imgColor: AppColors.primaryColor
                                    ),
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
