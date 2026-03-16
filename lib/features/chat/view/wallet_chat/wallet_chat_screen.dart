import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/chat_input_box.dart';
import '../widget/component_widgets.dart';
import '../widget/message_card.dart';

/// Hive-based storage for wallet self-conversation ID.
class WalletChatStorage {
  static const String _boxName = "walletChatBox";
  static const String _key = "walletConversationId";

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  static Future<void> saveConversationId(String id) async {
    final box = await _openBox();
    await box.put(_key, id);
  }

  static Future<String?> getConversationId() async {
    final box = await _openBox();
    return box.get(_key);
  }

  static Future<void> clearConversationId() async {
    final box = await _openBox();
    await box.delete(_key);
  }
}

class WalletChatScreen extends StatefulWidget {
  const WalletChatScreen({super.key});

  @override
  State<WalletChatScreen> createState() => _WalletChatScreenState();
}

class _WalletChatScreenState extends State<WalletChatScreen> {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController = TextEditingController();

  String _conversationId = '';
  bool _isInitialMessage = true;

  @override
  void initState() {
    super.initState();
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatThemeController.resetSelection();
    _initWalletChat();
  }

  /// Load saved conversationId from Hive.
  /// If exists → emit messageReceived to fetch history.
  /// If not → mark as initial message (first send will create conversation).
  Future<void> _initWalletChat() async {
    final savedId = await WalletChatStorage.getConversationId();

    if (savedId != null && savedId.isNotEmpty) {
      _conversationId = savedId;
      _isInitialMessage = false;

      // Listen for new messages on this conversation
      chatViewController.listenUserNewMessages(
        userId: userId, // self user ID
        conversationId: _conversationId,
      );

      // Fetch message history via socket
      chatViewController.emitEvent(
        ChatEmitEvents.messageReceived,
        {
          ApiKeys.conversation_id: _conversationId,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userId,
          ApiKeys.per_page_message: 30,
        },
      );

      _checkPendingMessages();
    } else {
      // No conversation yet — will be created on first message
      _isInitialMessage = true;
      chatViewController.getListOfMessageData?.clear();
      chatViewController.getListOfMessageResponse.value =
          ApiResponse.complete(chatViewController.getListOfMessageData);
    }
  }

  Future<void> _checkPendingMessages() async {
    final connected = await NetworkUtils.isConnected();
    if (!connected) {
      chatViewController.sendOfflineMessage(_conversationId);
    }
  }

  /// Send the initial "Namaste" message (self-conversation).
  /// After success, save the conversationId from the response.
  Future<void> _sendInitialNamaste() async {
    Map<String, dynamic> data = {
      ApiKeys.other_user_id: userId, // self → self conversation
      ApiKeys.message: "Namaste \u{1F64F}",
      ApiKeys.message_type: "text",
    };

    await chatViewController.sendInitialMessage(data);

    // Extract conversationId from the newly added message
    final messages = chatViewController.getListOfMessageData;
    if (messages != null && messages.isNotEmpty) {
      final newConvId = messages.last.conversationId ?? '';
      if (newConvId.isNotEmpty) {
        _conversationId = newConvId;
        _isInitialMessage = false;
        await WalletChatStorage.saveConversationId(newConvId);

        // Now listen on this conversation for real-time updates
        chatViewController.listenUserNewMessages(
          userId: userId,
          conversationId: _conversationId,
        );
      }
    }
  }

  @override
  void dispose() {
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.personal_Chat_Type},
        );
        chatViewController.emitEvent(
          ChatEmitEvents.newMessageReceived,
          {ApiKeys.type: AppConstants.personal_Chat_Type},
        );
        return true;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: AppColors.fillColor,
          appBar: (chatThemeController.isMessageSelectionActive.value)
              ? getChatOptionsAppBar(
                  context,
                  profileImage: null,
                  editingController: editingController,
                  conversationId: _conversationId,
                  userId: userId,
                )
              : _buildWalletAppBar(context),
          body: Obx(() {
            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              List<Messages> messages =
                  chatViewController.getListOfMessageData ?? [];
              messages.sort((a, b) {
                final dateA =
                    (a.createdAt != null && a.createdAt!.isNotEmpty)
                        ? DateTime.parse(a.createdAt!).toLocal()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                final dateB =
                    (b.createdAt != null && b.createdAt!.isNotEmpty)
                        ? DateTime.parse(b.createdAt!).toLocal()
                        : DateTime.fromMillisecondsSinceEpoch(0);
                return dateA.compareTo(dateB);
              });

              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Obx(() => chatThemeController.chatBackground()),
                    Column(
                      children: [
                        Expanded(
                          child: (messages.isEmpty)
                              ? _buildEmptyState()
                              : ListView.builder(
                                  controller:
                                      chatViewController.scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message =
                                        messages[messages.length - 1 - index];
                                    return MessageCard(
                                      message: message,
                                      isInitialMessage: false,
                                      conversationId: message.conversationId,
                                      userId: message.sender?.id,
                                      name: message.sender?.name,
                                      contactNo: message.sender?.contactNo,
                                      profileImage:
                                          message.sender?.profileImage,
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 6),
                        ChatInputBar(
                          isInitialMessage: _isInitialMessage,
                          userId: userId,
                          conversationId: _conversationId,
                        ),
                        const SizedBox(height: 14),
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
                    const Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: InkWell(
        onTap: _sendInitialNamaste,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Wallet Space",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Tap to say ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: "Namaste \u{1F64F}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildWalletAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: 38,
      leading: InkWell(
        onTap: () {
          chatViewController.emitEvent(
            ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.personal_Chat_Type},
          );
          Get.back();
        },
        child: Padding(
          padding: EdgeInsets.only(left: 18),
          child: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.blueLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Notes to self',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
