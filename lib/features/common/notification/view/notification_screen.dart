import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_history_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_screen.dart';
import 'package:BlueEra/features/common/notification/model/notification_model.dart';
import 'package:BlueEra/features/common/notification/notification_repo.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Local-first store: the list is served from here (Hive-backed) so opening
  /// the hub, switching tabs, marking read and deleting never wait on the API.
  final NotificationCacheService cache = NotificationCacheService.to;

  /// Client-side filter/search state. Reactive so the Obx list rebuilds without
  /// manual setState juggling.
  final RxString _searchQuery = ''.obs;
  final RxBool _isSyncing = false.obs;
  final RxBool _isLoadingMore = false.obs;

  /// Stable filter ids (decoupled from the localized tab titles) used for
  /// client-side filtering of the cached "all" stream.
  static const List<String> _tabIds = ['All', 'Orders', 'Tags', 'Jobs', 'Posts'];

  List<TabItem> notificationFilters = [];

  int selectedIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        _searchQuery.value = searchController.text;
      });
    });

    _scrollController.addListener(_onScroll);

    // Serve the cache instantly; only touch the network once per app session
    // (or when the cache is empty). Incoming pushes keep the cache fresh in the
    // meantime, so re-opening the hub is a pure local read.
    if (!cache.syncedThisSession || cache.items.isEmpty) {
      _syncFirstPage();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// Pagination only makes sense on the "All" tab — the filter tabs slice the
  /// already-cached stream client-side, so there are no extra server pages to
  /// pull for them.
  bool get _isAllTab => selectedIndex == 0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        _isAllTab &&
        cache.hasMore &&
        !_isLoadingMore.value &&
        !_isSyncing.value &&
        _searchQuery.value.isEmpty) {
      _loadMore();
    }
  }

  /// Parse the visible (hub-eligible) items out of a list response. Chat
  /// text/broadcast messages belong to the Chat section and are excluded here.
  List<NotificationDataList> _parseVisible(dynamic data) {
    final list = (data is Map ? data['data'] : null);
    if (list is! List) return [];
    return list
        .map((e) => NotificationDataList.fromJson(e))
        .where((n) => !_isChatMessageNotification(n))
        .toList();
  }

  bool _hasNext(dynamic data, int returnedCount) {
    final pg = data is Map ? data['pagination'] : null;
    if (pg is Map && pg['hasNextPage'] is bool) return pg['hasNextPage'] as bool;
    return returnedCount >= NotificationCacheService.pageLimit;
  }

  /// Authoritative refresh of page 1 → replaces the cache (keeping any newer
  /// push-only rows). Also the pull-to-refresh handler.
  Future<void> _syncFirstPage() async {
    if (_isSyncing.value) return;
    _isSyncing.value = true;
    try {
      final response = await NotificationListRepo().fetchNotificationRepo(
        filterType: "all",
        page: 1,
        limit: NotificationCacheService.pageLimit,
      );
      if (response.isSuccess) {
        final data = response.response!.data;
        final visible = _parseVisible(data);
        await cache.replaceWithServerPage(
          visible,
          hasNext: _hasNext(data, visible.length),
        );
      }
    } catch (e) {
      // Keep whatever is cached — offline / transient failures degrade to the
      // last known list rather than an empty screen.
      print("Notification sync error: $e");
    } finally {
      _isSyncing.value = false;
    }
  }

  /// Fetch the next older page on scroll and merge it into the cache.
  Future<void> _loadMore() async {
    if (_isLoadingMore.value) return;
    _isLoadingMore.value = true;
    final nextPage = cache.loadedPages + 1;
    try {
      final response = await NotificationListRepo().fetchNotificationRepo(
        filterType: "all",
        page: nextPage,
        limit: NotificationCacheService.pageLimit,
      );
      if (response.isSuccess) {
        final data = response.response!.data;
        final visible = _parseVisible(data);
        await cache.appendServerPage(
          visible,
          page: nextPage,
          hasNext: _hasNext(data, visible.length),
        );
      }
    } catch (e) {
      print("Notification load-more error: $e");
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Client-side tab filter over the cached "all" stream.
  bool _matchesTab(NotificationDataList n, String tabId) {
    final type = (n.notification_type ?? '').toLowerCase();
    switch (tabId) {
      case 'Orders':
        return type == 'orders';
      case 'Tags':
        return type == 'tags';
      case 'Jobs':
        return type == 'jobs';
      case 'Posts':
        return type == 'posts';
      default:
        return true; // "All"
    }
  }

  /// The rows to render: cache filtered by the active tab + search query.
  List<NotificationDataList> _computeVisible() {
    final tabId = _tabIds[selectedIndex.clamp(0, _tabIds.length - 1)];
    final q = _searchQuery.value.toLowerCase().trim();
    return cache.items.where((n) {
      if (_isChatMessageNotification(n)) return false;
      if (!_matchesTab(n, tabId)) return false;
      if (q.isEmpty) return true;
      return (n.message ?? '').toLowerCase().contains(q) ||
          (n.metadata?.title ?? '').toLowerCase().contains(q) ||
          (n.metadata?.body ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    notificationFilters = [
      TabItem(id: 'All', title: AppStrings.all.tr),
      TabItem(id: 'Orders', title: AppStrings.orders.tr),
      TabItem(id: 'Tags', title: AppStrings.tagsText.tr),
      TabItem(id: 'Jobs', title: AppStrings.jobs.tr),
      TabItem(id: 'Posts', title: AppStrings.posts.tr),
    ];
    return Scaffold(
      appBar: CommonBackAppBar(
          isSearch: true,
          controller: searchController,
          onClearCallback: () {
            searchController.clear();
          },
          iClearButton: true,
          onClearNotificationsTap: () {
            clearAllNotifications(0);
          },
          isSettingButton: false),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔘 Filter Chips
              _buildTabButtons(),

              // 📋 Notification List
              _buildNotificationList()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return HorizontalTabSelector(
        tabs: notificationFilters,
        selectedIndex: selectedIndex,
        onTabSelected: (index, value) {
          // Tabs filter the locally-cached "all" stream client-side — no API
          // call per tab switch.
          setState(() {
            selectedIndex = index;
          });
        },
        labelBuilder: (TabItem label) => label.title);
  }

  Widget _buildNotificationList() {
    return Expanded(
      child: Obx(() {
        final List<NotificationDataList> visible = _computeVisible();

        // First-ever load with nothing cached yet → spinner.
        if (visible.isEmpty && _isSyncing.value && cache.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (visible.isEmpty) {
          // Keep pull-to-refresh reachable even on the empty state.
          return RefreshIndicator(
            onRefresh: _syncFirstPage,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: SizeConfig.screenHeight * 0.25),
                EmptyStateWidget(message: AppStrings.noNotificationsFound.tr),
              ],
            ),
          );
        }

        final bool showFooter =
            _isAllTab && cache.hasMore && _searchQuery.value.isEmpty;
        return RefreshIndicator(
          onRefresh: _syncFirstPage,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: visible.length + (showFooter ? 1 : 0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
                top: SizeConfig.paddingXSL, bottom: SizeConfig.size20),
            itemBuilder: (_, index) {
              if (index >= visible.length) {
                // Pagination footer loader.
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final data = visible[index];
              final isLast = index == visible.length - 1;

                  final String imageUrl =
                      data.senderProfile?.profileImage ?? '';
                  final String id = data.sId ?? "";
                  // Display text resolution: many notifications (AI greetings,
                  // ride status updates, profile reminders) leave the top-level
                  // `message` empty and put their content in metadata.title /
                  // metadata.body. Build a bold heading + detail line so none of
                  // these rows render blank.
                  final String topMsg = (data.message ?? '').trim();
                  final String metaMsg = (data.metadata?.message ?? '').trim();
                  final String metaTitle = (data.metadata?.title ?? '').trim();
                  final String metaBody = (data.metadata?.body ?? '').trim();
                  // First non-empty among: top-level message → metadata.message
                  // → metadata.body.
                  final String bodyText = [topMsg, metaMsg, metaBody]
                      .firstWhere((s) => s.isNotEmpty, orElse: () => '');
                  // Bold heading only when it adds info beyond the body line.
                  final String headerText =
                      (metaTitle.isNotEmpty && metaTitle != bodyText)
                          ? metaTitle
                          : '';
                  // Title used for the fullscreen image viewer / a11y label.
                  final String title = headerText.isNotEmpty
                      ? headerText
                      : (bodyText.isNotEmpty
                          ? bodyText
                          : (data.metadata?.senderName ?? ''));
                  final String status = data.status ?? '';
                  String time = '';
                  try {
                    if (data.createdAt != null && data.createdAt!.isNotEmpty) {
                      final parsedDate = DateTime.tryParse(data.createdAt!);
                      if (parsedDate != null) {
                        time = timeAgoFormatted(parsedDate);
                      }
                    }
                  } catch (_) {
                    time = '';
                  }
                  return InkWell(
                    onTap: () {
                      if (data.status == "UNREAD") {
                        // Optimistic: flip read locally now, sync to the server
                        // in the background. Skip the API for push-only rows
                        // (synthetic `local_…` ids the server doesn't know yet).
                        cache.markRead(id);
                        if (id.isNotEmpty && !id.startsWith('local_')) {
                          NotificationListRepo()
                              .notificationReadRepo(notificationId: id);
                        }
                      }
                      // Redirect off the backend operation key first: it's
                      // present even when `notification_type` is null (e.g.
                      // profile_completion_reminder), so it drives routing more
                      // reliably than the coarse type. Falls through to the
                      // existing type-based handling when the operation isn't one
                      // we redirect explicitly (or is missing entirely).
                      final String operation =
                          (data.metadata?.originalOperation ?? data.type ?? '')
                              .trim();
                      if (operation == "profile_completion_reminder") {
                        _redirectToMeOverview();
                      }
                      else if (operation == "admin_broadcast") {
                        // Open the in-app "BlueEra" broadcast thread via the
                        // same path a push tap uses. Warm app resolves the row
                        // from the chat list; ids are passed for the fallback.
                        AppNotificationHandler.openBlueEraChat({
                          'senderId':
                              data.senderProfile?.id ?? data.sentBy ?? '',
                          'conversationId':
                              data.metadata?.conversationId ?? '',
                        });
                      }
                      else if (data.type == "SYMBOL_CREATED") {
                        _openSymbol(data);
                      }
                      else if (_isCallNotification(data)) {
                        // incoming_call / missed_call / call_cancelled share
                        // notification_type "chat" with messages, so branch on
                        // `type` first and send them to the call history screen.
                        Get.to(() => const CallHistoryScreen(showAppBar: true));
                      }
                      else if (data.notification_type == "chat") {
                        redirectToChat(data);
                      }
                      else if (data.notification_type == "jobs") {
                        redirectJobPost(jobID: data.metadata?.jobId ?? "");
                      }
                      else if(data.notification_type == "posts"){
                        Get.to(() => PostDeatilPage(), arguments: {"postId": data.metadata?.jobId ?? ""});
                      }
                      else {
                        Get.back();
                        // redirectToProfileScreen(
                        //   accountType: data.senderProfile?.account_type ?? "",
                        //   profileId: data.senderProfile?.id ?? "",
                        // );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          color: status == "UNREAD"
                              ? AppColors.greyE0
                              : Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size10,
                                horizontal: SizeConfig.size15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Center(
                                    child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: status == "UNREAD"
                                      ? AppColors.primaryColor
                                      : AppColors.transparent,
                                )),
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: SizeConfig.size5),
                                  child: InkWell(
                                    onTap: () {
                                      navigatePushTo(
                                        context,
                                        ImageViewScreen(
                                          appBarTitle: title,
                                          imageUrls: [imageUrl],
                                          initialIndex: 0,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          top: SizeConfig.size2),
                                      child: CachedAvatarWidget(
                                        imageUrl: imageUrl,
                                        size: SizeConfig.size45,
                                        borderRadius: SizeConfig.size30,
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.black1F,
                                              offset: Offset(0, 2))
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (headerText.isNotEmpty) ...[
                                        CustomText(
                                          headerText,
                                          maxLines: 2,
                                          fontWeight: FontWeight.w700,
                                          overflow: TextOverflow.ellipsis,
                                          color: AppColors.mainTextColor,
                                          fontSize: SizeConfig.small,
                                        ),
                                        SizedBox(height: SizeConfig.size2),
                                      ],
                                      CustomText(
                                        bodyText.isNotEmpty ? bodyText : title,
                                        maxLines: 3,
                                        fontWeight: headerText.isNotEmpty
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                        overflow: TextOverflow.ellipsis,
                                        color: headerText.isNotEmpty
                                            ? AppColors.secondaryTextColor
                                            : AppColors.mainTextColor,
                                        fontSize: SizeConfig.small,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    CustomText(time),
                                    SizedBox(
                                      height: SizeConfig.size2,
                                    ),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          clearAllNotifications(1,
                                              notifyId: id);
                                        }
                                      },
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          padding: EdgeInsets.zero,
                                          // REMOVE EXTRA PADDING
                                          height: 20,
                                          // padding: EdgeInsets.symmetric(
                                          //     horizontal: SizeConfig.size8),
                                          child: Center(
                                            child: CustomText(
                                              AppStrings.delete.tr,
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.mainTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                      child: Icon(Icons
                                          .more_vert), // Your trigger widget
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          CommonHorizontalDivider(
                            color: AppColors.whiteE0,
                          )
                      ],
                    ),
                  );
            },
          ),
        );
      }),
    );
  }

  Future<void> _openSymbol(NotificationDataList data) async {
    final symbolId = data.metadata?.symbolId ?? "";
    if (symbolId.isEmpty) return;
    try {
      final response = await SymbolRepo().getSymbolById(symbolId);
      if (response.isSuccess && response.data != null) {
        final responseData = Map<String, dynamic>.from(response.data);
        final symbolJson = Map<String, dynamic>.from(responseData['symbol'] ?? {});
        if (responseData['creator'] != null) {
          symbolJson['user'] = responseData['creator'];
        }
        final symbol = SymbolDetailsModel.fromJson(symbolJson);
        Get.to(() => SymbolViewImages(
              initialSymbol: symbol,
              userId: symbol.userId,
              name: symbol.user?.name,
              profileImage: symbol.user?.profileImage,
            ));
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  // Call notifications (incoming/missed/cancelled) are delivered under the
  // "chat" notification_type, so they're distinguished by their `type`.
  bool _isCallNotification(NotificationDataList data) {
    const callTypes = {"incoming_call", "missed_call", "call_cancelled"};
    return callTypes.contains(data.type);
  }

  // A chat message notification (personal / group / broadcast) that should be
  // hidden from this list. Calls share the "chat" notification_type but are
  // not messages, so they are excluded from the hide rule.
  bool _isChatMessageNotification(NotificationDataList data) {
    return data.notification_type == "chat" && !_isCallNotification(data);
  }

  // profile_completion_reminder → the logged-in user's own "Me" → Overview
  // tab, which hosts the profile-completion card. No-op for logged-out users
  // (nothing to complete without a session). When the bottom-nav shell is live
  // we pop back to it and switch tabs; otherwise we route to the shell fresh.
  void _redirectToMeOverview() {
    if (!isLoggedIn()) return;
    if (Get.isRegistered<BottomBarController>()) {
      Get.until((route) => route.isFirst);
      Get.find<BottomBarController>().openMeOverviewTab();
    } else {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: BottomBarController.meTabIndex},
      );
    }
  }

  void redirectToChat(NotificationDataList data) {
    final String conversationId = data.metadata?.conversationId ?? "";
    final String userId = data.senderProfile?.id ?? data.sentBy ?? "";
    Get.to(() => PersonalChatScreen(
          conversationId: conversationId,
          userId: userId,
          type: data.senderProfile?.account_type ??
              AppConstants.personal_Chat_Type,
          name: data.senderProfile?.name ?? data.metadata?.senderName,
          profileImage: data.senderProfile?.profileImage,
          isInitialMessage: conversationId.isEmpty,
        ));
  }

  void redirectJobPost({required String jobID}) {
    if (isIndividual()) {
      Get.to(() => JobDetailScreen(
            jobId: jobID,
            isPostApply: AppConstants.APPLY_NOW,
            isPostDirection: AppConstants.DIRECTION,
            isPostEdit: '',
            isPostCreate: '',
          ));
    }
    if (isBusiness()) {
      Get.to(() => JobDetailScreen(
            jobId: jobID,
            isPostDirection: '',
            isPostApply: '',
            isPostEdit: '',
            isPostCreate: '',
          ));
    }
  }

  Future<void> clearAllNotifications(int selected, {String? notifyId}) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          backgroundColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            margin: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: SizeConfig.size16,
                top: SizeConfig.size8),
            // margin: EdgeInsets.symmetric(
            //     vertical: SizeConfig.size30, horizontal: SizeConfig.size40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: SizeConfig.size7,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.goldenNotificationIcon),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      selected == 0
                          ? AppStrings.clearAllNotifications.tr
                          : AppStrings.clearNotification.tr,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.mainTextColor,
                    ),
                    Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () => Get.back(),
                          child: Icon(
                            Icons.close,
                            color: AppColors.secondaryTextColor,
                          ),
                        )),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size7,
                ),
                CustomText(
                    selected == 0
                        ? AppStrings.clearAllDescription.tr
                        : AppStrings.clearDescription.tr,
                    fontSize: SizeConfig.medium,
                    textAlign: TextAlign.center,
                    color: AppColors.secondaryTextColor),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                          Navigator.pop(context, false);
                        },
                        title: AppStrings.cancel.tr,
                        textColor: AppColors.secondaryTextColor,
                        bgColor: AppColors.white,
                        borderColor: AppColors.secondaryTextColor,
                        radius: 8.0,
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size10,
                    ),
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                          if (selected == 0) {
                            handleNotificationDelete(0);
                          } else {
                            handleNotificationDelete(1, notifyId: notifyId);
                          }
                          Navigator.pop(context, false);
                          setState(() {});
                        },
                        title: selected == 0
                            ? AppStrings.clearAll.tr
                            : AppStrings.clear.tr,
                        isValidate: true,
                        bgColor: AppColors.red02,
                        radius: 8.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    ).then(
      (value) {
        if (value == true) {
          setState(() {
            // widget.getNotificationsModel.data = [];
          });
        }
      },
    );
  }

  Future<void> handleNotificationDelete(int selected,
      {String? notifyId}) async {
    if (selected == 0) {
      // ✅ Clear all — remove from the local cache immediately, then sync the
      // server in the background (push-only rows never existed server-side).
      await cache.clear();
      commonSnackBar(message: AppStrings.allNotificationsDeleted.tr);
      try {
        await NotificationListRepo().deleteAllNotification();
      } catch (_) {
        // Local state already cleared; a failed server call self-heals on the
        // next successful sync.
      }
    } else {
      if (notifyId == null || notifyId.isEmpty) return;

      // ✅ Single delete — optimistic local removal, background server delete
      // (skipped for synthetic push-only ids the server doesn't know).
      await cache.remove(notifyId);
      commonSnackBar(message: AppStrings.notificationDeleted.tr);
      if (!notifyId.startsWith('local_')) {
        try {
          await NotificationListRepo().deleteNotification(notifyId: notifyId);
        } catch (_) {}
      }
    }
  }
}

class NotificationData {
  final String avatarUrl;
  final String title;
  final String timeAgo;

  NotificationData({
    required this.avatarUrl,
    required this.title,
    required this.timeAgo,
  });
}
