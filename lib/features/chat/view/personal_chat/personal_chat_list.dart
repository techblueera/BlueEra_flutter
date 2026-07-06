import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/notification_chat/controller/blueera_notification_controller.dart';
import 'package:BlueEra/features/chat/notification_chat/view/blueera_notification_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/custom_chat_tab_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../../auth/model/custom_chat_tab_model.dart';
import '../ai_chat/view/ai_chat_screen.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/flag_chat_list.dart';
import '../group_chat/group_chat_list.dart';
import '../pin_chat/pin_chat_list.dart';
import '../widget/component_widgets.dart';
import 'custom_tab_conversation_picker.dart';

class PersonalChatsList extends StatefulWidget {
  const PersonalChatsList({
    super.key,
    this.isForwardUI,
    this.isNewGroupUI,
    this.hideAiChats,
    this.hideSubTabs,
  });

  final bool? isForwardUI;
  final bool? isNewGroupUI;
  final bool? hideAiChats;
  /// When `true`, the All / Group / Pinned / Flagged / Records sub-tab
  /// strip is hidden and only the personal chat list is rendered.
  final bool? hideSubTabs;

  @override
  State<PersonalChatsList> createState() => _PersonalChatsListState();
}

class _PersonalChatsListState extends State<PersonalChatsList> {
  final chatViewController = getOrPut(() => ChatViewController());
  final pinArchiveController = getOrPut(() => ChatPinArchiveController());
  final lockController = getOrPut(() => ChatLockController());
  final customTabController = getOrPut(() => CustomChatTabController());
  final blueEraNotifController = BlueEraNotificationController.to;

  // Locally-personalized name/image for the personal AI chat row. Loaded from
  // [AiChatProfileStorage] and refreshed when returning from the AI chat
  // screen so a rename/avatar change made there is reflected in this list.
  String _aiName = '';
  String _aiImage = '';

  @override
  void initState() {
    super.initState();
    _loadAiProfile();
  }

