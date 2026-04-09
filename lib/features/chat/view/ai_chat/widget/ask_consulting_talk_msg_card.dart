import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/service_ask_ai_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../auth/controller/chat_view_controller.dart';

class AskConsultingTalkMsgCard extends StatelessWidget {
  final ServiceAskAiModel response;

  AskConsultingTalkMsgCard({super.key, required this.response});

  final chatThemeController = getOrPut(() => ChatThemeController());

  @override
  Widget build(BuildContext context) {
    final arrConsultingService = response.data?.serviceModel ?? [];

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
          /// 2. Education CARDS (GRID)
          /// -----------------------------------
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: arrConsultingService.length > 6 ? 6 : arrConsultingService.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 272,
            ),
            itemBuilder: (_, i) {
              final consultingService = arrConsultingService[i];
              Discounts? maxDiscount;
              if ((consultingService.discounts?.length ?? 0) > 0)
                maxDiscount = consultingService.discounts
                    ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

              final timingMap = getServicesMinMaxTimings(consultingService.timings);

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


                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// BUSINESS LOGO + NAME
                      Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: consultingService.providerDetails?.profileImage==null?null: NetworkImage(
                              consultingService.providerDetails?.profileImage ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              consultingService.providerDetails?.name ?? "",
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
                              child: CustomImageSlideshow(
                                isLoading: false,
                                width: double.infinity,
                                height: 110,
                                imagePaths: consultingService.photos ?? [],
                                borderRadius: BorderRadius.circular(10),
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
                                    //  Name
                                    CustomText(
                                      consultingService.title ?? AppStrings.na,
                                      fontSize: SizeConfig.size12,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    // const SizedBox(height: 4),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: CustomText(
                                              consultingService.providerDetails?.location,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              fontSize: SizeConfig.extraSmall,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // price
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CustomText(
                                              AppStrings.pricePrefix,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor
                                          ),

                                          CustomText(
                                              "₹${consultingService.priceRange?.min} - ₹${consultingService.priceRange?.max}",
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryColor
                                          ),
                                          const SizedBox(width: 6),
                                          CustomText(
                                              (maxDiscount?.amountOff != null)
                                                  ? "${maxDiscount?.amountOff.toString()}% ${AppStrings.off.tr}"
                                                  : "0% ${AppStrings.off.tr}",
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.green.shade600
                                          ),
                                          const SizedBox(width: 6),
                                          CustomText(
                                              "₹${consultingService.priceRange?.max}",
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor,
                                              decoration: TextDecoration.lineThrough
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: SizeConfig.size3),

                                    // Open | close
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CustomText(
                                              "${AppStrings.open.tr}: ",
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.green39
                                          ),

                                          CustomText(
                                              timingMap["start"]!,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor
                                          ),

                                          CustomText(
                                              "  |  ",
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor
                                          ),


                                          CustomText(
                                              "${AppStrings.close.tr}: ",
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.red
                                          ),

                                          CustomText(
                                              timingMap["end"]!,
                                              fontSize: SizeConfig.small,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: SizeConfig.size4),


                                  ],
                                ),
                              ),
                            ),

                            const Divider(height: 1,color: Colors.grey,),

                            Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final chatViewController = Get.find<ChatViewController>();
                                      Map<String, dynamic> detas = {
                                        ApiKeys.user_id: consultingService.providerDetails?.id
                                      };

                                      Map<String,dynamic>? userDetailsMap=  await chatViewController.checkChatConnection(detas);
                                      if(userDetailsMap!=null){
                                        List<Map<String, String>>? urlList;
                                        if( consultingService.photos?.isNotEmpty??false){
                                          urlList= consultingService.photos?.map((e) => {ApiKeys.url: e}).toList()??[];
                                        }

                                        final conversationId = userDetailsMap[ApiKeys.conversation_id];

                                        final hasConversation = conversationId != null &&
                                            conversationId.toString().isNotEmpty &&
                                            conversationId.toString().toLowerCase() != 'null';
                                        Map<String,dynamic> data={
                                          ApiKeys.service_id : "${consultingService.id}",
                                          ApiKeys.price: "₹${consultingService.priceRange?.min} - ₹${consultingService.priceRange?.max}",
                                          ApiKeys.discount: (maxDiscount?.amountOff != null)
                                              ? "${maxDiscount?.amountOff.toString()}% ${AppStrings.off.tr}"
                                              : "0% ${AppStrings.off.tr}",
                                          if(!hasConversation)
                                            ApiKeys.other_user_id: (userDetailsMap[ApiKeys.other_user_id] ??
                                                '')
                                          else
                                            ApiKeys.conversation_id:(userDetailsMap[ApiKeys.conversation_id] ??
                                                ''),

                                          ApiKeys.message: "${consultingService.title }",
                                          ApiKeys.message_type: AppConstants.service,
                                          ApiKeys.title: "${consultingService.title}" ,
                                          ApiKeys.sub_category : "${consultingService.description}",
                                          ApiKeys.variant : "",

                                          ApiKeys.url: urlList??[],
                                        };
                                        chatViewController.checkChatConnectionAndOpenChat(
                                          userId: "${consultingService.providerDetails?.id}",
                                          shareProductParams: data,
                                          isWithProductSend: true,
                                        );
                                      }
                                    },
                                    icon: LocalAssets(
                                        imagePath: AppIconAssets.chat,
                                        imgColor: AppColors.primaryColor
                                    ),
                                    label: CustomText(
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
          if (arrConsultingService.length > 6)
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
}
