import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';

import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/repo/chat_view_repo.dart';
import '../../auth/model/GetChatListModel.dart';
import '../business_chat/business_chat_list.dart';
import '../widget/component_widgets.dart';
import '../add_symbol/add_symbol_screen.dart';
import '../personal_chat/personal_chat_list.dart';

class ChatForwardScreen extends StatefulWidget {
  const ChatForwardScreen({super.key, this.sharedText, this.sharedFiles, this.maxSelectionCount, this.stopChatNav, this.documentFilePath});
  final String? sharedText;
  final List<SharedAttachment?>? sharedFiles;
  final int? maxSelectionCount;
  final bool? stopChatNav;

  /// Local path of a generated document (e.g. a packing-list PDF) to forward as
  /// a `document` chat message to each selected conversation. When set, the
  /// forward action sends this file instead of forwarding selected messages.
  final String? documentFilePath;

  @override
  State<ChatForwardScreen> createState() => _ChatForwardScreenState();
}

class _ChatForwardScreenState extends State<ChatForwardScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
 bool symbolSelected=false;
 bool _isSending = false;
  final bottomBarController = getOrPut(() => BottomBarController());

  // Inline local search of the conversations shown on this screen.
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    chatViewController.selectedUserIds.clear();
    chatViewController.selectedChatList.clear();
    // Make sure the business chat list is available so the "Recent Inquiry"
    // section can show the latest 4 business conversations.
    if (chatViewController.businessChatListResponse.value.status !=
        Status.COMPLETE) {
      chatViewController.emitEvent(
          ChatEmitEvents.ChatList, {ApiKeys.type: "business"});
    }
    // Personal chats power the recent list + local search results.
    if (chatViewController.personalChatListResponse.value.status !=
        Status.COMPLETE) {
      chatViewController.emitEvent(
          ChatEmitEvents.ChatList, {ApiKeys.type: "personal"});
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Sends the document at [filePath] as a `document` chat message to every
  /// conversation the user selected on this screen. Posts straight through the
  /// repo (not [ChatViewController.sendMessage]) so the file is delivered to the
  /// recipients without being optimistically appended to the chat we forwarded
  /// from — otherwise it would briefly appear as a sent message in our own
  /// (unrelated) open chat. A fresh MultipartFile is built per recipient because
  /// its byte stream is consumed once per send.
  Future<void> _sendDocumentToSelected(String filePath) async {
    final fileName = filePath.split('/').last;
    final repo = ChatViewRepo();
    for (final chat in chatViewController.selectedChatList) {
      final recipientId = chat?.sender?.id ?? '';
      final convId = chat?.conversationId ?? '';
      if (recipientId.isEmpty && convId.isEmpty) continue;

      final multipartFile = await dio.MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );
      final data = <String, dynamic>{
        ApiKeys.conversation_id: convId,
        ApiKeys.other_user_id: recipientId,
        ApiKeys.message: '',
        ApiKeys.message_type: 'document',
        ApiKeys.files: [multipartFile],
      };
      await repo.sendMessageToUser(data);
    }
    chatViewController.emitEvent(
        ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        isShadowShow: false,
        title: AppStrings.forwardTo.tr,
        isForwardUi: true,
        onForwardSearchTap: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchCtrl.clear();
              _query = '';
            }
          });
        },
      ),
      // AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   leading: const BackButton(color: Colors.black),
      //   title: const Text(
      //     "Forward to...",
      //     style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      //   ),
      //   actions: const [
      //     Icon(Icons.person_add_alt, color: Colors.black),
      //     SizedBox(width: 16),
      //     Icon(Icons.search, color: Colors.black),
      //     SizedBox(width: 12),
      //   ],
      // ),
      body: Column(
        children: [
          if (_isSearching) _searchField(),
          Expanded(
            child: SingleChildScrollView(
              child: _isSearching
                  ? _searchResults()
                  : Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topOptions(),
                  _recentInquiries(),
                  _sectionTitle(AppStrings.recentChatsLabel.tr),
                  PersonalChatsList(isForwardUI: true),
                ],
              ),
            ),
          ),
          Obx(() {
            return _bottomMessageBar();
          }),
        ],
      ),
    );
  }

  /// Inline search box shown under the app bar when the search icon is tapped.
  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: AppStrings.searchConversations.tr,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _query = '';
                  }),
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Local search results: business "inquiry" + personal conversations on this
  /// screen, deduped by conversation and filtered by name. Each row stays
  /// selectable for forwarding.
  Widget _searchResults() {
    final theme = Theme.of(context);
    final business =
        (chatViewController.getBusinessChatListModel?.value.chatList ?? [])
            .where((c) => c != null && bucketChat(c) == ChatBucket.chats);
    final personal =
        chatViewController.getPersonalChatListModel?.value.chatList ?? [];

    // Combine + dedup by conversationId (business inquiries first).
    final seen = <String>{};
    final combined = <ChatList?>[];
    for (final c in [...business, ...personal]) {
      final id = c?.conversationId ?? '';
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      combined.add(c);
    }

    final results = _query.isEmpty
        ? combined
        : combined.where((c) {
            final name = (c?.sender?.name ?? c?.groupName ?? '').toLowerCase();
            return name.contains(_query);
          }).toList();

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: CustomText(
            AppStrings.noChatsFound.tr,
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, i) {
        final chat = results[i];
        return ChatListTile(
          onSelect: () => setState(() {}),
          type: chat?.sender?.accountType ?? AppConstants.individual,
          index: i,
          chatViewController: chatViewController,
          chat: chat,
          theme: theme,
          isForwardUI: true,
          showFlagBadge: true,
          context: context,
        );
      },
    );
  }

  Widget _topOptions() {
    return Column(
      children: [
        _chatTile(
          name: AppStrings.mySymbolLabel.tr,
          subtitle: AppStrings.myContactsPlus.tr,
          icon: Icons.account_circle_rounded,
          isGreen: true,
        ),
        const Divider(height: 1),
      ],
    );
  }

  /// Latest 4 business conversations ("Recent Inquiry"), shown above the
  /// regular recent chats. Reuses [ChatListTile] in forward mode so each row
  /// is selectable for forwarding just like the recent chats below.
  Widget _recentInquiries() {
    return Obx(() {
      if (chatViewController.businessChatListResponse.value.status !=
          Status.COMPLETE) {
        return const SizedBox.shrink();
      }
      final all =
          chatViewController.getBusinessChatListModel?.value.chatList ?? [];
      // Same "chats" bucket the business list shows (excludes the seller's
      // own "me" orders), capped at the latest 4.
      final inquiries = all
          .where((c) => c != null && bucketChat(c) == ChatBucket.chats)
          .take(4)
          .toList();
      if (inquiries.isEmpty) return const SizedBox.shrink();

      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.recentInquiryLabel.tr),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: inquiries.length,
            itemBuilder: (context, i) {
              final chat = inquiries[i];
              return ChatListTile(
                onSelect: () => setState(() {}),
                type: chat?.sender?.accountType ?? AppConstants.business,
                index: i,
                chatViewController: chatViewController,
                chat: chat,
                theme: theme,
                isForwardUI: true,
                showFlagBadge: true,
                context: context,
              );
            },
          ),
          const Divider(height: 1),
        ],
      );
    });
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CustomText(
        title,
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _chatTile({
    required String name,
    String? subtitle,
    String? image,
    IconData? icon,
    bool isGreen = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isGreen ? Colors.green : Colors.grey.shade200,
        backgroundImage: image != null ? NetworkImage(image) : null,
        child: icon != null
            ? Icon(icon, color: isGreen ? Colors.white : Colors.black)
            : null,
      ),
      title: CustomText(
        name,
          fontSize: 16,
          fontWeight: FontWeight.w500,
      ),
      subtitle: subtitle != null
          ? CustomText(
        subtitle,
       color: Colors.grey, fontSize: 13
      )
          : null,
      trailing: Theme(
        data: theme.copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: Colors.black),
          ),
        ),
        child: Transform.scale(
          scale: 1.3, // 👈 increase this (1.2 – 1.8 recommended)
          child: Checkbox(
            activeColor: Colors.blue,
            checkColor: Colors.white,
            value: symbolSelected,
            onChanged: (_) {
              setState(() {
                symbolSelected=!symbolSelected;
              });
            },
          ),
        ),
      ),
      onTap: () {
        setState(() {
          symbolSelected=!symbolSelected;
        });
      },
    );
  }

  Widget _bottomMessageBar() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 35, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CommonTextField(
          //   hintText: "Add Message...",
          //   maxLine: 3,
          // ),
          InkWell(
            onTap: ()async{
              if (_isSending) return; // prevent double-tap
              _isSending = true;
              // Forward to selected contacts first (if any)
              if(chatViewController.selectedUserIds.isNotEmpty){
                if(widget.documentFilePath!=null){
                  // Send the generated PDF as a `document` message to each
                  // selected conversation (same payload as the chat input's
                  // document send — see SelfPickupMsgCard packing flow).
                  await _sendDocumentToSelected(widget.documentFilePath!);
                }else if(widget.sharedFiles!=null||widget.sharedText!=null){
                  if (widget.sharedText != null) {
                    for (final chat in chatViewController.selectedChatList) {
                      final recipientId = chat?.sender?.id ?? '';
                      final convId = chat?.conversationId ?? '';
                      if (recipientId.isEmpty) continue;

                      Map<String, dynamic> data = {
                        ApiKeys.conversation_id: convId,
                        ApiKeys.other_user_id: recipientId,
                        ApiKeys.message: "${widget.sharedText}",
                        ApiKeys.message_type: "text",
                      };
                      await chatViewController.sendMessage(data);
                    }
                    chatViewController.emitEvent(
                        ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.personal_Chat_Type});
                  }

                  if (widget.sharedFiles != null) {
                    List<String?> userIds= chatViewController.selectedChatList.map((e)=>e?.sender?.id).toList();
                    List<File> selectedFiles = [];
                    List<SharedAttachment?>? sharedList =
                        widget.sharedFiles;

                    if (sharedList != null && sharedList.isNotEmpty) {
                      selectedFiles = sharedList
                          .where((e) =>
                      e?.path != null && e!.path.isNotEmpty)
                          .map((e) => File(e!.path))
                          .toList();
                    }

                    List<String?> fileNames = [];
                    List<String?> fileTypes = [];
                    for (var file in selectedFiles) {
                      Map<String, String?> fileInfo = getFileInfo(file);
                      fileNames.add(fileInfo['fileName']);
                      fileTypes.add(fileInfo['mimeType']);
                    }

                    String firstFileExtension = selectedFiles.first.path
                        .split('.')
                        .last
                        .toLowerCase();
                    String messageType = ['mp4', 'mov', 'avi', 'mkv']
                        .contains(firstFileExtension)
                        ? 'video'
                        : 'image';

                    final uploadParams = {
                      ApiKeys.fileName: fileNames,
                      ApiKeys.fileType: fileTypes,
                    };

                    await chatViewController.generateUploadUrlsApi(
                      params: uploadParams,
                      listFile: selectedFiles,
                      userId: userIds,
                      messageType: messageType,
                    );
                    chatViewController.emitEvent(
                        ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.personal_Chat_Type});
                  }
                }else{
                  // Forward existing messages to selected contacts
                  Map<String, dynamic> data = {
                    ApiKeys.forward_id:
                    chatThemeController.selectedMessageIds,
                    ApiKeys.forward_to_conversations:
                    chatViewController.selectedUserIds,
                  };

                  bool value = await chatViewController
                      .forwardMessageApi(data);

                  if (value) {
                    chatViewController.emitEvent(
                        ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.personal_Chat_Type});
                    chatThemeController.selectedMessageIds.clear();
                    chatThemeController.isMessageSelectionActive.value=false;
                  }
                }
              }

              // Navigate to symbol screen if symbol selected
              if(symbolSelected==true){
                String? symbolText = widget.sharedText;
                final symbolFiles = widget.sharedFiles;

                // When forwarding messages from within chat (no share-intent),
                // pull the text from the first selected text message so the
                // symbol screen opens pre-filled.
                if (symbolText == null && symbolFiles == null) {
                  for (final m in chatThemeController.selectedMessages) {
                    if (m.messageType == 'text' &&
                        (m.message ?? '').isNotEmpty) {
                      symbolText = m.message;
                      break;
                    }
                  }
                  // Clear selection so the chat screen exits selection mode
                  chatThemeController.selectedMessageIds.clear();
                  chatThemeController.selectedMessages.clear();
                  chatThemeController.isMessageSelectionActive.value = false;
                }

                Get.off(()=>AddChatSymbolScreen(
                  sharedText: symbolText,
                  sharedFiles: symbolFiles,
                ));
              }else{
                if(widget.stopChatNav!=true){
                  bottomBarController.onChangeIndex(3);
                }
                // For share-intent flows (sharedFiles/sharedText), only pop
                // once since there's no underlying chat screen to return to.
                // For normal message forwarding, pop the forward screen first,
                // then pop the message-selection screen.
                Get.back();
                if(widget.sharedFiles==null && widget.sharedText==null){
                  // Small delay to let the first pop finish so we don't
                  // accidentally pop an unrelated screen.
                  await Future.delayed(const Duration(milliseconds: 100));
                  if(Navigator.of(context).canPop()) {
                    Get.back();
                  }
                }
              }

              _isSending = false;
            },
            child: Container(
              padding: EdgeInsets.all(14),
              margin: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: (chatViewController.selectedUserIds.isNotEmpty||symbolSelected)
                      ? AppColors.primaryColor
                      : chatThemeController.myMessageBgColor.value,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    "${chatViewController.selectedUserIds.length} Forward",
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  SvgPicture.asset(
                      height: 18,
                      width: 18,
                      AppIconAssets.send_message_chat),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
