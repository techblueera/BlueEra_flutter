import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/check_internet_connectivity.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/add_chat_symbol_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_history_screen.dart';
import 'package:BlueEra/features/chat/view/chat_theme/chat_background_screen.dart';
import 'package:BlueEra/features/chat/view/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/chat/view/flag_chat/order_flagged_chats_screen.dart';
import 'package:BlueEra/features/chat/view/flag_chat/personal_flagged_chats_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/chat_search_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/view/reminder_chat/reminder_todo_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/chat/view/wallet_chat/wallet_chat_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/manage_notification/notification.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../core/constants/getx_utils.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../chat/auth/controller/chat_flag_controller.dart';
import '../../../chat/auth/controller/chat_lock_controller.dart';
import '../../../chat/auth/controller/chat_pin_archive_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/model/GetChatListModel.dart';
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../../chat/view/lock_chat/locked_chats_screen.dart';
import '../../../chat/view/widget/chat_flag_bottom_sheet.dart';
import '../../../personal/personal_profile/controller/languge_list_controller.dart';

enum SavedFeedTab {
  posts;

  /// Human-readable title (capitalised)
  String get title => name[0].toUpperCase() + name.substring(1);
}

class ConnectMainPage extends StatefulWidget {
  const ConnectMainPage({super.key});

  @override
  State<ConnectMainPage> createState() => _ConnectMainPageState();
}

class _ConnectMainPageState extends State<ConnectMainPage> with SingleTickerProviderStateMixin {
  final List<String> iconTab = [
    AppIconAssets.chat,
    AppIconAssets.shop,
    AppIconAssets.call,
  ];
  List<String> get postTab => [
        AppStrings.chat.tr,
        AppStrings.inquiryTab.tr,
        AppStrings.call.tr,
      ];

  int selectedIndex = 0;
  int selectedSubIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final symbolFeedController = Get.put(SymbolFeedController());
  final addSymbolController = getOrPut(() => AddChatSymbolController());
  final ChatViewController chatViewController = getOrPut(() => ChatViewController());
  final ChatPinArchiveController chatPinArchiveController = getOrPut(() => ChatPinArchiveController());
  final ChatFlagController chatFlagController = getOrPut(() => ChatFlagController());
  final ChatLockController chatLockController = getOrPut(() => ChatLockController());
  final LanguageListController langController = getOrPut(() => LanguageListController());

  late TabController _tabController;

  /// Single global subscription so the share-handler stream is never listened
  /// to more than once (ConnectMainPage is re-created on every tab switch).
  static StreamSubscription? _shareSubscription;

  /// Guard to prevent the forward screen from being pushed while one is
  /// already being opened (e.g. rapid share intents).
  static bool _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    // Honour any pending tab request set by another flow before
    // navigating here — e.g. food / grocery `placeBulkOrderApi` calls
    // `chatViewController.onSelectChatTab(2)` so the Connect screen
    // opens directly on the Orders tab. Clamp to the valid range and
    // clear the flag afterwards so subsequent opens default back to
    // Chat unless explicitly requested again.
    addSymbolController.getSymbolsForPartUser(userId);
    final pendingTab = chatViewController.selectedChatTabIndex.value;
    final initialTab = (pendingTab >= 0 && pendingTab < postTab.length) ? pendingTab : 0;
    selectedIndex = initialTab;
    chatViewController.selectedChatTabIndex.value = 0;

    _tabController = TabController(
      length: postTab.length,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_handleTabChange);
    initPlatformState();
    getPackageData();

    // Boot the chat list for whichever tab we're landing on. Without
    // this socket emit, the tab renders blank on first open until the
    // user navigates away and back.
    _emitChatListForTab(initialTab);
    // Fire-and-forget: fetch the full chat export once on home entry.
    // Response is only logged right now (see ChatViewController.getChatExportAll).
    chatViewController.getChatExportAll();

