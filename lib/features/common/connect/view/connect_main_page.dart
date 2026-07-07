import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

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
import 'package:BlueEra/features/chat/view/bookmarks/bookmarks_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_history_screen.dart';
import 'package:BlueEra/features/chat/view/chat_theme/chat_background_screen.dart';
import 'package:BlueEra/features/chat/view/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/chat/view/flag_chat/order_flagged_chats_screen.dart';
import 'package:BlueEra/features/chat/view/flag_chat/personal_flagged_chats_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/chat_search_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/view/reminder_chat/reminder_todo_screen.dart';
import 'package:BlueEra/features/chat/view/starred_chat/starred_messages_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_chat_list_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/chat/view/wallet_chat/wallet_chat_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/order_history/view/local_orders_list_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/manage_notification/notification.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../../chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../../chat/view/lock_chat/locked_chats_screen.dart';
import '../../../chat/view/widget/chat_flag_bottom_sheet.dart';
import '../../../personal/personal_profile/controller/languge_list_controller.dart';
import 'inquiry_ride_order_selection_screen.dart';
import '../widget/customer_ongoing_ride_card.dart';
import '../../../../core/services/ongoing_ride_store.dart';
import '../../../chat/auth/repo/chat_view_repo.dart';
import '../../../chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import '../../Discover/controller/discover_controller.dart';

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

  /// One-shot worker that forces a single rebuild once the Inquiry tab's
  /// business chat list finishes loading. The "New" tag in each row is
  /// derived from `updatedAt` at build time; on the very first paint the
  /// rows are laid out before the freshly-arrived data settles, so the tag
  /// is missed until something rebuilds the tab. This re-runs the tile
  /// builders exactly once after the list completes so the tag shows
  /// without the user having to navigate away and back.
  Worker? _inquiryNewTagWorker;

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
    if (initialTab == 1) _armInquiryNewTagRefresh();
    // Fire-and-forget: fetch the full chat export once on home entry.
    // Response is only logged right now (see ChatViewController.getChatExportAll).
    chatViewController.getChatExportAll();

    _loadContactsFromStorage();
    // Restore the customer "Your Ongoing Ride/Booking" card after an app
    // relaunch (the in-memory overlay state is lost when the app is killed).
    _restoreOngoingRideIfNeeded();
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

  /// Rebuild the customer ongoing-ride card from the persisted snapshot on app
  /// relaunch, then confirm with the order-status API that the ride is still
  /// active (clearing it if it ended while the app was closed). Re-seeds the
  /// [DiscoverController] fare-call state so tapping the card resumes the live
  /// tracking screen.
  Future<void> _restoreOngoingRideIfNeeded() async {
    final overlayCtrl = getOrPut(() => RideNavigationOverlayController());
    // Already tracking this session (e.g. minimized just now) — nothing to do.
    if (overlayCtrl.hasOngoingCustomerRide) return;

    final snap = await OngoingRideStore.read();
    if (snap == null) return;
    final orderId = (snap['orderId'] ?? '').toString();
    if (orderId.isEmpty) {
      await OngoingRideStore.clear();
      return;
    }

    double toD(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    // 1) Optimistically rebuild the card from the snapshot.
    overlayCtrl.restoreCustomerRide(
      orderId: orderId,
      riderName: (snap['riderName'] ?? '').toString(),
      riderImageVal: (snap['riderImage'] ?? '').toString(),
      riderContactVal: (snap['riderContact'] ?? '').toString(),
      pickupLabel: (snap['pickupLabel'] ?? '').toString(),
      dropLabelVal: (snap['dropLabel'] ?? '').toString(),
      bookingTimeLabelVal: (snap['bookingTimeLabel'] ?? '').toString(),
      riderLatVal: toD(snap['riderLat']),
      riderLngVal: toD(snap['riderLng']),
      pickupLat: toD(snap['pickupLat']),
      pickupLng: toD(snap['pickupLng']),
    );

    // 2) Re-seed DiscoverController so opening the card resumes live tracking.
    final dc = getOrPut(() => DiscoverController());
    final riderId = (snap['riderId'] ?? '').toString();
    if (riderId.isNotEmpty) dc.fareCallAcceptedRiderId.value = riderId;
    dc.fareCallAcceptedRiderInfo.value = {
      'riderId': riderId,
      'name': (snap['riderName'] ?? '').toString(),
      'profileImage': (snap['riderImage'] ?? '').toString(),
      'contact': (snap['riderContact'] ?? '').toString(),
    };
    dc.fareCallOrderId.value = orderId;
    dc.selectedFromLat?.value = toD(snap['pickupLat']);
    dc.selectedFromLong?.value = toD(snap['pickupLng']);
    dc.selectedFromAddress?.value = (snap['pickupLabel'] ?? '').toString();
    dc.selectedToLat?.value = toD(snap['dropLat']);
    dc.selectedToLong?.value = toD(snap['dropLng']);
    dc.selectedToAddress?.value = (snap['dropLabel'] ?? '').toString();

    // 3) Confirm the ride is still ongoing via the suitable API. A terminal
    // status clears the card; transient failures keep the optimistic card.
    try {
      final res = await ChatViewRepo().checkTrackOrderStatusSilentApi(orderId);
      if (res.isSuccess) {
        final status =
            res.response?.data?['status']?.toString().toLowerCase() ?? '';
        if (status == 'completed' ||
            status == 'cancelled' ||
            status == 'rejected') {
          await OngoingRideStore.clear();
          overlayCtrl.clearRideData();
        }
      }
    } catch (_) {}
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
      if (selectedIndex == 1) _armInquiryNewTagRefresh();
    }
  }

  /// Arm a single forced rebuild for when the Inquiry (business) chat list
  /// next completes loading, so the recently-created "New" tags surface on
  /// the first visit instead of only after a manual rebuild. Re-armed on
  /// every entry to the tab; the previous worker is disposed first so we
  /// never stack listeners.
  void _armInquiryNewTagRefresh() {
    _inquiryNewTagWorker?.dispose();
    _inquiryNewTagWorker = once<ApiResponse>(
      chatViewController.businessChatListResponse,
      (_) {
        if (mounted) setState(() {});
      },
      condition: () =>
          chatViewController.businessChatListResponse.value.status ==
          Status.COMPLETE,
    );
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
    _inquiryNewTagWorker?.dispose();
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
      // Transparent so the frosted-glass flexibleSpace behind it shows through.
      appBarColor: Colors.transparent,
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

  /// Action row for the Inquiry (business) tab — basket + rider shortcuts and
  /// the flag affordance that previously lived in `OrderMainChatScreen`'s
  /// header. Shown only on the Inquiry tab.
  Widget _buildInquiryTabActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              // Open the same drop-location bottom sheet used by the
              // self-pickup order card's "Ride" action. On confirm, open the
              // inquiry-order selection screen for the chosen drop location.
              final drop = await showRideDropLocationSheet(context);
              if (drop != null) {
                Get.to(() =>
                    InquiryRideOrderSelectionScreen(dropAddress: drop));
              }
            },
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child: SvgPicture.asset(
                AppIconAssets.riderIcon,
                width: 22,
                height: 18,
                colorFilter:
                    const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // TODO: wire to the basket/orders destination.
              commonSnackBar(message: "Coming soon....");
            },
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Get.to(() => const OrderFlaggedChatsScreen()),
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child: const Icon(Icons.flag_outlined,
                  size: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTabActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.to(() => const ChatSearchScreen()),
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child: const Icon(Icons.search, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Get.to(() => const ReminderTodoScreen()),
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child:
                  const Icon(Icons.lock_clock, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Get.to(() => const PersonalFlaggedChatsScreen()),
            customBorder: const CircleBorder(),
            child: _glassCircle(
              child: const Icon(Icons.flag_outlined,
                  size: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolAvatar() {
    return InkWell(
      onTap: () => _openProfileDrawer(context),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _glassCircle(
          child: const Icon(Icons.more_vert, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  /// Circular frosted-glass chip for the header icons — same recipe as the
  /// order_main_chat header chips (translucent white over the blurred banner,
  /// hairline border, faint lift).
  Widget _glassCircle({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: CircleBorder()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return SafeArea(
      // Top inset is handled by the frosted status-bar strip sliver so the
      // glass header extends behind the status bar (like the Me tab) while the
      // app bar + tabs stay below the notch.
      top: false,
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
            // Transparent so the app-wide background banner (AppHomeBackground)
            // shows through and the glass header can frost it.
            backgroundColor: Colors.transparent,
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
            body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // Frosted status-bar strip — always pinned so the glass
                    // extends behind the notch and the app bar / tabs never
                    // slide under the status bar.
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StatusBarGlassDelegate(topInset),
                    ),
                    if (isSelectionMode)
                      _buildSelectionSliverAppBar()
                    else
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        floating: true,
                        snap: true,
                        pinned: false,
                        // Status-bar inset is owned by the strip above.
                        primary: false,
                        automaticallyImplyLeading: false,
                        titleSpacing: 0,
                        // Snug to the app bar (~56) so there isn't a big empty
                        // band below the header before the tabs.
                        expandedHeight: 56,
                        // Frosted-glass header that blurs the app-wide banner,
                        // mirroring the Me-screen headers. removePadding stops
                        // the inner AppBar from re-adding the status-bar inset
                        // (already handled by the strip above).
                        flexibleSpace: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.45),
                              child: MediaQuery.removePadding(
                                context: context,
                                removeTop: true,
                                child: _buildCustomAppBar(),
                              ),
                            ),
                          ),
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
                      // Chat tab: same customer "Your Ongoing Ride/Booking"
                      // card sits above the personal chat list (collapses to
                      // nothing when there is no ongoing ride).
                      Column(
                        children: [
                          const CustomerOngoingRideCard(),
                          Expanded(
                            child: PersonalChatsList(isForwardUI: false),
                          ),
                        ],
                      ),
                      // Inquiry tab: the business lane. Now that `order` is
                      // merged into `business`, former order threads also
                      // surface here. This is the buyer/general business view,
                      // so it renders the [ChatBucket.chats] bucket (my buyer
                      // orders, friends' orders, groups) via the default
                      // `bucketChat` routing — the inverse of the provider-side
                      // Grocery/self-employed views which pass
                      // `excludeSenderId: userId` to show the seller's "me"
                      // (stranger customers) bucket.
                      //
                      // NOTE: do NOT pass `onlySenderId` here. It is a legacy
                      // last-message-author filter that predates `bucketChat`
                      // and silently drops every row whose latest message was
                      // sent by the other party (e.g. "New self-pickup food
                      // order" from a customer), emptying the tab.
                      // Inquiry tab: a customer "Your Ongoing Ride/Booking"
                      // card (when a ride/goods booking is being tracked) sits
                      // above the business chat list. The card collapses to
                      // nothing when there is no ongoing ride.
                      Column(
                        children: [
                          const CustomerOngoingRideCard(),
                          Expanded(
                            child: BusinessChatsList(
                              isForwardUI: false,
                              // Flag conversations created in the last 4 hours
                              // with a "New" label below the time in the
                              // Inquiry tab.
                              showNewIfRecentlyCreated: true,
                            ),
                          ),
                        ],
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
      // Status-bar inset is owned by the pinned glass strip above.
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
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
                        // Opens the WhatsApp-status-style list of everyone with
                        // an active symbol (the users shown with the multi-colour
                        // ring in the chat lists). "Add Symbol" sits on top; each
                        // row opens that user's symbols in the fullscreen viewer.
                        _drawerMenuItem(
                          icon: Icons.web_stories_rounded,
                          label: AppStrings.symbols.tr,
                          iconColor: const Color(0xFFE91E63),
                          bgColor: const Color(0xFFFDE6EF),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const SymbolChatListScreen());
                          },
                        ),
                        _menuDivider(),
                        // Local order history from the Discover section, shown
                        // as a WhatsApp-style chat-list (one thread per shop).
                        _drawerMenuItem(
                          icon: Icons.receipt_long_rounded,
                          label: AppStrings.myOrdersTitle.tr,
                          iconColor: const Color(0xFFE88D1A),
                          bgColor: const Color(0xFFFFF3E0),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const LocalOrdersListScreen());
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
                          icon: Icons.star_rounded,
                          label: AppStrings.starredMessagesLabel.tr,
                          iconColor: const Color(0xFFE8B100),
                          bgColor: const Color(0xFFFFF8E1),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const StarredMessagesScreen());
                          },
                        ),
                        _menuDivider(),
                        // Locally saved chat photos, grouped by person.
                        _drawerMenuItem(
                          icon: Icons.bookmark_rounded,
                          label: 'Bookmarks',
                          iconColor: const Color(0xFF0086FF),
                          bgColor: const Color(0xFFE8F3FF),
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const BookmarksScreen());
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

/// Pinned frosted-glass strip occupying the status-bar inset, so the glass
/// chrome extends behind the notch while the app bar / tabs stay below it.
class _StatusBarGlassDelegate extends SliverPersistentHeaderDelegate {
  final double height;

  _StatusBarGlassDelegate(this.height);

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (height <= 0) return const SizedBox.shrink();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: height,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StatusBarGlassDelegate oldDelegate) =>
      oldDelegate.height != height;
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

  static const double _tabsHeight = 36;

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
            // Stretch each tab to the full strip height so the per-tab Column
            // can center its label and pin the underline to the bottom.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(postTab.length, (index) {
              bool isSelected = selectedIndex == index;
              return Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 10.0 : 0),
                  child: GestureDetector(
                    onTap: () => onTabTapped(index),
                    child: Column(
                      children: [
                        // Label vertically centered in the cell; the underline
                        // pinned to the bottom — same text↔underline gap as the
                        // Material TabBar on order_main_chat.
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSelected ? 90 : 0,
                          color: AppColors.primaryColor,
                        ),
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
