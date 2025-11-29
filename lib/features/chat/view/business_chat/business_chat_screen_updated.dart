import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_foods.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_products.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_services.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../../core/services/notification_utils.dart';
import '../../../common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import '../../../common/feed/view/feed_screen.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/chat_input_box.dart';
import '../widget/component_widgets.dart';
import '../widget/message_card.dart';

class BusinessChatScreenUpdated extends StatefulWidget {
  BusinessChatScreenUpdated(
      {required this.conversationId,
      required this.userId,
      required this.businessId,
      this.profileImage,
      required this.type,
      this.name,
      this.contactNo,
      required this.isInitialMessage});

  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? businessId;
  final String? name;
  final String? type;
  final bool isInitialMessage;
  final String? contactNo;

  @override
  State<BusinessChatScreenUpdated> createState() =>
      _BusinessChatScreenUpdatedState();
}

class _BusinessChatScreenUpdatedState extends State<BusinessChatScreenUpdated> {
  final Color sentMessageColor = Color(0xFF007AFF);

  final Color receivedMessageColor = Color(0xFFECECEC);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    chatViewController.isChatFromBusinessProfile(true);
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatViewController.listenUserNewMessages(
        userId: widget.userId ?? "",
        conversationId: widget.conversationId ?? '');
    chatThemeController.resetSelection();

