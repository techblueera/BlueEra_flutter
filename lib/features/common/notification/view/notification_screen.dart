import 'dart:async';

import 'package:BlueEra/core/api/model/tab_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_screen.dart';
import 'package:BlueEra/features/common/notification/model/notification_model.dart';
import 'package:BlueEra/features/common/notification/notification_repo.dart';
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
  List<NotificationDataList> allNotifications = [];
  late List<NotificationDataList> filteredNotifications;
  bool isLoading = true;
  List<TabItem> notificationFilters = [];

  int selectedIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    filteredNotifications = [...allNotifications];
    fetchNotification(filterType: "all");

    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    }); // To show/hide clear icon
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchNotification({required String filterType}) async {
    try {
      filteredNotifications.clear();
      allNotifications.clear();
      isLoading = true;
      final response = await NotificationListRepo()
          .fetchNotificationRepo(filterType: filterType);
      if (response.isSuccess) {
        final data = response.response!.data;

        final List<NotificationDataList> fetchedData =
            List<NotificationDataList>.from(
          (data['data'] as List).map((e) => NotificationDataList.fromJson(e)),
        );

        setState(() {
          allNotifications = fetchedData;
          filteredNotifications = fetchedData;
        });
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteNotification({required String? notifyId}) async {
    try {
      final response = await NotificationListRepo()
          .deleteNotification(notifyId: notifyId ?? "");

      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.notificationDeleted.tr);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final response = await NotificationListRepo().deleteAllNotification();

      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.allNotificationsDeleted.tr);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    filterNotifications(query);
  }

  void filterNotifications(String query) {
    setState(() {
      filteredNotifications = allNotifications
          .where((notification) => (notification.message ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
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

  String? getTypeFromTabLabel(String label) {
    switch (label) {
      case "Chat":
        return "CHAT";
      case "Orders":
        return "ORDERS";
      case "Tags":
        return "TAGS";
      case "Jobs":
        return "JOBS";
      case "Posts":
        return "POSTS";
      default:
        return null; // "All"
    }
  }

  Widget _buildTabButtons() {
    return HorizontalTabSelector(
        tabs: notificationFilters,
        selectedIndex: selectedIndex,
        onTabSelected: (index, value) {
          setState(() {
            selectedIndex = index;

            final String? selectedType = getTypeFromTabLabel(value);

            fetchNotification(filterType: selectedType?.toLowerCase() ?? "all");

            // if (selectedType == null) {
            //   // Show all
            //   filteredNotifications = allNotifications;
            // } else {
            //   filteredNotifications = allNotifications
            //       .where((notification) => notification.type == selectedType)
            //       .toList();
            // }
          });
        },
        labelBuilder: (TabItem label) => label.title);
  }

  Widget _buildNotificationList() {
    return Expanded(
        child: filteredNotifications.isNotEmpty
            ? ListView.builder(
                itemCount: filteredNotifications.length,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                    top: SizeConfig.paddingXSL, bottom: SizeConfig.size20),
                itemBuilder: (_, index) {
                  final data = filteredNotifications[index];
                  final isLast = index == filteredNotifications.length - 1;

                  final String imageUrl =
                      data.senderProfile?.profileImage ?? '';
                  final String id = data.sId ?? "";
                  final String title = (data.message?.isNotEmpty ?? false)
                      ? (data.message ?? data.metadata?.message ?? "")
                      : (data.metadata?.message ?? "");
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
                      final data = filteredNotifications[index];
                      if (data.status == "UNREAD") {
                        NotificationListRepo().notificationReadRepo(
                            notificationId: data.sId ?? "");
                      }
                      if (data.type == "SYMBOL_CREATED") {
                        _openSymbol(data);
                      }
                      else if (data.notification_type == "jobs") {
                        redirectJobPost(jobID: data.metadata?.jobId ?? "");
                      }
                      else if(data.notification_type == "posts"){
                        Get.to(() => PostDeatilPage(), arguments: {"postId": data.metadata?.jobId ?? ""});
                      }
                      else {
                        redirectToProfileScreen(
                          accountType: data.senderProfile?.account_type ?? "",
                          profileId: data.senderProfile?.id ?? "",
                        );
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
                                  child: CustomText(
                                    title,
                                    maxLines: 3,
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                    color: AppColors.mainTextColor,
                                    fontSize: SizeConfig.small,
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
              )
            : EmptyStateWidget(message: AppStrings.noNotificationsFound.tr));
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
      // ✅ Clear all notifications
      try {
        final response = await NotificationListRepo().deleteAllNotification();

        if (response.isSuccess) {
          commonSnackBar(
              message:
                  response.message ?? AppStrings.allNotificationsDeleted.tr);

          setState(() {
            allNotifications.clear();
            filteredNotifications.clear();
          });
        } else {
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } else {
      if (notifyId == null || notifyId.isEmpty) return;

      try {
        final response =
            await NotificationListRepo().deleteNotification(notifyId: notifyId);

        if (response.isSuccess) {
          commonSnackBar(
              message: response.message ?? AppStrings.notificationDeleted.tr);

          setState(() {
            allNotifications.removeWhere((item) => item.sId == notifyId);
            filteredNotifications.removeWhere((item) => item.sId == notifyId);
          });
        } else {
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
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
