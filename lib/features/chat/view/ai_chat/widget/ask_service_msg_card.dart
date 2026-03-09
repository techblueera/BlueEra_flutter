import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/business_service_ask_ai_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../auth/controller/chat_view_controller.dart';

class AskServiceMsgCard extends StatelessWidget {
  final BusinessServicesAskAiModel response;

  AskServiceMsgCard({Key? key, required this.response}) : super(key: key);

  final chatThemeController = getOrPut(() => ChatThemeController());


  @override
  Widget build(BuildContext context) {
    final arrServices = response.data?.data ?? [];

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
            itemCount: arrServices.length > 6 ? 6 : arrServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 310,
            ),
            itemBuilder: (_, i) {
              final item = arrServices[i];
              final profile = item.profile;

              final distance = calculateDistance(
                  profile?.location?.coordinates?[1] ?? 0.0,
                  profile?.location?.coordinates?[0] ?? 0.0);

              return InkWell(
                onTap: (){
                  // Get.toNamed(
                  //   RouteHelper.getStoreProductPreviewScreenProductRoute(),
                  //   arguments: {
                  //     ApiKeys.argProductData: business,
                  //     // "isShowBusinessInfo": widget.isShowBusinessInfo,
                  //     ApiKeys.id: business?.businessId??'',
                  //     ApiKeys.providerType:ProviderType.business
                  //   },
                  // );
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
                            backgroundImage: profile?.logoUrl==null?null: NetworkImage(
                              profile?.logoUrl ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              profile?.profileName ?? "",
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
                              child: CustomImageSlideshow(
                                isLoading: false,
                                width: double.infinity,
                                height: 110,
                                imagePaths: (item.gallery ?? [])
                                    .map((g) => g.imageUrls ?? [])
                                    .expand((urlList) => urlList)
                                    .whereType<String>()
                                    .toList(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            //  Details
                            Container(
                              color: const Color.fromRGBO(242, 254, 254, 1),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    CustomText(
                                      profile?.profileName,
                                      fontSize: SizeConfig.size12,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),

                                    _buildItem(
                                        Icons.location_on_outlined,
                                        profile?.location?.address ?? "N/A",
                                        maxLines: 2
                                    ),

                                    // Distance
                                    _buildItem(
                                      Icons.near_me_outlined,
                                      distance!=null
                                          ? "${distance.toStringAsFixed(2)} KM"
                                          : AppStrings.na,
                                    ),

                                    _buildItem(
                                      Icons.language_outlined,
                                      item.contactUs?[0].websiteUrl ?? "N/A",
                                      isLink: true,
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
                                      // Discounts? maxDiscount;
                                      // if ((service.discounts?.length ?? 0) > 0)
                                      //   maxDiscount = service.discounts
                                      //       ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

                                      final chatViewController = Get.find<ChatViewController>();
                                      Map<String, dynamic> detas = {
                                        ApiKeys.user_id: profile?.userId
                                      };

                                      Map<String,dynamic>? userDetailsMap=  await chatViewController.checkChatConnection(detas);
                                      if(userDetailsMap!=null){
                                        List<Map<String, String>>? urlList;
                                        if( item.gallery?.isNotEmpty??false){
                                          urlList= item.gallery?.first.imageUrls?.map((e) => {ApiKeys.url: e}).toList()??[];
                                        }

                                        final conversationId = userDetailsMap[ApiKeys.conversation_id];

                                        final hasConversation = conversationId != null &&
                                            conversationId.toString().isNotEmpty &&
                                            conversationId.toString().toLowerCase() != 'null';
                                        Map<String,dynamic> data={
                                          ApiKeys.service_id : " ",
                                          // ApiKeys.price: "${service.priceRange?.min} - ${service.priceRange?.max} per ${service.perUnit ?? ''}",
                                          ApiKeys.price: "",
                                          // ApiKeys.discount: "${(maxDiscount?.amountOff != null)
                                          //     ? "${maxDiscount?.amountOff.toString()}% Off"
                                          //     : "0% Off"}",
                                          ApiKeys.discount: "",
                                          if(!hasConversation)
                                            ApiKeys.other_user_id: (userDetailsMap[ApiKeys.other_user_id] ??
                                                '')
                                          else
                                            ApiKeys.conversation_id:(userDetailsMap[ApiKeys.conversation_id] ??
                                                ''),

                                          ApiKeys.message: "${profile?.profileName}",
                                          ApiKeys.message_type: AppConstants.service,
                                          ApiKeys.title: profile?.profileName,
                                          ApiKeys.sub_category : "${profile?.description}",
                                          ApiKeys.variant : "",
                                          // ApiKeys.variant : "${service.business?.businessName ?? "N/A"}",

                                          ApiKeys.url: urlList??[],
                                        };
                                        chatViewController.checkChatConnectionAndOpenChat(
                                          userId: profile?.userId ?? '',
                                          shareProductParams: data,
                                          isWithProductSend: true,
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


                    ],
                  ),
                ),
              );
            },
          ),

          /// SEE MORE BUTTON
          if (arrServices.length > 6)
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

  Widget _buildItem(IconData icon, String text, {bool isLink = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isLink ? Colors.blue : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: isLink ? ()=> launchURL(text) : null,
              child: CustomText(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                fontSize: SizeConfig.small,
                color: isLink ? AppColors.primaryColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
