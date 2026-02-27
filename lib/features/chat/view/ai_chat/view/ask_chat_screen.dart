import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_chat_screen.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../widget/component_widgets.dart';

class AskChatScreen extends StatefulWidget {
  AskChatScreen(
      {required this.conversationId,
        required this.userId,
        required this.businessId,
        this.profileImage,
        required this.type,
        this.name,
        this.contactNo,
        required this.isInitialMessage,
        });

  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? businessId;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;

  @override
  State<AskChatScreen> createState() => _AskChatScreenState();
}

class _AskChatScreenState extends State<AskChatScreen> {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.fillColor,
        appBar: (chatThemeController.isMessageSelectionActive.value &&
            widget.type != AppStrings.Admin)
            ? getChatOptionsAppBar(
            context,
            profileImage: widget.profileImage,
            editingController: editingController,
            conversationId: widget.conversationId,
            userId: widget.userId,
           )
            : getChatTitleAppBar(
            socketType:AppConstants.personal,
            context,
            userId: widget.userId,
            type: widget.type,
            name: widget.name,
            profileImage: widget.profileImage,
            contactNo: widget.contactNo, conversationId: widget.conversationId),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImageAssets.chating_bg,
              fit: BoxFit.cover,
              width: SizeConfig.screenWidth,
              height: SizeConfig.screenHeight,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  CustomText(
                      'Sarthi Ai',
                      fontSize: SizeConfig.extraLarge,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500
                  ),
                  SizedBox(height: SizeConfig.paddingXSL),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:  AppColors.white, width: 3),
                    ),
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      height: SizeConfig.size90,
                      width: SizeConfig.size90,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryColor.withValues(alpha: 0.02),
                                AppColors.primaryColor.withValues(alpha: 0.3),
                              ])
                      ),
                      child: LocalAssets(
                        imagePath: AppImageAssets.sampleGirlImage,
                        boxFix: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.paddingS),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: CustomText(
                        'Hi! What Are You Looking For?',
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  SizedBox(height: SizeConfig.paddingL),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: AppColors.white, width: 1.5
                          ),
                        ),
                        child: MasonryGridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: chatViewController.arrAskForOptions.length,
                          primary: false,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            var items = chatViewController.arrAskForOptions[index];
                            return CommonServiceCard(
                              service: items,
                              iconHeight: SizeConfig.size55,
                              getName: (item) => item.name,
                              getIcon: (item) => item.icon,
                              onTap: (_) {
                                chatViewController.askAiFor.value = items;
                                switch(chatViewController.askAiFor.value?.slugId){
                                  case PRODUCT:
                                    final chat = ChatViewController.inventoryAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askInventory_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case FOOD:
                                    final chat = ChatViewController.foodAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askFood_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case SERVICE:
                                    final chat = ChatViewController.serviceAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askService_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case HEALTHCARE_MEDICAL_SERVICES:
                                    final chat = ChatViewController.healthCareAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askHealthCare_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case EDUCATION_TRAINING:
                                    final chat = ChatViewController.educationAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askEducation_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case HOME_SERVICES:
                                    final chat = ChatViewController.homeServiceAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askHomeService_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case RENTAL_SERVICES:
                                    final chat = ChatViewController.travelAndStayAiChatListSearchModule;
                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askTravelStay_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case PROFESSIONAL:
                                    final chat = ChatViewController.consultingTalkAiChatListSearchModule;

                                    Get.to(() => AiCommonSearchScreen(
                                      chatType: AppConstants.askConsultingTalk_Chat_Type,
                                      profileImage: chat?.sender?.profileImage,
                                      name: chat?.sender?.name,
                                      contactNo: chat?.sender?.contactNo,
                                      conversationId: '',
                                      userId: '',
                                      businessId: '',
                                      type: chat?.sender?.accountType,
                                      isInitialMessage: false,
                                    ));
                                    break;
                                  case 'LETS_TALK':
                                    final chat= ChatViewController.businessAiChatModule;
                                    Get.to(()=> AiChatScreen(
                                        profileImage: chat?.sender?.profileImage,
                                        name: chat?.sender?.name,
                                        type: chat?.sender?.accountType,
                                    ));
                                    break;
                                  default:
                                    break;
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }


}
