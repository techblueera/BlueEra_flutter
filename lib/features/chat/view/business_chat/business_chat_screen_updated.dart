import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_foods.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_products.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_services.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/notification_utils.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
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
      this.profileImage,
      required this.type,
      this.name,
      this.contactNo,
      required this.isInitialMessage,
      this.prefilledMessage});

  final String? conversationId;
  final String? userId;
  final String? profileImage;

  final String? name;
  final String? type;
  final bool isInitialMessage;
  final String? contactNo;
  /// Optional intro text seeded into the input field on first open. Applied
  /// inside the post-frame callback so it survives the `clear()` there.
  final String? prefilledMessage;

  @override
  State<BusinessChatScreenUpdated> createState() =>
      _BusinessChatScreenUpdatedState();
}

class _BusinessChatScreenUpdatedState extends State<BusinessChatScreenUpdated>
    with WidgetsBindingObserver {
  final chatViewController = getOrPut(() => ChatViewController());
  final bottomBarController = getOrPut(() => BottomBarController());
  final chatThemeController = getOrPut(() => ChatThemeController());

  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {

    WidgetsBinding.instance.addPostFrameCallback((value){
      chatViewController.isChatFromBusinessProfile(true);
      chatViewController.sendMessageController.value.clear();
      chatViewController.isTextFieldEmpty.value = false;
      final prefill = widget.prefilledMessage;
      if (prefill != null && prefill.isNotEmpty) {
        chatViewController.sendMessageController.value.text = prefill;
        // `isTextFieldEmpty` is inverted in this codebase: `true` means the
        // field HAS text, which is what flips the mic icon to send.
        chatViewController.isTextFieldEmpty.value = true;
      }
      chatViewController.listenUserNewMessages(
          userId: widget.userId ?? "",
          conversationId: widget.conversationId ?? '');
      chatThemeController.resetSelection();

      // Bump the message page size by 30 whenever the user scrolls to the top
      // of the (reverse:true) list so older history streams in on demand.
      chatViewController.scrollController.addListener(_onScroll);

      checkPendingMessages();
    });

    // On Android, CallActivity runs in a separate task and pauses the chat's
    // Flutter engine. Once the user returns, pull the latest messages so the
    // just-created call record shows up without the user having to leave and
    // re-open the chat.
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final id = widget.conversationId ?? '';
      if (id.isEmpty) return;
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: id,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: chatViewController.userOpenUserId.value,
        ApiKeys.per_page_message: 30,
      });
    }
  }

  void _onScroll() {
    final controller = chatViewController.scrollController;
    if (!controller.hasClients) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 80) {
      chatViewController.loadMoreMessages();
    }
  }

  Future<void> checkPendingMessages() async {
    final connectivityResult = await NetworkUtils.isConnected();
    if (!connectivityResult) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chatViewController.scrollController.removeListener(_onScroll);
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (val)  {
        chatViewController.leaveConversation();
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"},);
        } else {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"},);
        }
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          appBar: (chatThemeController.isMessageSelectionActive.value &&
                  widget.type != "Admin")
              ? getChatOptionsAppBar(
                  context,
                  profileImage: widget.profileImage,
                  editingController: editingController,
                  conversationId: widget.conversationId,
                  userId: widget.userId,

                )
              : getChatTitleAppBar(
                  socketType: "business",
                  context,
                  userId: widget.userId,
                  type: widget.type,
                  name: widget.name,
                  contactNo: widget.contactNo,
                  profileImage: widget.profileImage,
                  conversationId: widget.conversationId,
                ),
          body: Obx(() {
            final _status =
                chatViewController.getListOfMessageResponse.value.status;
            List<Messages> messages =
                chatViewController.getListOfMessageData ?? [];
            // Show the body as soon as cached history is available; only fall
            // back to the spinner when there is truly nothing to paint yet.
            // This keeps the offline chat screen populated from Hive.
            if (messages.isNotEmpty || _status == Status.COMPLETE) {
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
                    Obx(() => chatThemeController.chatBackground()),
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
                                : ListView.builder(
                                    controller: chatViewController.scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[messages.length - 1 - index];
                                      return MessageCard(
                                        message: message,
                                        isInitialMessage: widget.isInitialMessage,
                                        conversationId: widget.conversationId,
                                        userId: widget.userId,
                                        name: widget.name,
                                        contactNo: widget.contactNo,
                                        profileImage: widget.profileImage,
                                        conversationName: widget.name,
                                        conversationProfileImage: widget.profileImage,
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
                                  child: BusinessChatServices(
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
                  Obx(() => chatThemeController.chatBackground()),
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

}