    _loadContactsFromStorage();
    // First-time-only contacts sync. On entry to the connect tab we ask for
    // contacts permission, upload the phone book, and persist the response.
    // Subsequent entries short-circuit on the Hive cache and never hit the
    // network again. Offline entries skip the sync entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContactsIfNeeded();
      _askNotificationPermission();
    });
  }

  /// Ask the OS notification permission once on entry. Mirrors the
  /// `_requestIfNotGranted` pattern in `AppServices.permissionHandler` —
  /// silently no-ops if the user has already granted (or permanently
  /// denied) the permission, so it's safe to call on every entry.
  Future<void> _askNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _syncContactsIfNeeded() async {
    // Already synced (memory or Hive)? Nothing to do.
    final hydrated = await chatViewController.hydrateContactsFromCache();
    if (hydrated) return;

    // First-time sync needs internet. Offline → skip; ContactsPage will
    // render from cache (empty if none yet).
    final online = await checkInternetStatus();
    if (!online) return;

    // Ask for contacts permission.
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) return;
    }

    // Mirror ContactsPage._loadContactsFromCache: hydrate from cache or
    // mark the response complete so a later open of ContactsPage doesn't
    // hang on the spinner while the upload below is in flight.
    await _loadContactsFromCache();

    // Read the device phone book and upload once.
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,
    );
    final formatted = contacts
        .where((c) => c.phones.isNotEmpty)
        .map<Map<String, dynamic>>((c) => {
              ApiKeys.contact_no: c.phones.first.number,
              ApiKeys.name: c.displayName,
            })
        .toList();
    if (formatted.isEmpty) return;
    await chatViewController.uploadContacts(formatted);
  }

  Future<void> _loadContactsFromCache() async {
    final hydrated = await chatViewController.hydrateContactsFromCache();
    if (hydrated) return;
    chatViewController.viewContactsListResponse.value =
        ApiResponse.complete(chatViewController.contactsListModel?.value);
  }

  Future<void> _loadContactsFromStorage() async {
    String? storedData = await SharedPreferenceUtils.getSecureValue(SharedPreferenceUtils.saved_contacts);
    if (storedData != null) {
      Map<String, dynamic> decoded = await compute(jsonDecode, storedData) as Map<String, dynamic>;
      chatViewController.loadContactsFromLocalStorage(decoded);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != selectedIndex && mounted) {
      // Switching tabs while a selection is active would strand the user
      // with no AppBar affordance to exit it — and the previous tab's
      // selection wouldn't apply to the new list anyway.
      if ((selectedIndex == 0 || selectedIndex == 1) && chatViewController.isChatListSelectionMode.value) {
        chatViewController.exitChatListSelectionMode();
      }
      setState(() {
        selectedIndex = _tabController.index;
        selectedSubIndex = 0;
      });
      _emitChatListForTab(selectedIndex);
    }
  }

  /// Hydrate the tab's chat list. Personal is also emitted in `initState`
  /// so the first paint isn't blank.
  void _emitChatListForTab(int index) {
    if (index == 0) {
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.personal_Chat_Type},
      );
    } else if (index == 1) {
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.business_Chat_Type},
      );
    }
    // index == 2 is the Call tab — CallHistoryScreen loads its own data,
    // so there is no chat-list socket emit for it.
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  ///DO NOT DELETE THIS CODE.....
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Only subscribe once — subsequent ConnectMainPage rebuilds reuse the same
    // subscription so the forward screen doesn't open multiple times.
    if (_shareSubscription != null) return;

    final handler = ShareHandlerPlatform.instance;

    // App running, receiving new share while app is open
    _shareSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
      _openChatScreen(media);
    });
  }

  void _openChatScreen(SharedMedia media) {
    if (_isHandlingShare) return; // prevent duplicate opens
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final sharedText = media.content;
    final attachments = media.attachments ?? [];

    if (sharedText != null && sharedText.isNotEmpty) {
      _isHandlingShare = true;
      Get.to(() => ChatForwardScreen(sharedText: sharedText))?.then((_) => _isHandlingShare = false);
    } else if (attachments.isNotEmpty) {
      _isHandlingShare = true;
      Get.to(() => ChatForwardScreen(sharedFiles: attachments))?.then((_) => _isHandlingShare = false);
    }
  }

  Future<void> getPackageData() async {
    if (!mounted) return;
    PackageInfo _packageInfo = await PackageManager.getPackageInfo();
    _checkForUpdate(context, _packageInfo);
  }

  Future<void> _checkForUpdate(BuildContext context, PackageInfo packageInfo) async {
    try {
      if (Platform.isAndroid) {
        InAppUpdateManager manager = InAppUpdateManager();
        AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();
        if (appUpdateInfo == null) return;
        if (appUpdateInfo.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
          //If an in-app update is already running, resume the update.
          String? message = await manager.startAnUpdate(type: AppUpdateType.immediate);
          debugPrint(message ?? '');
        } else if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          ///Update available
          if (appUpdateInfo.immediateAllowed) {
            String? message = await manager.startAnUpdate(type: AppUpdateType.immediate);
            debugPrint(message ?? '');
          } else if (appUpdateInfo.flexibleAllowed) {
            String? message = await manager.startAnUpdate(type: AppUpdateType.flexible);
            debugPrint(message ?? '');
          } else {
            debugPrint('Update available. Immediate & Flexible Update Flow not allow');
          }
        }
      } else if (Platform.isIOS) {
        VersionInfo? _versionInfo =
            await UpgradeVersion.getiOSStoreVersion(packageInfo: packageInfo, regionCode: "US");
        debugPrint(_versionInfo.toJson().toString());
      }
    } catch (e) {
      debugPrint("Error checking for update: $e");
    }
  }

  Widget _buildCustomAppBar() {
    return CommonBackAppBar(
      showElevation: 0,
      isLeading: false,
      // Hide the "+" icon on the Chat tab — its slot is replaced by
      // the search + call-history + reminder-clock actions below.
      isMore: false,
      // Inline search is disabled on the Chat tab — the search icon below
      // pushes a fullscreen WhatsApp-style search page instead.
      isSearch: false,
      isProfile: false,
      isNotification: false,
      isGuestLogout: false,
      controller: searchController,
      onClearCallback: () => searchController.clear(),
      leadingWidget: _buildSymbolAvatar(),
      buildCustomActionWidget: isGuestUser()
          ? null
          : () {
              // Chat → search/reminder/flag; Inquiry → flag; Call → no actions.
              if (selectedIndex == 0) return _buildChatTabActions();
              if (selectedIndex == 1) return _buildInquiryTabActions();
              return const SizedBox.shrink();
            },
    );
  }

  /// Action row for the Inquiry (business) tab — the flag affordance that
  /// previously lived in `OrderMainChatScreen`'s header.
  Widget _buildInquiryTabActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 14.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.to(() => const OrderFlaggedChatsScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(Icons.flag_outlined, size: 24, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTabActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 14.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.to(() => const ChatSearchScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.search,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => Get.to(() => const ReminderTodoScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.lock_clock,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => Get.to(() => const PersonalFlaggedChatsScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.flag_outlined,
              size: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolAvatar() {
    return InkWell(
      onTap: () => _openProfileDrawer(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: const Icon(
          Icons.more_vert,
          size: 26,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        // Selection mode is only meaningful on chat-style tabs (Chat /
        // Inquiry). The Orders tab uses its own filter UI and never enters
        // selection mode.
        final bool isSelectionMode =
            chatViewController.isChatListSelectionMode.value && (selectedIndex == 0 || selectedIndex == 1);
        return WillPopScope(
          onWillPop: () async {
            if (isSelectionMode) {
              chatViewController.exitChatListSelectionMode();
              return false;
            }
            return true;
          },
          child: Scaffold(
            // The "+" FAB starts a new chat/group — only meaningful on the
            // Chat / Inquiry tabs, not the Call tab.
            floatingActionButton: selectedIndex == 2
                ? null
                : SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                        child: InkWell(
                          onTap: () {
                            if (chatViewController.personalTabSelectedIndex.value == 1) {
                              Get.to(() => ContactsPage(from: "group"));
                            } else {
                              Get.toNamed(RouteHelper.getChatContactsRoute());
                            }
                          },
                          child: Container(
                            // width: 60,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.primaryColor,
                            ),
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.only(left: 12, right: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (chatViewController.personalTabSelectedIndex.value == 1)
                                  CustomText(
                                    "New Group ",
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                Icon(
                                  Icons.add,
                                  color: AppColors.white,
                                ),
                              ],
                            ),
                            // backgroundColor: AppColors.primaryColor,
                            // foregroundColor: Colors.white,
                            // onPressed: () {
                            //
                            //
                            // },
                          ),
                        )),
                  ),
            body: BottomNavHideOnScroll(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    if (isSelectionMode)
                      _buildSelectionSliverAppBar()
                    else
                      SliverAppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        floating: true,
                        snap: true,
                        pinned: false,
                        automaticallyImplyLeading: false,
                        titleSpacing: 0,
                        expandedHeight: 72,
                        flexibleSpace: Container(
                          color: Colors.white,
                          child: _buildCustomAppBar(),
                        ),
                      ),
                    if (!isSelectionMode)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _HomeTabBarDelegate(
                          tabController: _tabController,
                          iconTab: iconTab,
                          postTab: postTab,
                          selectedIndex: selectedIndex,
                          onTabTapped: _onTabTapped,
                        ),
                      ),
                  ];
                },
                body: Container(
                  color: Colors.white,
                  child: TabBarView(
                    // Lock swiping while selecting — otherwise an accidental
                    // pan would leave selection mode on a non-Chat tab.
                    physics: isSelectionMode ? const NeverScrollableScrollPhysics() : null,
                    controller: _tabController,
                    children: [
                      PersonalChatsList(isForwardUI: false),
                      // Inquiry tab: the business lane. Now that `order` is
                      // merged into `business`, former order threads also
                      // surface here. `onlySenderId` keeps it to the user's
                      // own outgoing inquiries/orders (the inverse of the
                      // provider-side Grocery/self-employed views which use
                      // `excludeSenderId: userId`).
                      BusinessChatsList(
                        isForwardUI: false,
                        onlySenderId: userId,
                      ),
                      // Call tab. CallHistoryScreen owns its own scrollable;
                      // detach it from the parent NestedScrollView's inherited
                      // PrimaryScrollController so the inner ListView doesn't
                      // recursively try to attach to it (which blows the stack).
                      PrimaryScrollController.none(
                        child: const CallHistoryScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _selectionActionIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.black),
      onPressed: onPressed,
      splashRadius: 20,
    );
  }

  /// Multi-select AppBar shown when the user long-presses a chat row in the
  /// Chat tab — mirrors the one in `OrderMainChatScreen` so the gesture feels
  /// identical across the chat surfaces. Personal-tab only, so pin/archive
  /// always pass `isBusiness: false`.
  Widget _buildSelectionSliverAppBar() {
    final selectedCount = chatViewController.selectedConversationIds.length;
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => chatViewController.exitChatListSelectionMode(),
          ),
          CustomText(
            "$selectedCount",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ],
      ),
      actions: [
        _selectionActionIcon(Icons.flag_outlined, () {
          final ids = chatViewController.selectedConversationIds.toList();
          if (ids.isEmpty) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _MultiFlagBottomSheet(
              conversationIds: ids,
              onDone: () {
                chatViewController.exitChatListSelectionMode();
              },
            ),
          );
        }),
        _selectionActionIcon(Icons.push_pin_outlined, () {
          final ids = chatViewController.selectedConversationIds.toList();
          final isBiz = selectedIndex == 1;
          final allPinned = ids.every((id) => chatPinArchiveController.isPinned(id, isBusiness: isBiz));
          if (allPinned) {
            chatPinArchiveController.unpinMultiple(ids, isBusiness: isBiz);
          } else {
            chatPinArchiveController.pinMultiple(ids, isBusiness: isBiz);
          }
          chatViewController.exitChatListSelectionMode();
        }),
        _selectionActionIcon(Icons.volume_off_outlined, () {
          // Mute action — placeholder, matches OrderMainChatScreen.
        }),
        _selectionActionIcon(Icons.archive_outlined, () {
          final ids = chatViewController.selectedConversationIds.toList();
          final isBiz = selectedIndex == 1;
          chatPinArchiveController.archiveMultiple(ids, isBusiness: isBiz);
          chatViewController.exitChatListSelectionMode();
        }),
        _selectionActionIcon(Icons.lock_outline, () {
          final ids = chatViewController.selectedConversationIds.toList();
          if (ids.isEmpty) return;
          final isBiz = selectedIndex == 1;
          _handleLockSelectedChats(ids, isBiz);
        }),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          offset: const Offset(0, 40),
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (value) {
            switch (value) {
              case 'mark_unread':
                break;
              case 'select_all':
                final isBiz = selectedIndex == 1;
                final lockedIds = chatLockController.lockedIds(isBiz);
                final allChats = (isBiz
                        ? chatViewController.getBusinessChatListModel?.value.chatList
                                ?.whereType<ChatList>()
                                .toList() ??
                            []
                        : chatViewController.getPersonalChatListModel?.value.chatList
                                ?.whereType<ChatList>()
                                .toList() ??
                            [])
                    .where((c) => !lockedIds.contains(c.conversationId))
                    .toList();
                chatViewController.selectAllChats(allChats);
                break;
              case 'lock_chats':
                break;
              case 'add_favourites':
                break;
              case 'clear_chats':
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'mark_unread', child: Text('Mark as unread')),
            const PopupMenuItem(value: 'select_all', child: Text('Select all')),
            const PopupMenuItem(value: 'lock_chats', child: Text('Lock chats')),
            const PopupMenuItem(value: 'add_favourites', child: Text('Add to Favourites')),
            const PopupMenuItem(value: 'clear_chats', child: Text('Clear chats')),
          ],
        ),
      ],
    );
  }

  /// Lock the currently-selected chats. If no PIN exists yet, route the
  /// user through the [LockedChatsScreen] to create one first — once they
  /// land there a snackbar reminds them to come back and re-select. If a
  /// PIN does exist we just confirm and lock.
  Future<void> _handleLockSelectedChats(List<String> ids, bool isBusiness) async {
    if (!chatLockController.hasPin.value) {
      final created = await Get.to<bool>(() => const LockedChatsScreen());
      // The PIN screen returns nothing on back; recheck the reactive state.
      if (!chatLockController.hasPin.value) {
        commonSnackBar(message: "Set up a PIN first to lock chats.");
        return;
      }
      // ignore: unused_local_variable
      final _ = created; // discard — we trust the reactive `hasPin` value
    }
    final confirmed = await _confirmLockDialog(ids.length);
    if (confirmed != true) return;
    await chatLockController.lockMultiple(ids, isBusiness: isBusiness);
    chatViewController.exitChatListSelectionMode();
    commonSnackBar(message: "Locked ${ids.length} chat${ids.length > 1 ? 's' : ''}");
  }

  Future<bool?> _confirmLockDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const CustomText(
          "Lock Chats",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: CustomText(
          "Move $count chat${count > 1 ? 's' : ''} to your Locked Chats? "
          "They will be hidden behind your PIN.",
          fontSize: 14,
          color: Colors.black87,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const CustomText(
              "Cancel",
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const CustomText(
              "Lock",
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (!mounted) return;
    searchController.clear();
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    setState(() {
      selectedIndex = index;
      selectedSubIndex = 0;
    });
    _emitChatListForTab(index);
  }

  /// Slide-in profile drawer (lifted from OrderMainChatScreen). Opened by
  /// tapping the symbol avatar in the AppBar leading slot.
  void _openProfileDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final authController = Get.find<AuthController>();
    final ctrl = getOrPut(() => AddChatSymbolController());

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close drawer',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: screenWidth * 0.55,
                margin: const EdgeInsets.only(top: 8, left: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);

                              Get.to(() => SymbolViewImages(mySymbols: ctrl.mySymbols));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: (ctrl.mySymbols.isEmpty)
                                    ? null
                                    : SweepGradient(
                                        colors: [
                                          AppColors.symbolBorderRed,
                                          AppColors.symbolBorderBlue,
                                          AppColors.symbolBorderYellow,
                                          AppColors.symbolBorderGreen,
                                          AppColors.symbolBorderRed,
                                        ],
                                      ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: CachedAvatarWidget(
                                  imageUrl: authController.imgPath.value,
                                  size: 52,
                                  borderRadius: 26,
                                  showProfileOnFullScreen: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _drawerMenuItem(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Symbol',
                          iconColor: const Color(0xFF0086FF),
                          bgColor: const Color(0xFFE8F3FF),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => AddChatSymbolScreen());
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.group_add_rounded,
                          label: 'Create Group',
                          iconColor: const Color(0xFF2BB67F),
                          bgColor: const Color(0xFFE6F9F1),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => ContactsPage(from: "group"));
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.palette_rounded,
                          label: 'Background',
                          iconColor: const Color(0xFF9C27B0),
                          bgColor: const Color(0xFFF3E5F5),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => ChatBackgroundScreen());
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Wallet',
                          iconColor: const Color(0xFF0086FF),
                          bgColor: const Color(0xFFE8F3FF),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const WalletChatScreen());
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.lock_rounded,
                          label: 'Lock Chat',
                          iconColor: const Color(0xFFE88D1A),
                          bgColor: const Color(0xFFFFF3E0),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => LockedChatsScreen(
                                  initialIsBusiness: selectedIndex == 1,
                                ));
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.notifications_rounded,
                          label: 'Notification',
                          iconColor: const Color(0xFF2BB67F),
                          bgColor: const Color(0xFFE6F9F1),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => NotificationSettingScreen());
                          },
                        ),
                        _menuDivider(),
                        _drawerMenuItem(
                          icon: Icons.person_add_alt_rounded,
                          label: 'Invite Friend',
                          iconColor: const Color(0xFF9C27B0),
                          bgColor: const Color(0xFFF3E5F5),
                          onTap: () {
                            Navigator.pop(context);
                            commonSnackBar(message: "Coming soon....");
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  Widget _menuDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
    );
  }

  Widget _drawerMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                label,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> iconTab;
  final List<String> postTab;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;

  _HomeTabBarDelegate({
    required this.tabController,
    required this.iconTab,
    required this.postTab,
    required this.selectedIndex,
    required this.onTabTapped,
  });

  static const double _tabsHeight = 32;

  @override
  double get maxExtent => _tabsHeight;

  @override
  double get minExtent => _tabsHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: _tabsHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(postTab.length, (index) {
              bool isSelected = selectedIndex == index;
              return Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 10.0 : 0),
                  child: GestureDetector(
                    onTap: () => onTabTapped(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LocalAssets(
                              imagePath: iconTab[index],
                              width: 16,
                              height: 16,
                              imgColor: isSelected ? AppColors.black28 : AppColors.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: CustomText(
                                postTab[index].tr,
                                fontSize: 14,
                                maxLines: 1,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                                color: isSelected ? AppColors.black28 : AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSelected ? 90 : 0,
                          color: AppColors.primaryColor,
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeTabBarDelegate oldDelegate) =>
      selectedIndex != oldDelegate.selectedIndex || tabController != oldDelegate.tabController;
}

/// Bottom sheet to apply a flag to multiple selected conversations.
/// Mirrors the same widget in `OrderMainChatScreen` — kept local so the two
/// screens stay independent.
class _MultiFlagBottomSheet extends StatefulWidget {
  final List<String> conversationIds;
  final VoidCallback onDone;

  const _MultiFlagBottomSheet({
    required this.conversationIds,
    required this.onDone,
  });

  @override
  State<_MultiFlagBottomSheet> createState() => _MultiFlagBottomSheetState();
}

class _MultiFlagBottomSheetState extends State<_MultiFlagBottomSheet> {
  final flagController = Get.find<ChatFlagController>();
  String? selectedFlagId;

  @override
  void initState() {
    super.initState();
    final flags = widget.conversationIds.map((id) => flagController.getFlagForConversation(id)).toSet();
    if (flags.length == 1 && flags.first != null) {
      selectedFlagId = flags.first!.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "Label ${widget.conversationIds.length} Chat${widget.conversationIds.length > 1 ? 's' : ''}",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showAddFlagLabelDialog(context, flagController);
                },
                child: const CustomText(
                  "+ New Label",
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: flagController.allFlags.length,
                itemBuilder: (context, index) {
                  final flag = flagController.allFlags[index];
                  final isSelected = selectedFlagId == flag.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedFlagId = isSelected ? null : flag.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? flag.color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? Border.all(color: flag.color, width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: flag.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              flag.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              flag.label,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: flag.color, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    for (final id in widget.conversationIds) {
                      flagController.removeFlagFromConversation(id);
                    }
                    Navigator.pop(context);
                    widget.onDone();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText(
                    "Remove Label",
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedFlagId == null
                      ? null
                      : () {
                          final flag = flagController.allFlags.firstWhere((f) => f.id == selectedFlagId);
                          for (final id in widget.conversationIds) {
                            flagController.assignFlagToConversation(id, flag);
                          }
                          Navigator.pop(context);
                          widget.onDone();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText(
                    "Apply",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/* Old _HomeScreenState removed - DO NOT DELETE
(Preserved for reference only)
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;
  final List<String> postTab = [
    AppStrings.allPosts,
    AppStrings.channel,
    AppStrings.tab_ott,
    AppStrings.tab_saved,
  ];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  late SavedFeedTab _selectedSavedTab;
  final homeScreenController = Get.put(HomeScreenController());

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);

    initPlatformState();
    getPackageData();
    searchController.addListener(() {
      setState(() {});
    });
    _selectedSavedTab = SavedFeedTab.posts;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _calculateHeaderHeight();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    searchController.dispose();

    super.dispose();
  }

  ///DO NOT DELETE THIS CODE.....
  SharedMedia? sharedMedia;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;

    // App opened from share intent
    handler.getInitialSharedMedia().then((SharedMedia? media) {
      setState(() => sharedMedia = media);
      if (media?.content?.isNotEmpty ?? false) {
        _openChatScreen(media!);
      }
      if (media?.attachments?.isNotEmpty ?? false) {
        _openChatScreen(media!);
      }
    });

    // App running, receiving new share
    handler.sharedMediaStream.listen((SharedMedia media) {
      setState(() => sharedMedia = media);
      _openChatScreen(media);
    });
  }

  void _openChatScreen(SharedMedia media) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        final _sharedText = media.content;
        List<SharedAttachment?>? attachments = media.attachments ?? [];

        if (_sharedText != null && _sharedText.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeAvailableContactsList(sharedText: _sharedText),
            ),
          );
        } else if ((attachments.isNotEmpty)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeAvailableContactsList(sharedFiles: attachments),
            ),
          );
        }
      }
    });
  }

  Future<void> getPackageData() async {
    if (!mounted) return;
    PackageInfo _packageInfo = await PackageManager.getPackageInfo();
    _checkForUpdate(context, _packageInfo);
  }

  Future<void> _checkForUpdate(
      BuildContext context, PackageInfo packageInfo) async {
    try {
      if (Platform.isAndroid) {
        InAppUpdateManager manager = InAppUpdateManager();
        AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();
        if (appUpdateInfo == null) return;
        if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress) {
          //If an in-app update is already running, resume the update.
          String? message =
              await manager.startAnUpdate(type: AppUpdateType.immediate);
          debugPrint(message ?? '');
        } else if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          ///Update available
          if (appUpdateInfo.immediateAllowed) {
            String? message =
                await manager.startAnUpdate(type: AppUpdateType.immediate);
            debugPrint(message ?? '');
          } else if (appUpdateInfo.flexibleAllowed) {
            String? message =
                await manager.startAnUpdate(type: AppUpdateType.flexible);
            debugPrint(message ?? '');
          } else {
            debugPrint(
                'Update available. Immediate & Flexible Update Flow not allow');
          }
        }
      } else if (Platform.isIOS) {
        VersionInfo? _versionInfo = await UpgradeVersion.getiOSStoreVersion(
            packageInfo: packageInfo, regionCode: "US");
        debugPrint(_versionInfo.toJson().toString());
      }
    } catch (e) {
      debugPrint("Error checking for update: $e");
    }
  }

  void _calculateHeaderHeight() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() => _headerHeight = renderBox.size.height);
    }
  }

  void _toggleAppBarAndBottomNav(bool visible) {
    if (widget.isHeaderVisible != visible && mounted) {
      homeScreenController.isVisible.value = visible;
      widget.onHeaderVisibilityChanged
          .call(visible); // Notify parent to hide/show bottom nav
    }
  }

  Widget _buildCustomAppBar() {
    return CommonBackAppBar(
      isDrawerMenu: true,
      isLeading: false,
      isMore: true,
      isSearch: true,
      isProfile: false,
      isNotification: !isGuestUser(),
      bellIconNotEmpty: true,
      isGuestLogout: isGuestUser(),
      controller: searchController,
      onClearCallback: () => searchController.clear(),
      onNotificationTap: () {
        Navigator.pushNamed(
          context,
          RouteHelper.getNotificationScreenRoute(),
        );
      },
      // onProfileTap: widget.onProfileTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,

        body: Obx(() => Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (_headerHeight *
                          (1 - homeScreenController.headerOffset.value))),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _calculateHeaderHeight();
                      });
                    },
                    children: isIndividual()
                        ? [
                            if (selectedIndex == 0)
                              HomeFeedScreenNew(
                                key: ValueKey('feedScreen_all'),
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                                postFilterType: PostType.all,
                                query: searchController.text.isEmpty
                                    ? null
                                    : searchController.text,
                                headerHeight: _headerHeight,
                                isInParentScroll: false,
                              ),
                            if (selectedIndex == 1)
                              ChannelFeedScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 2)
                              OttScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 3)
                              SavedFeedScreen(
                                  onHeaderVisibilityChanged:
                                      _toggleAppBarAndBottomNav,
                                  query: searchController.text,
                                  selectedTab: _selectedSavedTab,
                                  headerHeight:
                                      _headerHeight + SizeConfig.size30),
                          ]
                        : [
                            if (selectedIndex == 0)
                              HomeFeedScreenNew(
                                key: ValueKey('feedScreen_all'),
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                                postFilterType: PostType.all,
                                query: searchController.text.isEmpty
                                    ? null
                                    : searchController.text,
                                headerHeight: _headerHeight,
                                isInParentScroll: false,
                              ),
                            if (selectedIndex == 1)
                              ChannelFeedScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 2)
                              OttScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 3)
                              SavedFeedScreen(
                                  onHeaderVisibilityChanged:
                                      _toggleAppBarAndBottomNav,
                                  query: searchController.text,
                                  selectedTab: _selectedSavedTab,
                                  headerHeight:
                                      _headerHeight + SizeConfig.size30),
                          ],
                  ),
                ),

                /// Header stays same
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  top: -homeScreenController.headerOffset.value * _headerHeight,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _headerKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomAppBar(),
                        SizedBox(height: SizeConfig.size15),
                        HorizontalTabSelector(
                          tabs: postTab,
                          selectedIndex: selectedIndex,
                          onTabSelected: (index, value) {
                            if (mounted) {
                              searchController.clear();
                              setState(() => selectedIndex = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              resetScrollingOnTabChanged();
                            }
                          },
                          labelBuilder: (label) => label,
                        ),
                        SizedBox(height: SizeConfig.size10),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  void resetScrollingOnTabChanged() {
    homeScreenController.isVisible.value = true;
    widget.onHeaderVisibilityChanged.call(homeScreenController.isVisible.value);
    homeScreenController.headerOffset.value = 0.0;
  }
}
*/
