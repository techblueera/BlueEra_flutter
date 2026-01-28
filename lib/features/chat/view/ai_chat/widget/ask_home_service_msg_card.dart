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

class AskHomeServiceMsgCard extends StatelessWidget {
  final ServiceAskAiModel response;

   AskHomeServiceMsgCard({super.key, required this.response});

  final chatThemeController = getOrPut(() => ChatThemeController());

  @override
  Widget build(BuildContext context) {
    final arrHomeService = response.data?.serviceModel ?? [];

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
            itemCount: arrHomeService.length > 6 ? 6 : arrHomeService.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 290,
            ),
            itemBuilder: (_, i) {
              final homeServices = arrHomeService[i];

              Discounts? maxDiscount;
              if ((homeServices.discounts?.length ?? 0) > 0)
                maxDiscount = homeServices.discounts
                    ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

              final timingMap = getServicesMinMaxTimings(homeServices.timings);

              return InkWell(
                onTap: () {
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
                            backgroundImage: homeServices.providerDetails?.profileImage==null?null: NetworkImage(
                              homeServices.providerDetails?.profileImage ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              homeServices.providerDetails?.name ?? "",
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
                                imagePaths: homeServices.photos ?? [],
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
                                      homeServices.title ?? AppStrings.na,
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
                                              homeServices.providerDetails?.location,
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
                                              "₹${homeServices.priceRange?.min} - ₹${homeServices.priceRange?.max}",
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
                                              "₹${homeServices.priceRange?.max}",
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
                                      // final chatViewController = Get.find<ChatViewController>();
                                      // Map<String, dynamic> detas = {
                                      //   ApiKeys.user_id: business?.user_id
                                      // };
                                      // chatViewController.newVisitContactApiResponse?.value;
                                      // await chatViewController.checkChatConnection(detas);
                                      // List<Map<String, String>>? urlList =
                                      // product?.media.map((e) => {"url": e}).toList();
                                      // Map<String, dynamic> data = {
                                      //   ApiKeys.product_id:"${product?.id}",
                                      //
                                      //   ApiKeys.price: "${product?.mrpPerUnit}",
                                      //   ApiKeys.discount: "",
                                      //   if ((chatViewController.newVisitContactApiResponse
                                      //       ?.value?.data?.conversationId ==
                                      //       '' ||
                                      //       chatViewController.newVisitContactApiResponse
                                      //           ?.value?.data?.conversationId ==
                                      //           null))
                                      //     ApiKeys.other_user_id: (chatViewController
                                      //         .newVisitContactApiResponse
                                      //         ?.value
                                      //         ?.data
                                      //         ?.otherUserId ??
                                      //         '')
                                      //   else
                                      //     ApiKeys.conversation_id: (chatViewController
                                      //         .newVisitContactApiResponse
                                      //         ?.value
                                      //         ?.data
                                      //         ?.conversationId ??
                                      //         ''),
                                      //   ApiKeys.message:
                                      //   "${product?.name}",
                                      //   ApiKeys.message_type: "product",
                                      //   ApiKeys.title: product?.name,
                                      //   ApiKeys.mrp :'',
                                      //   ApiKeys.url: urlList,
                                      // };
                                      // chatViewController.
                                      // openAnyOneChatFunction(
                                      //   shareProductParams: data,
                                      //   isWithProductSend: true,
                                      //   profileImage: business?.business_logo,
                                      //   otherUserId: (chatViewController.newVisitContactApiResponse
                                      //       ?.value?.data?.conversationId ??
                                      //       '') ==
                                      //       ""
                                      //       ? chatViewController.newVisitContactApiResponse?.value
                                      //       ?.data?.otherUserId ??
                                      //       ''
                                      //       : null,
                                      //   // businessId: widget
                                      //   //     .productStore?.sellerClassification?.owner?.id,
                                      //   type: AppConstants.business_Chat_Type,
                                      //   isInitialMessage: (chatViewController
                                      //       .newVisitContactApiResponse
                                      //       ?.value
                                      //       ?.data
                                      //       ?.conversationId ??
                                      //       '') ==
                                      //       ""
                                      //       ? true
                                      //       : false,
                                      //   userId: business?.user_id,
                                      //   conversationId: (chatViewController
                                      //       .newVisitContactApiResponse
                                      //       ?.value
                                      //       ?.data
                                      //       ?.conversationId ??
                                      //       ''),
                                      //   contactName: business?.business_name,
                                      //   contactNo: business?.mobile_no,
                                      // );
                                    },
                                    icon: LocalAssets(
                                        imagePath: AppIconAssets.chat,
                                        imgColor: AppColors.primaryColor
                                    ),
                                    label: CustomText(
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
          if (arrHomeService.length > 6)
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
}
