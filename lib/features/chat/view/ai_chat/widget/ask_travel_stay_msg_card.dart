import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/travel_and_stay_ask_ai_model.dart';
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

class AskTravelStayMsgCard extends StatelessWidget {
  final TravelAndStayAskAiModel response;

  AskTravelStayMsgCard({Key? key, required this.response}) : super(key: key);

  final chatThemeController = getOrPut(() => ChatThemeController());

  @override
  Widget build(BuildContext context) {
    final hotelsList = response.data?.hotelData ?? [];

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
            itemCount: hotelsList.length > 6 ? 6 : hotelsList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 340,
            ),
            itemBuilder: (_, i) {
              final item = hotelsList[i];
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
                            backgroundImage: profile?.coverUrl==null?null: NetworkImage(
                              profile?.coverUrl ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              profile?.name ?? "",
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
                              child: (profile?.photos?.isNotEmpty ?? false)
                                  ? CustomImageSlideshow(
                                isLoading: false,
                                width: double.infinity,
                                height: 110,
                                imagePaths: profile?.photos?[0].imageReferences??[],
                                borderRadius: BorderRadius.circular(10),
                              ) : LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image,
                                height: 110,
                                boxFix: BoxFit.cover,
                              ),
                            ),

                            // Details
                            Container(
                              color: const Color.fromRGBO(242, 254, 254, 1),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Name
                                    CustomText(
                                      profile?.name,
                                      fontSize: SizeConfig.size12,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),

                                    _buildItem(
                                        Icons.location_on_outlined,
                                          profile?.address != null ? [
                                          profile?.address?.city,
                                          profile?.address?.state,
                                          profile?.address?.country,
                                          profile?.address?.pincode
                                        ]
                                            .where((element) => element != null && element.isNotEmpty)
                                            .join(', ')
                                       :  "N/A",
                                        maxLines: 2
                                    ),

                                    _buildItem(
                                      Icons.near_me_outlined,
                                      distance!=null
                                          ? "${distance.toStringAsFixed(2)} KM"
                                          : AppStrings.na,
                                    ),

                                    // Phone Number
                                    _buildItem(
                                      Icons.phone_outlined,
                                      profile!=null && (profile.contacts?.isNotEmpty ?? false)
                                          ? (profile.contacts?[0].phone ?? AppStrings.na)
                                          : AppStrings.na,
                                    ),

                                    _buildItem(
                                      Icons.language_outlined,
                                      profile?.website ?? "N/A",
                                      isLink: true,
                                    ),

                                    // CustomText(
                                    //   [
                                    //     profile?.address?.city,
                                    //     profile?.address?.state,
                                    //     profile?.address?.country,
                                    //     profile?.address?.pincode
                                    //   ]
                                    //       .where((element) => element != null && element.isNotEmpty)
                                    //       .join(', '),
                                    //   fontWeight: FontWeight.w700,
                                    //   fontSize: SizeConfig.medium,
                                    //   color: AppColors.mainTextColor,
                                    // ),
                                    // CustomText(
                                    //   profile?.contacts?[0].phone,
                                    //   fontWeight: FontWeight.w700,
                                    //   fontSize: SizeConfig.size12,
                                    //   color: AppColors.secondaryTextColor,
                                    // ),
                                    // CustomText(
                                    //   profile?.website,
                                    //   fontWeight: FontWeight.w700,
                                    //   fontSize: SizeConfig.size12,
                                    //   color: AppColors.primaryColor,
                                    // ),

                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1,color: Colors.grey,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final chatViewController = Get.find<ChatViewController>();
                                      Map<String, dynamic> detas = {
                                        ApiKeys.user_id: profile?.sId
                                      };

                                      Map<String,dynamic>? userDetailsMap=  await chatViewController.checkChatConnection(detas);
                                      if(userDetailsMap!=null){
                                        List<Map<String, String>>? urlList;
                                        if( profile?.photos?.isNotEmpty??false){
                                          urlList=  profile?.photos?.first.imageReferences?.map((e) => {ApiKeys.url: e}).toList()??[];
                                        }

                                        final conversationId = userDetailsMap[ApiKeys.conversation_id];

                                        final hasConversation = conversationId != null &&
                                            conversationId.toString().isNotEmpty &&
                                            conversationId.toString().toLowerCase() != 'null';
                                        Map<String,dynamic> data={
                                          ApiKeys.service_id : "${item.businessId}",
                                          ApiKeys.price: "",
                                          ApiKeys.discount: "",
                                          if(!hasConversation)
                                            ApiKeys.other_user_id: (userDetailsMap[ApiKeys.other_user_id] ??
                                                '')
                                          else
                                            ApiKeys.conversation_id:(userDetailsMap[ApiKeys.conversation_id] ??
                                                ''),

                                          ApiKeys.message: "${profile?.name}",
                                          ApiKeys.message_type: AppConstants.service,
                                          ApiKeys.title: "${profile?.name}" ,
                                          ApiKeys.sub_category : "${profile?.description}",
                                          ApiKeys.variant : "",

                                          ApiKeys.url: urlList??[],
                                        };
                                        chatViewController.checkChatConnectionAndOpenChat(
                                          userId: "${profile?.sId}",
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
                                      AppStrings.chatNow.tr,
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
          if (hotelsList.length > 6)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CustomText(
                  AppStrings.seeMore.tr,
                  fontSize: 15,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
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