    checkPendingMessages();
    super.initState();
  }

  Future<void> checkPendingMessages() async {
    final connectivityResult = await NetworkUtils.isConnected();
    if (!connectivityResult) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  void launchDialPad(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch dialer';
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"}, true);
          chatViewController.onSelectChatTab(1);
          bottomBarController.onChangeIndex(4);
          Navigator.popUntil(
              context,
              ModalRoute.withName(
                  RouteHelper.getBottomNavigationBarScreenRoute()));
        } else {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"}, true);
        }
        return true;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: (chatThemeController.isMessageSelectionActive.value &&
                  widget.type != "Admin")
              ? getChatOptionsAppBar(
                  context,
                  profileImage: widget.profileImage,
                  editingController: editingController,
                  conversationId: widget.conversationId,
                  userId: widget.userId,
                  type: widget.type,
                  name: widget.name,
                  contactNo: widget.contactNo,
                )
              : getChatTitleAppBar(
                  socketType: "business",
                  context,
                  userId: widget.userId,
                  // userId: widget.userId,
                  type: widget.type,
                  name: widget.name,
                  contactNo: widget.contactNo,
                  businessId: widget.businessId,
                  profileImage: widget.profileImage,
                  conversationId: widget.conversationId,
                ),
          body: Obx(() {
            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              List<Messages> messages =
                  chatViewController.getListOfMessageData ?? [];
              messages.sort((a, b) {
                final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
                    ? DateTime.parse(a.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
                    ? DateTime.parse(b.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return dateA.compareTo(dateB); // descending
              });
              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        AppImageAssets.chating_bg,
                        fit: BoxFit.cover,
                        width: SizeConfig.screenWidth,
                        height: SizeConfig.screenHeight,
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          height: 42,
                          padding: EdgeInsets.only(left: 10, right: 6),
                          margin: EdgeInsets.only(top: 8, bottom: 4),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: chatViewController.tabs.length,
                            separatorBuilder: (_, __) => SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              return Obx(() {
                                final selected = index ==
                                    chatViewController
                                        .businessTabIndexSelected.value;
                                return InkWell(
                                  onTap: () {
                                    chatViewController
                                        .changeBusinessInsideTab(index);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 3),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryColor
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: selected
                                          ? null
                                          : Border.all(
                                              color: AppColors.borderBox
                                                  .withOpacity(0.75)),
                                    ),
                                    child: Center(
                                      child: CustomText(
                                        chatViewController.tabs[index],
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.grayText,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                        if (chatViewController.businessTabIndexSelected == 0)
                          Expanded(
                            child: (messages.isEmpty)
                                ? Center(
                                    child: InkWell(
                                      onTap: () {
                                        Map<String, dynamic> data = {
                                          ApiKeys.other_user_id: widget.userId,
                                          ApiKeys.message: "Namaste 🙏",
                                          ApiKeys.message_type: "text",
                                        };
                                        chatViewController
                                            .sendInitialMessage(data);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.5),
                                          // light color with 0.5 opacity
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:AppStrings.noConversationYet.tr,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.sayNamaste.tr,
                                                style: TextStyle(
                                                  color: Colors
                                                      .blue, // blue from theme
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: IntrinsicHeight(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: SingleChildScrollView(
                                              padding: EdgeInsets.zero,
                                              controller: chatViewController
                                                  .scrollController,
                                              reverse: true,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children:
                                                    messages.map((message) {
                                                  return MessageCard(
                                                    message: message,
                                                    isInitialMessage:
                                                        widget.isInitialMessage,
                                                    conversationId:
                                                        widget.conversationId,
                                                    userId: widget.userId,
                                                    name: widget.name,
                                                    contactNo: widget.contactNo,
                                                    profileImage:
                                                        widget.profileImage,
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          )
                        else if (chatViewController.businessTabIndexSelected ==
                            1)
                          Expanded(child:
                              LayoutBuilder(builder: (context, constraints) {
                            return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, bottom: 0),
                                  child: BusinessChatProducts(
                                    conversationId: widget.conversationId ?? '',
                                    businessId: widget.userId ?? '',
                                  ),
                                ));
                          }))
                        else if (chatViewController.businessTabIndexSelected ==
                            2)
                          Expanded(child:
                              LayoutBuilder(builder: (context, constraints) {
                            return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, bottom: 0),
                                  child: BusinessChatFoods(
                                    businessId: widget.userId ?? '',
                                    conversationId: '${widget.conversationId}',
                                  ),
                                ));
                          }))
                        else if (chatViewController.businessTabIndexSelected ==
                            3)
                          Expanded(child:
                              LayoutBuilder(builder: (context, constraints) {
                            return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, bottom: 0),
                                  child:
                                      //BusinessChatFoods
                                      BusinessChatServices(
                                    businessId: widget.userId ?? '',
                                  ),
                                ));
                          }))
                        else if (chatViewController.businessTabIndexSelected ==
                            4)
                          Expanded(
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 0),
                                    child: FeedScreen(
                                        key: ValueKey(
                                            'feedScreen_user_posts_${widget.userId}'),
                                        postFilterType: PostType.otherPosts,
                                        isInParentScroll: false,
                                        bottomPaddingChannel: 20,
                                        id: widget.userId),
                                  ));
                            }),
                          )
                        else if (chatViewController.businessTabIndexSelected ==
                            5)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 38.0),
                            child: Center(
                              child: CustomText(AppStrings.noReviewsFound),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 38.0),
                            child: Center(
                              child: CustomText("Coming Soon"),
                            ),
                          ),
                        if (chatViewController.businessTabIndexSelected == 0)
                          SizedBox(
                            height: SizeConfig.size6,
                          ),
                        if (chatViewController.businessTabIndexSelected == 0)
                          ChatInputBar(
                            isInitialMessage: widget.isInitialMessage,
                            userId: widget.userId ?? '',
                            conversationId: widget.conversationId ?? '',
                          ),
                        if (chatViewController.businessTabIndexSelected == 0)
                          SizedBox(height: SizeConfig.size14)
                        else
                          SizedBox(height: SizeConfig.size6)
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return SafeArea(
                  child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppImageAssets.chating_bg,
                    fit: BoxFit.cover,
                    width: SizeConfig.screenWidth,
                    height: SizeConfig.screenHeight,
                  ),
                  Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(),
                    ),
                  )
                ],
              ));
            }
          }),
        );
      }),
    );
  }

  void showMessageEditDialog() {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(vertical: 12),
        // Reduced outer spacing
        contentPadding: const EdgeInsets.only(bottom: 10),
        backgroundColor: AppColors.appBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.message,
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: AppColors.greyB4),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextFormField(
                controller: editingController,
                maxLines: 6,
                minLines: 6,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText:AppStrings.typeMessage.tr,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    child: CustomText(
                      AppStrings.close,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () async {
                      ApiKeys;
                      Map<String, dynamic> data = {
                        ApiKeys.id:
                            "${chatThemeController.selectedFirstMessage?.value?.id}",
                        ApiKeys.type: "message",
                        ApiKeys.message: "${editingController.text}"
                      };
                      bool value =
                          await chatViewController.updateMessageApi(data);
                      if (value) {
                        chatViewController
                            .emitEvent(ChatEmitEvents.messageReceived, {
                          ApiKeys.conversation_id: widget.conversationId,
                          ApiKeys.page: 1,
                          ApiKeys.is_online_user: widget.userId,
                          ApiKeys.per_page_message: 30,
                        });
                        chatThemeController.resetSelection();
                        Get.back();
                      }
                    },
                    child: CustomText(
                      AppStrings.edit,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      useSafeArea: true,
    );
  }
}
