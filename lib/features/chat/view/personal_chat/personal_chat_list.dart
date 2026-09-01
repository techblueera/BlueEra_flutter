import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/custom_chat_tab_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../../auth/model/custom_chat_tab_model.dart';
import '../archive_chat/archive_chat_list.dart';
import '../business_chat/business_chat_list.dart' show ChatBucket, bucketChat;
import '../flag_chat/flag_chat_list.dart';
import '../group_chat/group_chat_list.dart';
import '../pin_chat/pin_chat_list.dart';
import '../contacts/widget/start_chat_contact_suggestions.dart';
import '../widget/component_widgets.dart';
import '../../../../widgets/glass_surface.dart';
import 'custom_tab_conversation_picker.dart';

class PersonalChatsList extends StatefulWidget {
  const PersonalChatsList({
    super.key,
    this.isForwardUI,
    this.isNewGroupUI,
    this.hideSubTabs,
  });

  final bool? isForwardUI;
  final bool? isNewGroupUI;
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
              // if(widget.isForwardUI==false && widget.hideSubTabs != true)
              //   _buildTabStrip(theme),
              SizedBox(height: 10,),
              _sheeted(_buildBody(data, theme)),
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
      // Breathing room above the sub-tabs (gap from the app bar), but no bottom
      // pad so the first chat row sits right under the sub-tabs (no empty gap).
      padding: const EdgeInsets.only(left: 14, right: 14, top: 12),
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
    // On the Connect tab these pills sit on the frosted header, so an
    // unselected pill takes a translucent white fill and a white rim to lift it
    // off the banner. Its LABEL stays dark — the fill is what it reads against.
    // The selected pill is solid brand blue in both looks.
    final bool glass = GlassScope.isActive(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : (glass ? Colors.white.withValues(alpha: 0.30) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(
                  color: glass
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.secondaryTextColor),
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
    final bool glass = GlassScope.isActive(context);
    return InkWell(
      onTap: _showAddTabDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: glass ? Colors.white.withValues(alpha: 0.30) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: glass
                  ? Colors.white.withValues(alpha: 0.75)
                  : AppColors.secondaryTextColor),
        ),
        child: Icon(Icons.add, size: 18, color: AppColors.secondaryTextColor),
      ),
    );
  }

  /// Drops the list body onto the frosted sheet when this list is rendering on
  /// the Connect tab. The sheet's top edge lands directly under the filter chips
  /// above it, which is where the reference puts it (docs/chat_new.jpeg).
  /// Everywhere else this widget is embedded, the body is returned untouched on
  /// whatever page the host already has.
  ///
  /// [_buildBody] returns an [Expanded] on most branches, and an Expanded has to
  /// stay a direct child of the Column — so the sheet is slipped INSIDE it
  /// rather than wrapped around it, which would put an Expanded under a
  /// non-Flex parent and throw.
  Widget _sheeted(Widget body) {
    if (!GlassScope.isActive(context)) return body;
    if (body is Expanded) {
      return Expanded(
        flex: body.flex,
        child: GlassSheet(child: body.child),
      );
    }
    return GlassSheet(child: body);
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

  /// True for the read-only "BlueEra" broadcast/system thread. It arrives in
  /// the server chat list like any other conversation, but the user can't
  /// reply to it — so it doesn't count as "this user has a conversation".
  /// Matched the same way `AppNotificationHandler` resolves the thread:
  /// by sender name or the `Admin` account type (plus the client-side
  /// notifications row id).
  bool _isBlueEraBroadcastChat(ChatList? chat) {
    if (chat == null) return true;
    if (chat.conversationId == 'blueera_notifications') return true;
    final name = (chat.sender?.name ?? '').trim().toLowerCase();
    final type = chat.sender?.accountType ?? '';
    return name == 'blueera' || type == AppStrings.Admin;
  }

  /// Sort key for "most recent activity": the last-message time, falling back
  /// to creation time. Empty string for a row with neither, which sorts it to
  /// the bottom — the same place the Today/History split sends it.
  String _lastActivityKey(ChatList? chat) {
    if (chat == null) return '';
    final updated = chat.updatedAt;
    if (updated != null && updated.isNotEmpty) return updated;
    return chat.createdAt ?? '';
  }

  /// The order / inquiry conversations that also belong on the Chat tab.
  ///
  /// Placing an order creates a business conversation, so it only ever landed
  /// in Inquiry. The Chat tab now carries those rows too — same conversation,
  /// two entry points — so a fresh order is reachable without switching tabs.
  ///
  /// Which rows: exactly the ones the Inquiry tab shows, so the two tabs can't
  /// disagree. [ChatBucket.chats] is orders I PLACED plus normal business
  /// chats; orders I RECEIVED as a seller stay in the Me/Order lane, and a
  /// rider's own ride threads are bucketed out by [bucketChat]. Archived and
  /// PIN-locked business threads are dropped the same way Inquiry drops them.
  ///
  /// Reading the business model here also registers it with the enclosing
  /// [Obx], so the Chat tab repaints when the business list arrives.
  List<ChatList?> _businessChatsForChatTab(Set<String?> alreadyListed) {
    final businessList =
        chatViewController.getBusinessChatListModel?.value.chatList ?? [];
    if (businessList.isEmpty) return const [];

    final archivedIds = pinArchiveController.businessArchivedIds;
    final lockedIds = lockController.businessLockedIds;

    final merged = <ChatList?>[];
    for (final chat in businessList) {
      if (chat == null) continue;
      final id = chat.conversationId;
      // A conversation the personal list already carries must not double up.
      if (alreadyListed.contains(id)) continue;
      if (archivedIds.contains(id) || lockedIds.contains(id)) continue;
      if (bucketChat(chat) != ChatBucket.chats) continue;
      merged.add(chat);
    }
    return merged;
  }

  /// True when the conversation saw activity at or after [cutoff] — i.e. it
  /// belongs under the "Today" heading. `updated_at` is the last-message time;
  /// `created_at` only covers rows the server sent before the conversation had
  /// one. A row with no usable timestamp can't be claimed as recent, so it
  /// falls through to History. Same rule as [recentInquiryChats] on the
  /// Inquiry side, so the two tabs can never disagree about what "today" means.
  bool _isActiveSince(ChatList chat, DateTime cutoff) {
    final raw =
        (chat.updatedAt?.isNotEmpty ?? false) ? chat.updatedAt : chat.createdAt;
    if (raw == null || raw.isEmpty) return false;
    try {
      return DateTime.parse(raw).toLocal().isAfter(cutoff);
    } catch (_) {
      return false; // unparseable timestamp — can't claim it's recent
    }
  }

  /// Section heading ("Today" / "History") separating the last-24h chats from
  /// the aged-out ones. Matches the Inquiry tab's heading style.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: CustomText(
        title,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
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

    // Orders / inquiries surface on this tab as well as on Inquiry — see
    // [_businessChatsForChatTab]. Pickers are left alone: the forward screen
    // already lists recent inquiries in its own section above this list, so
    // merging here would show every order twice.
    final bool mergeBusinessChats =
        widget.isForwardUI != true && widget.isNewGroupUI != true;
    if (mergeBusinessChats) {
      chatList = [
        ...chatList,
        ..._businessChatsForChatTab(
          chatList.map((c) => c?.conversationId).toSet(),
        ),
      ];
    }

    // Sort: pinned chats first, then newest activity first.
    //
    // The recency tie-break is not cosmetic. The merged order rows arrive in
    // the business list's own order, so without it every order would sit
    // below every personal chat regardless of age. It also can't be left to
    // the incoming order: `List.sort` is NOT stable in Dart, so a comparator
    // returning 0 for two unpinned rows is free to swap them and scramble the
    // server's newest-first ordering.
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      return _lastActivityKey(b).compareTo(_lastActivityKey(a));
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Count special rows at top: just the Records row (if archived). The
    // BlueEra thread is no longer a synthetic pinned row — it now comes
    // straight from the server chat list like any other conversation — and the
    // AI-assistant row has been removed from every chat list (the server-side
    // copy is stripped in `ChatViewController.loadChatListWithType`, so it
    // can't reappear via the socket either).
    final recordsOffset = hasArchived ? 1 : 0;
    final topRowCount = recordsOffset;

    // A brand-new user's list is either completely empty or holds nothing but
    // the BlueEra broadcast thread — which they can't reply to. In both cases
    // we append the "contacts on BlueEra" suggestions so there's something to
    // start a conversation from. Never in the forward / new-group pickers:
    // those pick an EXISTING conversation, and a suggestion row there would
    // both mislead and navigate away mid-selection.
    final hasRealConversation =
        chatList.any((chat) => !_isBlueEraBroadcastChat(chat));
    final showContactSuggestions = !hasRealConversation &&
        !hasArchived &&
        widget.isForwardUI != true &&
        widget.isNewGroupUI != true;
    final suggestionRowCount = showContactSuggestions ? 1 : 0;

    // Recency split — the Chat tab now mirrors the Inquiry tab's sections.
    // "Today" is the last 24 hours of activity (`updated_at`, falling back to
    // `created_at` for rows the server sent before the conversation had a
    // message); everything older drops under "History" in the same list.
    // Pinned chats are exempt: the user pinned them to keep them at the top,
    // so they stay under Today however old the last message is.
    //
    // Pickers (forward / new-group) keep the flat list — section headings
    // there would only get in the way of picking a conversation.
    final bool showSections =
        widget.isForwardUI != true && widget.isNewGroupUI != true;
    final List<ChatList?> todayList = [];
    final List<ChatList?> historyList = [];
    if (showSections) {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      for (final chat in chatList) {
        if (chat != null &&
            !pinnedIds.contains(chat.conversationId) &&
            !_isActiveSince(chat, cutoff)) {
          historyList.add(chat);
        } else {
          todayList.add(chat);
        }
      }
    } else {
      todayList.addAll(chatList);
    }
    final bool showTodayHeader = showSections && todayList.isNotEmpty;
    final bool showHistoryHeader = showSections && historyList.isNotEmpty;
    final int todayHeaderCount = showTodayHeader ? 1 : 0;
    final int historyHeaderCount = showHistoryHeader ? 1 : 0;

    return Container(
      // Still render the list when there are no real chats but pinned system
      // rows exist (AI / BlueEra notifications), so those stay visible for a
      // brand-new user. Only the truly-empty case shows the empty state.
      child: (chatList.isEmpty && !hasArchived && topRowCount == 0)
          ? (showContactSuggestions
              ? const SingleChildScrollView(
                  child: StartChatContactSuggestions())
              : noChatsFound())
          : ListView.builder(
        // Kill the top inset ListView auto-injects when it's the primary
        // scrollable (it adds MediaQuery.padding.top), which showed up as an
        // empty strip above the first chat row.
        padding: EdgeInsets.zero,
        itemCount: topRowCount +
            todayHeaderCount +
            todayList.length +
            historyHeaderCount +
            historyList.length +
            suggestionRowCount,
        shrinkWrap: true,
        physics: widget.isForwardUI == true
            ? NeverScrollableScrollPhysics()
            : null,
        itemBuilder: (context, index) {
          // Records row at very top (index 0)
          if (hasArchived && index == 0) {
            return _buildRecordsRow();
          }

          // Past the Records row — `i` now walks the real content:
          // [Today?, today…, History?, history…, suggestions?]
          int i = index - topRowCount;

          // "Today" heading above the last-24h chats.
          if (showTodayHeader) {
            if (i == 0) return _buildSectionHeader(AppStrings.todayLabel.tr);
            i -= 1;
          }

          final List<ChatList?> section;
          final int chatIndex;
          if (i < todayList.length) {
            section = todayList;
            chatIndex = i;
          } else {
            i -= todayList.length;

            // "History" heading above the aged-out conversations.
            if (showHistoryHeader) {
              if (i == 0) {
                return _buildSectionHeader(AppStrings.historyTab.tr);
              }
              i -= 1;
            }

            // Suggestions sit BELOW every chat row.
            if (i >= historyList.length) {
              return const StartChatContactSuggestions();
            }
            section = historyList;
            chatIndex = i;
          }
          final chat = section[chatIndex];
          final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
          final isChatSelected = chatViewController.selectedConversationIds
              .contains(chat?.conversationId ?? '');
          final isPinned = pinnedIds.contains(chat?.conversationId);

          final tile = ChatListTile(
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

          // The sheet has no per-row edge, so without a rule the entries run
          // together into one column of text. Inset past the avatar so the line
          // separates entries rather than cutting across the sheet
          // (docs/chat_new.jpeg). The solid look keeps its undivided rows.
          if (!GlassScope.isActive(context)) return tile;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              const Padding(
                padding: EdgeInsets.only(left: 78, right: 16),
                child: Divider(height: 1, thickness: 1, color: kGlassDivider),
              ),
            ],
          );
        },
      ),
    );
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
