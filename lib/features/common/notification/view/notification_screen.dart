import 'package:BlueEra/core/navigation/me_profile_navigator.dart';
import 'dart:async';

import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/services/deep_link_router.dart';
import 'package:BlueEra/core/services/notification_tracking_service.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/admob_banner_ad_widget.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_history_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/common/connect/view/connect_main_page.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_screen.dart';
import 'package:BlueEra/features/common/notification/controller/notification_hub_controller.dart';
import 'package:BlueEra/features/common/notification/model/notification_model.dart';
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
import 'package:BlueEra/widgets/app_popup_menu_button.dart';
import 'package:BlueEra/core/routes/safe_back.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final NotificationHubController controller =
      Get.find<NotificationHubController>();

  List<TabItem> notificationFilters = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        controller.searchQuery.value = searchController.text;
      });
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 && controller.canLoadMore) {
      controller.loadMore();
    }
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
              _buildNotificationList(),

              // Anchored banner under the list. Safe at the BOTTOM here (and
              // not on the Connect chat list) because this is a pushed route
              // with its own back app bar — no bottom nav underneath for the
              // strip to sit against. It collapses to zero height when there
              // is no fill, so the list keeps the full screen either way.
              const AdMobBannerAdWidget(
                margin: EdgeInsets.only(top: 4, bottom: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return HorizontalTabSelector(
        tabs: notificationFilters,
        selectedIndex: controller.selectedTab.value,
        onTabSelected: (index, value) {
          // Tabs filter the locally-cached "all" stream client-side — no API
          // call per tab switch.
          setState(() {
            controller.selectedTab.value = index;
          });
        },
        labelBuilder: (TabItem label) => label.title);
  }

  Widget _buildNotificationList() {
    return Expanded(
      child: Obx(() {
        final List<NotificationDataList> visible = controller.visible;

        // First-ever load with nothing cached yet → spinner.
        if (visible.isEmpty &&
            controller.isSyncing.value &&
            controller.cache.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (visible.isEmpty) {
          // Keep pull-to-refresh reachable even on the empty state.
          return RefreshIndicator(
            onRefresh: controller.syncFirstPage,
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
            controller.showsMore;
        return RefreshIndicator(
          onRefresh: controller.syncFirstPage,
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

                  // Admin campaign rows have no sender profile, so their
                  // leading slot would otherwise be an empty placeholder and
                  // the row would read as plain text — which is what gets
                  // scrolled past. Fall back to the campaign artwork (a video
                  // promo's still, or a promotion's `imageUrl`). Sender avatar
                  // still wins wherever there is one, so no person-to-person
                  // notification changes.
                  final String imageUrl = [
                    data.senderProfile?.profileImage ?? '',
                    data.metadata?.videoThumbnail ?? '',
                    data.metadata?.imageUrl ?? '',
                  ].firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
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
                        controller.markRead(id);
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
                        MeProfileNavigator.openOverviewIfLoggedIn();
                      }
                      // A user who opens the LIST instead of the banner must
                      // reach the same screen — otherwise an engagement push
                      // works and the inbox row it left behind is a dead end.
                      // Same resolver, same tracking as the push tap.
                      else if (operation == "admin_promotion") {
                        final meta = data.metadata?.toJson() ?? {};
                        unawaited(NotificationTracking.report(
                          meta,
                          kind: 'open',
                        ));
                        final link = NotificationTracking.deepLinkOf(meta);
                        final uri = link == null ? null : Uri.tryParse(link);
                        if (uri != null) {
                          unawaited(
                            DeepLinkRouter.routeOrDefer(uri).then(
                              (_) => NotificationTracking.report(
                                meta,
                                kind: 'convert',
                              ),
                            ),
                          );
                        }
                        // No link: the user is already on the list the push
                        // would have sent them to, so the read-flip above is
                        // the whole interaction. Deliberately no `safeBack()` —
                        // closing the inbox on a nudge with nowhere to go
                        // would look like the tap failed.
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
                      else if (data.type == "CONTACT_JOINED" ||
                          data.type == "USER_ENROLLED" ||
                          operation.toLowerCase() == "contact_joined" ||
                          operation.toLowerCase() == "user_enrolled") {
                        // A phonebook contact joined BlueEra — open their chat
                        // so the user can actually say hello. The empty chat
                        // carries a "View Profile" button, so the profile this
                        // used to open is still one tap away. Same destination
                        // as the push tap; see
                        // GUEST_CONTACT_JOINED_AND_CHAT_VIEW_PROFILE_GUIDE.md §5.
                        _openJoinedContactChat(data);
                      }
                      else if (NotificationHubController.isCallNotification(data)) {
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
                        safeBack();
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
                                    AppPopupMenuButton<String>(
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
    final symbol = await controller.fetchSymbol(symbolId);
    if (symbol == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    Get.to(() => SymbolViewImages(
          initialSymbol: symbol,
          userId: symbol.userId,
          name: symbol.user?.name,
          profileImage: symbol.user?.profileImage,
        ));
  }

  /// CONTACT_JOINED / USER_ENROLLED row tap → open the joiner's personal chat.
  /// The contact id comes from the payload's `contactUserId`; falls back to the
  /// sender profile when the backend only fills that in. Routed through
  /// [ConnectMainPage.openJoinedContactChat] so this row and the push tap share
  /// one set of guards and fallbacks (empty id, self, no session, offline).
  void _openJoinedContactChat(NotificationDataList data) {
    ConnectMainPage.openJoinedContactChat(
      JoinedContactChatRequest.fromPayload({
        'contactUserId': data.metadata?.contactUserId,
        'senderId': data.senderProfile?.id,
        'sentBy': data.sentBy,
        'senderName': data.senderProfile?.name,
        'profileImage': data.senderProfile?.profileImage,
      }),
    );
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
                          onTap: () => safeBack(),
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
          if (!mounted) return;
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
      await controller.deleteAll();
      commonSnackBar(message: AppStrings.allNotificationsDeleted.tr);
    } else if (await controller.deleteOne(notifyId)) {
      commonSnackBar(message: AppStrings.notificationDeleted.tr);
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
