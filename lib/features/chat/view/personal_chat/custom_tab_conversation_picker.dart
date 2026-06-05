import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/cached_avatar_widget.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/custom_chat_tab_controller.dart';
import '../../auth/model/GetChatListModel.dart';

/// Bottom sheet that lets the user pick which personal conversations belong to
/// a custom chat tab. Pre-checks conversations already in the tab; on "Done"
/// the full selection is persisted via [CustomChatTabController].
class CustomTabConversationPicker extends StatefulWidget {
  final String tabId;
  final String tabName;

  const CustomTabConversationPicker({
    super.key,
    required this.tabId,
    required this.tabName,
  });

  @override
  State<CustomTabConversationPicker> createState() =>
      _CustomTabConversationPickerState();
}

class _CustomTabConversationPickerState
    extends State<CustomTabConversationPicker> {
  final chatViewController = Get.find<ChatViewController>();
  final customTabController = Get.find<CustomChatTabController>();

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    final i = customTabController.tabs.indexWhere((t) => t.id == widget.tabId);
    if (i >= 0) _selected.addAll(customTabController.tabs[i].conversationIds);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatList> get _allChats {
    final list = chatViewController.getPersonalChatListModel?.value.chatList ??
        <ChatList?>[];
    return list.whereType<ChatList>().toList();
  }

  String _displayName(ChatList chat) {
    if (chat.isGroup == true) {
      return (chat.groupName?.trim().isNotEmpty ?? false)
          ? chat.groupName!
          : 'Group';
    }
    return chat.sender?.name ?? 'Unknown';
  }

  String? _displayImage(ChatList chat) =>
      chat.isGroup == true ? chat.groupProfileImage : chat.sender?.profileImage;

  @override
  Widget build(BuildContext context) {
    final chats = _allChats.where((c) {
      if (c.conversationId == null) return false;
      if (_query.isEmpty) return true;
      return _displayName(c).toLowerCase().contains(_query);
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    "Add to ${widget.tabName}",
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CustomText(
                  "${_selected.length} selected",
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search chats",
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Flexible(
            child: chats.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: CustomText(
                      "No conversations found",
                      color: Colors.grey.shade500,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final id = chat.conversationId!;
                      final isChecked = _selected.contains(id);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selected.remove(id);
                            } else {
                              _selected.add(id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              CachedAvatarWidget(
                                imageUrl: _displayImage(chat),
                                size: 42,
                                borderRadius: 21,
                                showProfileOnFullScreen: false,
                              ),
                              SizedBox(width: SizeConfig.size12),
                              Expanded(
                                child: CustomText(
                                  _displayName(chat),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isChecked
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isChecked
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await customTabController.setConversations(
                        widget.tabId, _selected.toList());
                    if (mounted) Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const CustomText(
                    "Done",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
