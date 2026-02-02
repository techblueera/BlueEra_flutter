import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/health_care_ask_ai_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_box_shadow.dart';

class AskHealthCareMsgCard extends StatelessWidget {
  final HealthCareAskAiModel response;

  AskHealthCareMsgCard({Key? key, required this.response}) : super(key: key);

  final chatThemeController = getOrPut(() => ChatThemeController());


  @override
  Widget build(BuildContext context) {
    final arrHealthCareData = response.data?.healthCareData ?? [];

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
            itemCount: arrHealthCareData.length > 6 ? 6 : arrHealthCareData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 320,
            ),
            itemBuilder: (_, i) {
              final healthCareData = arrHealthCareData[i];
              final hospitalInfo = healthCareData.hospitalInfo;
              final businessDetails = healthCareData.businessDetails;

              final distance = calculateDistance(
                  businessDetails?.business?.businessLocation?.lat ?? 0.0,
                  businessDetails?.business?.businessLocation?.lon ?? 0.0);

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
                            backgroundImage: businessDetails?.business?.logo==null?null: NetworkImage(
                              healthCareData.photo ?? "",
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              businessDetails?.business?.businessName ?? "",
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
                              child:  CustomImageSlideshow(
                                isLoading: false,
                                width: double.infinity,
                                height: 110,
                                imagePaths: [healthCareData.photo ?? ''],
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
                                    // Hospital Name
                                    CustomText(
                                      hospitalInfo?.hospitalName,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    CustomText(
                                      businessDetails?.business?.subCategoryOfBusiness?.name??'',
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),

                                    _buildItem(
                                        Icons.location_on_outlined,
                                        hospitalInfo?.address ?? AppStrings.na,
                                        maxLines: 2
                                    ),

                                    // Distance
                                    _buildItem(
                                      Icons.near_me_outlined,
                                      distance!=null
                                          ? "${distance.toStringAsFixed(2)} KM"
                                          : AppStrings.na,
                                    ),

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
                                    onPressed: () async{
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
          if (arrHealthCareData.length > 6)
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