  Future<void> _loadAiProfile() async {
    const aiType = AppConstants.personal_Chat_Type;
    final name = (await AiChatProfileStorage.getName(aiType)) ?? '';
    final image = (await AiChatProfileStorage.getImagePath(aiType)) ?? '';
    if (!mounted) return;
    setState(() {
      _aiName = name;
      _aiImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.personalChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            chatViewController.getPersonalChatListModel?.value;

        return RefreshIndicator(
          onRefresh: () async {
            chatViewController.emitEvent(
                ChatEmitEvents.ChatList, {ApiKeys.type: "personal"}, );
          },
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(widget.isForwardUI==false && widget.hideSubTabs != true)
                _buildTabStrip(theme),
              _buildBody(data, theme),
            ],
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }

  /// Sub-tab strip: the 5 built-in tabs, then any user-created custom tabs,
  /// then a trailing "+" to create a new one.
  Widget _buildTabStrip(ThemeData theme) {
    final builtin = [
      AppStrings.allTab.tr,
      AppStrings.groupTab.tr,
      AppStrings.pinnedTab.tr,
      AppStrings.flaggedTab.tr,
      AppStrings.recordsTab.tr,
    ];
    final selectedCustomId = customTabController.selectedTabId.value;
    final builtinIdx = chatViewController.personalTabSelectedIndex.value;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < builtin.length; i++) ...[
            _buildTabChip(
              label: builtin[i],
              selected: selectedCustomId == null && builtinIdx == i,
              onTap: () {
                customTabController.selectedTabId.value = null;
                chatViewController.personalTabSelectedIndex.value = i;
                if (i == 1) {
                  chatViewController.emitEvent(ChatEmitEvents.ChatList,
                      {ApiKeys.type: AppConstants.group_Chat_Type});
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          for (final tab in customTabController.tabs) ...[
            _buildTabChip(
              label: tab.name,
              selected: selectedCustomId == tab.id,
              onTap: () => customTabController.selectedTabId.value = tab.id,
              onLongPress: () => _showTabOptions(tab),
            ),
            const SizedBox(width: 8),
          ],
          _buildAddTabChip(),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(color: AppColors.secondaryTextColor),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: selected ? AppColors.white : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildAddTabChip() {
    return InkWell(
      onTap: _showAddTabDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondaryTextColor),
        ),
        child: Icon(Icons.add, size: 18, color: AppColors.secondaryTextColor),
      ),
    );
  }

  /// Chooses what to render under the strip: forward-UI list, a custom tab, or
  /// one of the built-in tabs.
  Widget _buildBody(GetChatListModel? data, ThemeData theme) {
    // Forward UI never shows sub-tabs — just the plain selectable list.
    if (widget.isForwardUI == true) {
      return personalChatListWidget(data, theme);
    }
    // A user-created custom tab takes precedence over the built-in tabs.
    final customTab = customTabController.selectedTab;
    if (customTab != null) {
      return customTabChatListWidget(customTab, data, theme);
    }
    switch (chatViewController.personalTabSelectedIndex.value) {
      case 1:
        return Expanded(child: const GroupChatListTabPage());
      case 2:
        return const PinChatList();
      case 3:
        return const FlagChatList();
      case 4:
        return _buildArchiveTab();
      case 0:
      default:
        return Expanded(child: personalChatListWidget(data, theme));
    }
  }

  /// The list shown when a custom tab is active: an "Add conversation" button
  /// plus the conversations the user assigned to this tab.
  Widget customTabChatListWidget(
      CustomChatTab tab, GetChatListModel? data, ThemeData theme) {
    final all = data?.chatList ?? <ChatList?>[];
    final ids = tab.conversationIds.toSet();
    final chats =
        all.where((c) => c != null && ids.contains(c.conversationId)).toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: InkWell(
              onTap: () => _openConversationPicker(tab),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    CustomText(
                      "Add conversation",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: chats.isEmpty
                ? _emptyCustomTab()
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: SizeConfig.size70),
                    itemCount: chats.length,
                    itemBuilder: (context, i) {
                      final chat = chats[i];
                      return ChatListTile(
                        onLongPress: () => _confirmRemoveFromTab(tab, chat),
                        onSelect: () => setState(() {}),
                        type: chat?.sender?.accountType ??
                            AppConstants.individual,
                        index: i,
                        chatViewController: chatViewController,
                        chat: chat,
                        theme: theme,
                        isForwardUI: false,
                        showFlagBadge: true,
                        context: context,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCustomTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          CustomText(
            "No conversations yet",
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          const SizedBox(height: 4),
          CustomText(
            'Tap "Add conversation" to pick chats',
            color: Colors.grey.shade400,
            fontSize: 12.5,
          ),
        ],
      ),
    );
  }

  Future<void> _openConversationPicker(CustomChatTab tab) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CustomTabConversationPicker(tabId: tab.id, tabName: tab.name),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showAddTabDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText("New tab",
            fontSize: 18, fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: "Tab name"),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const CustomText("Create",
                color: AppColors.primaryColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final tab = await customTabController.addTab(name);
    customTabController.selectedTabId.value = tab.id;
    // Immediately let the user pick conversations for the brand-new tab.
    await _openConversationPicker(tab);
  }

  Future<void> _showRenameTabDialog(CustomChatTab tab) async {
    final controller = TextEditingController(text: tab.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText("Rename tab",
            fontSize: 18, fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: "Tab name"),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const CustomText("Save",
                color: AppColors.primaryColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await customTabController.renameTab(tab.id, name);
  }

  void _showTabOptions(CustomChatTab tab) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const CustomText("Add / edit conversations", fontSize: 15),
              onTap: () {
                Navigator.pop(ctx);
                _openConversationPicker(tab);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const CustomText("Rename tab", fontSize: 15),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameTabDialog(tab);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const CustomText("Delete tab",
                  fontSize: 15, color: AppColors.red),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTab(tab);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTab(CustomChatTab tab) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText("Delete tab",
            fontSize: 17, fontWeight: FontWeight.bold),
        content: CustomText(
          'Delete "${tab.name}"? The conversations themselves are not deleted.',
          fontSize: 14,
          color: Colors.black87,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () {
              customTabController.removeTab(tab.id);
              Navigator.pop(ctx);
            },
            child: const CustomText("Delete",
                color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFromTab(CustomChatTab tab, ChatList? chat) {
    final id = chat?.conversationId;
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText("Remove from tab",
            fontSize: 17, fontWeight: FontWeight.bold),
        content: CustomText(
          'Remove this chat from "${tab.name}"?',
          fontSize: 14,
          color: Colors.black87,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () {
              customTabController.removeConversation(tab.id, id);
              Navigator.pop(ctx);
            },
            child: const CustomText("Remove",
                color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab() {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () => Get.to(() => const ArchiveChatListPage()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                final count = pinArchiveController.personalArchivedIds.length;
                return Row(
                  children: [
                    Icon(Icons.archive_outlined, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        "${AppStrings.recordsLabel.tr} ($count)",
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey.shade400),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

Widget personalChatListWidget(GetChatListModel? data,ThemeData theme ){
    // Sort pinned to top — archived chats are no longer filtered out here.
    List<ChatList?> chatList = data?.chatList ?? [];
    final archivedIds = pinArchiveController.personalArchivedIds;
    final pinnedIds = pinArchiveController.personalPinnedIds;
    final lockedIds = lockController.personalLockedIds;

    // Locked chats live behind the PIN-gated Locked Chats screen, so they
    // must not appear in the main list (WhatsApp-style Chat Lock).
    chatList = chatList.where((chat) {
      return chat == null || !lockedIds.contains(chat.conversationId);
    }).toList();

    // Sort: pinned chats first, then unpinned
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Count special rows at top: Records row (if archived) + AI chat +
    // BlueEra notifications row. BlueEra is hidden in the forward picker (you
    // can't forward a message into the system notifications thread).
    final aiOffset = widget.hideAiChats == true ? 0 : 1;
    final recordsOffset = hasArchived ? 1 : 0;
    final blueEraOffset = widget.isForwardUI == true ? 0 : 1;
    final topRowCount = aiOffset + recordsOffset + blueEraOffset;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size70),
      // Still render the list when there are no real chats but pinned system
      // rows exist (AI / BlueEra notifications), so those stay visible for a
      // brand-new user. Only the truly-empty case shows the empty state.
      child: (chatList.isEmpty && !hasArchived && topRowCount == 0)
          ? noChatsFound()
          : ListView.builder(
        itemCount: chatList.length + topRowCount,
        shrinkWrap: true,
        physics: widget.isForwardUI == true
            ? NeverScrollableScrollPhysics()
            : null,
        itemBuilder: (context, index) {
          // Records row at very top (index 0)
          if (hasArchived && index == 0) {
            return _buildRecordsRow();
          }

          // AI chat right after Records row
          if (index == recordsOffset && widget.hideAiChats != true) {
            final chat = ChatViewController.personalAiChatModule;
            // Apply the locally-saved custom name/image so the row matches
            // what the user set inside the AI chat screen.
            if (_aiName.isNotEmpty) {
              chat?.sender?.name = _aiName;
            }
            if (_aiImage.isNotEmpty) {
              chat?.sender?.profileImage = _aiImage;
            }
            final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
            final isChatSelected = chatViewController.selectedConversationIds
                .contains(chat?.conversationId ?? '');

            return ChatListTile(
              onTab: (widget.isForwardUI == false) ? () {
                if (isInSelectionMode) {
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                  return;
                }
                Get.to(() => AiChatScreen(
                  profileImage: chat?.sender?.profileImage,
                  name: chat?.sender?.name,
                  type: chat?.sender?.accountType,
                ))?.then((_) => _loadAiProfile());
              } : null,
              isFromGroupSelect: widget.isNewGroupUI,
              onLongPress: () {
                if (!isInSelectionMode) {
                  chatViewController.isChatListSelectionMode.value = true;
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                }
              },
              isChatListSelected: isChatSelected,
              onSelect: () => setState(() {}),
              type: chat?.sender?.accountType ?? AppConstants.individual,
              index: -1,
              chatViewController: chatViewController,
              chat: chat,
              theme: theme,
              isForwardUI: widget.isForwardUI,
              showFlagBadge: true,
              context: context,
            );
          }

          // Pinned "BlueEra" system row — broadcast/system notifications shown
          // as a chat thread. Sits right after the AI row (or in the AI slot
          // when the AI row is hidden).
          if (blueEraOffset == 1 && index == recordsOffset + aiOffset) {
            return _buildBlueEraNotificationRow(theme);
          }

          final chatIndex = index - topRowCount;
          final chat = chatList[chatIndex];
          final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
          final isChatSelected = chatViewController.selectedConversationIds
              .contains(chat?.conversationId ?? '');
          final isPinned = pinnedIds.contains(chat?.conversationId);

          return ChatListTile(
            isFromGroupSelect: widget.isNewGroupUI,
            onLongPress: () {
              if (!isInSelectionMode) {
                chatViewController.isChatListSelectionMode.value = true;
                chatViewController.toggleChatListSelection(chat);
                setState(() {});
              }
            },
            isChatListSelected: isChatSelected,
            isPinned: isPinned,
            onSelect: () => setState(() {}),
            type: chat?.sender?.accountType ?? AppConstants.individual,
            index: chatIndex,
            chatViewController: chatViewController,
            chat: chat,
            theme: theme,
            isForwardUI: widget.isForwardUI,
            showFlagBadge: true,
            context: context,
          );
        },
      ),
    );
}

  /// The pinned "BlueEra" system row. Reuses [ChatListTile] with the synthetic
  /// [ChatViewController.blueEraNotificationModule], overwriting its preview /
  /// time / unread-count from the live notification store, and opens
  /// [BlueEraNotificationScreen] on tap. Wrapped in [Obx] so a freshly-arrived
  /// notification updates the row instantly.
  Widget _buildBlueEraNotificationRow(ThemeData theme) {
    return Obx(() {
      final chat = ChatViewController.blueEraNotificationModule;
      final latest = blueEraNotifController.latest;
      final unread = blueEraNotifController.unreadCount;
      // Depend on the reactive list length too, so inserts always rebuild.
      final _ = blueEraNotifController.messages.length;

      chat?.lastMessage =
          latest?.preview ?? "Tap to view your BlueEra notifications";
      chat?.unreadCount = unread;
      chat?.updatedAt = latest != null
          ? DateTime.fromMillisecondsSinceEpoch(latest.timeMillis)
              .toUtc()
              .toIso8601String()
          : '';

      return ChatListTile(
        onTab: () {
          if (chatViewController.isChatListSelectionMode.value) return;
          Get.to(() => const BlueEraNotificationScreen());
        },
        // No long-press: the system row can't be selected / flagged / pinned.
        onLongPress: null,
        isFromGroupSelect: widget.isNewGroupUI,
        isChatListSelected: false,
        onSelect: () {},
        type: AppConstants.personal_Chat_Type,
        index: -1,
        chatViewController: chatViewController,
        chat: chat,
        theme: theme,
        isForwardUI: widget.isForwardUI,
        showFlagBadge: false,
        context: context,
      );
    });
  }

  Widget _buildRecordsRow() {
    return Obx(() {
      final count = pinArchiveController.personalArchivedIds.length;
      if (count == 0) return const SizedBox.shrink();
      return InkWell(
        onTap: () => Get.to(() => const ArchiveChatListPage()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.archive_outlined,
                    color: Colors.grey.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  AppStrings.recordsLabel.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    });
  }
}
