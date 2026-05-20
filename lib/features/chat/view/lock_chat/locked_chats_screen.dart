import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';

/// WhatsApp-style "Locked Chats" screen.
///
/// Flow:
///   1. If no PIN is configured yet, show "Create PIN" (4-digit numeric).
///   2. Otherwise show "Enter PIN" — only after the PIN matches is the
///      list of locked chats revealed.
///
/// Personal and business locked chats are kept on separate tabs so the
/// experience matches the parent Connect screen's tab split.
class LockedChatsScreen extends StatefulWidget {
  const LockedChatsScreen({super.key, this.initialIsBusiness = false});

  final bool initialIsBusiness;

  @override
  State<LockedChatsScreen> createState() => _LockedChatsScreenState();
}

class _LockedChatsScreenState extends State<LockedChatsScreen>
    with SingleTickerProviderStateMixin {
  final ChatLockController _lockController = Get.find<ChatLockController>();
  final ChatViewController _chatViewController = Get.find<ChatViewController>();

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isUnlocked = false;
  String? _pinError;
  late TabController _tabController;

  /// IDs the user has selected for bulk unlock. Lives at the screen level
  /// (not the per-tab widget) so the bottom action bar and the AppBar can
  /// react together.
  final RxSet<String> _selectedIds = <String>{}.obs;

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsBusiness ? 1 : 0,
    );
    // Switching tabs while a selection is active would leave the user
    // unable to act on the hidden selection from the other tab.
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    if (id.isEmpty) return;
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  void _clearSelection() => _selectedIds.clear();

  Future<void> _unlockSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    final isBiz = _tabController.index == 1;
    await _lockController.unlockMultiple(ids, isBusiness: isBiz);
    _selectedIds.clear();
    commonSnackBar(
      message: "Unlocked ${ids.length} chat${ids.length > 1 ? 's' : ''}",
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_lockController.hasPin.value) {
      final ok = await _lockController.verifyPin(_pinController.text.trim());
      if (!ok) {
        setState(() => _pinError = "Incorrect PIN");
        return;
      }
    } else {
      final pin = _pinController.text.trim();
      final confirm = _confirmPinController.text.trim();
      if (pin.length < 4) {
        setState(() => _pinError = "PIN must be at least 4 digits");
        return;
      }
      if (pin != confirm) {
        setState(() => _pinError = "PINs do not match");
        return;
      }
      await _lockController.setPin(pin);
    }
    setState(() {
      _isUnlocked = true;
      _pinError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final inSelection = _isSelectionMode;
      return PopScope(
        canPop: !inSelection,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _clearSelection();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            leading: inSelection
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: _clearSelection,
                  )
                : null,
            title: CustomText(
              inSelection
                  ? "${_selectedIds.length} Selected"
                  : "Locked Chats",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            actions: inSelection
                ? [
                    IconButton(
                      tooltip: "Unlock",
                      icon: const Icon(Icons.lock_open, color: Colors.black),
                      onPressed: _unlockSelected,
                    ),
                  ]
                : null,
            bottom: _isUnlocked
                ? TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryColor,
                    tabs: const [
                      Tab(text: "Personal"),
                      Tab(text: "Business"),
                    ],
                  )
                : null,
          ),
          bottomNavigationBar: inSelection
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
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
                      onPressed: _unlockSelected,
                      icon: const Icon(Icons.lock_open, color: Colors.white),
                      label: CustomText(
                        "Unlock (${_selectedIds.length})",
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: _isUnlocked ? _buildLockedList() : _buildPinGate(),
        ),
      );
    });
  }

  Widget _buildPinGate() {
    return Obx(() {
      final hasPin = _lockController.hasPin.value;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primaryColor,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomText(
              hasPin ? "Enter your PIN" : "Create a PIN",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CustomText(
              hasPin
                  ? "Enter the PIN to view your locked chats."
                  : "Your locked chats and their content will be hidden behind this PIN.",
              fontSize: 14,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: hasPin ? "PIN" : "New PIN",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (!hasPin) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Confirm PIN",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            if (_pinError != null) ...[
              const SizedBox(height: 8),
              CustomText(
                _pinError!,
                color: AppColors.red,
                fontSize: 13,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: CustomText(
                hasPin ? "Unlock" : "Create PIN",
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLockedList() {
    return TabBarView(
      controller: _tabController,
      physics: _isSelectionMode
          ? const NeverScrollableScrollPhysics()
          : null,
      children: [
        _LockedChatsTab(
          isBusiness: false,
          lockController: _lockController,
          chatViewController: _chatViewController,
          selectedIds: _selectedIds,
          onToggleSelect: _toggleSelect,
          onUnlockSingle: (id) async {
            await _lockController.unlockMultiple([id], isBusiness: false);
            commonSnackBar(message: "Chat unlocked");
          },
        ),
        _LockedChatsTab(
          isBusiness: true,
          lockController: _lockController,
          chatViewController: _chatViewController,
          selectedIds: _selectedIds,
          onToggleSelect: _toggleSelect,
          onUnlockSingle: (id) async {
            await _lockController.unlockMultiple([id], isBusiness: true);
            commonSnackBar(message: "Chat unlocked");
          },
        ),
      ],
    );
  }
}

class _LockedChatsTab extends StatelessWidget {
  const _LockedChatsTab({
    required this.isBusiness,
    required this.lockController,
    required this.chatViewController,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onUnlockSingle,
  });

  final bool isBusiness;
  final ChatLockController lockController;
  final ChatViewController chatViewController;
  final RxSet<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final Future<void> Function(String id) onUnlockSingle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final lockedIds = lockController.lockedIds(isBusiness);
      if (lockedIds.isEmpty) {
        return _emptyState();
      }

      final allChats = isBusiness
          ? chatViewController.getBusinessChatListModel?.value.chatList ?? []
          : chatViewController.getPersonalChatListModel?.value.chatList ?? [];

      final List<ChatList?> lockedChats = allChats
          .where((chat) => chat != null && lockedIds.contains(chat.conversationId))
          .toList();

      if (lockedChats.isEmpty) {
        return _emptyState();
      }

      return ListView.builder(
        itemCount: lockedChats.length,
        itemBuilder: (context, index) {
          final chat = lockedChats[index];
          final convId = chat?.conversationId ?? '';
          // Obx already rebuilds on selectedIds changes via the outer scope,
          // but this read keeps the per-row highlight correct.
          final isSelected = selectedIds.contains(convId);
          final inSelection = selectedIds.isNotEmpty;

          return Container(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.1)
                : null,
            child: Row(
              children: [
                Expanded(
                  child: ChatListTile(
                    type: chat?.sender?.accountType ??
                        (isBusiness
                            ? AppConstants.business
                            : AppConstants.individual),
                    index: index,
                    chatViewController: chatViewController,
                    chat: chat,
                    theme: theme,
                    isForwardUI: false,
                    isChatListSelected: isSelected,
                    context: context,
                    onSelect: () {},
                    onLongPress: () => onToggleSelect(convId),
                    onTab: inSelection
                        ? () => onToggleSelect(convId)
                        : null,
                  ),
                ),
                if (!inSelection)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      tooltip: "Unlock",
                      icon: const Icon(Icons.lock_open,
                          color: AppColors.primaryColor),
                      onPressed: () => _confirmAndUnlock(context, convId),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _confirmAndUnlock(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const CustomText(
          "Unlock Chat",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: const CustomText(
          "This chat will move back to your main inbox.",
          fontSize: 14,
          color: Colors.black87,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const CustomText("Unlock",
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onUnlockSingle(id);
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          CustomText(
            "No locked chats",
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}
