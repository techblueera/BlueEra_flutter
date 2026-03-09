import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../widget/component_widgets.dart';

class ArchiveChatListPage extends StatefulWidget {
  const ArchiveChatListPage({super.key, this.isBusiness = false});

  final bool isBusiness;

  @override
  State<ArchiveChatListPage> createState() => _ArchiveChatListPageState();
}

class _ArchiveChatListPageState extends State<ArchiveChatListPage> {
  final chatViewController = Get.find<ChatViewController>();
  final pinArchiveController = Get.find<ChatPinArchiveController>();
  final Set<String> selectedIds = {};
  bool isSelectionMode = false;

  void _toggleSelection(String? conversationId) {
    if (conversationId == null) return;
    setState(() {
      if (selectedIds.contains(conversationId)) {
        selectedIds.remove(conversationId);
        if (selectedIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedIds.add(conversationId);
      }
    });
  }

  void _startSelection(String? conversationId) {
    if (conversationId == null) return;
    setState(() {
      isSelectionMode = true;
      selectedIds.add(conversationId);
    });
  }

  void _clearSelection() {
    setState(() {
      selectedIds.clear();
      isSelectionMode = false;
    });
  }

  void _selectAll(List<dynamic> archivedChats) {
    setState(() {
      selectedIds.clear();
      for (var chat in archivedChats) {
        if (chat?.conversationId != null) {
          selectedIds.add(chat!.conversationId!);
        }
      }
    });
  }

  Future<void> _unrecordSelected() async {
    final idsToRemove = List<String>.from(selectedIds);
    for (var id in idsToRemove) {
      await pinArchiveController.toggleArchive(id, isBusiness: widget.isBusiness);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (isSelectionMode) {
                _clearSelection();
              } else {
                Get.back();
              }
            },
          ),
          title: isSelectionMode
              ? CustomText(
                  "${selectedIds.length} Selected",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                )
              : const CustomText(
                  "Records Chats",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          actions: isSelectionMode
              ? [
                  Obx(() {
                    final archivedIds = pinArchiveController.archivedIds(widget.isBusiness);
                    final allChats = widget.isBusiness
                        ? chatViewController.getBusinessChatListModel?.value.chatList ?? []
                        : chatViewController.getPersonalChatListModel?.value.chatList ?? [];
                    final archivedChats = allChats.where((chat) {
                      return chat != null && archivedIds.contains(chat.conversationId);
                    }).toList();

                    final allSelected = archivedChats.isNotEmpty &&
                        archivedChats.every((c) => selectedIds.contains(c?.conversationId));

                    return IconButton(
                      icon: Icon(
                        allSelected ? Icons.deselect : Icons.select_all,
                        color: Colors.black,
                      ),
                      tooltip: allSelected ? "Deselect All" : "Select All",
                      onPressed: () {
                        if (allSelected) {
                          _clearSelection();
                        } else {
                          _selectAll(archivedChats);
                        }
                      },
                    );
                  }),
                ]
              : null,
        ),
        bottomNavigationBar: isSelectionMode
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: selectedIds.isNotEmpty ? _unrecordSelected : null,
                    icon: const Icon(Icons.unarchive, color: Colors.white),
                    label: CustomText(
                      "Unrecord (${selectedIds.length})",
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: Obx(() {
          final archivedIds = pinArchiveController.archivedIds(widget.isBusiness);

          if (archivedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  CustomText(
                    "No records found",
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            );
          }

          final allChats = widget.isBusiness
              ? chatViewController.getBusinessChatListModel?.value.chatList ?? []
              : chatViewController.getPersonalChatListModel?.value.chatList ?? [];

          final archivedChats = allChats.where((chat) {
            return chat != null && archivedIds.contains(chat.conversationId);
          }).toList();

          if (archivedChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  CustomText(
                    "No records found",
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: archivedChats.length,
            itemBuilder: (context, index) {
              final chat = archivedChats[index];
              final conversationId = chat?.conversationId ?? '';
              final isSelected = selectedIds.contains(conversationId);

              return Dismissible(
                key: Key(conversationId.isNotEmpty ? conversationId : '$index'),
                direction: isSelectionMode
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.primaryColor,
                  child: const Icon(Icons.unarchive, color: Colors.white),
                ),
                onDismissed: (_) {
                  pinArchiveController.toggleArchive(
                      conversationId,
                      isBusiness: widget.isBusiness);
                },
                child: Container(
                  color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : null,
                  child: ChatListTile(
                    type: chat?.sender?.accountType ??
                        (widget.isBusiness ? AppConstants.business : AppConstants.individual),
                    index: index,
                    chatViewController: chatViewController,
                    chat: chat,
                    theme: theme,
                    isForwardUI: false,
                    context: context,
                    onSelect: () {},
                    onLongPress: () {
                      if (!isSelectionMode) {
                        _startSelection(conversationId);
                      }
                    },
                    onTab: () {
                      if (isSelectionMode) {
                        _toggleSelection(conversationId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
