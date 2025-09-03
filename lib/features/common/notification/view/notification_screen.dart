import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
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

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
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
  final List<String> notificationFilters = [
    "All",
    "Chats",
    "Orders",
    "Tags",
    "Jobs",
    "Posts"
  ];
  int selectedIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchNotification();
    // context.read<NotificationsBloc>().add(GetNotificationsEvent());
    filteredNotifications = [...allNotifications];
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    }); // To show/hide clear icon
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  


  Future<void> fetchNotification() async {
    try {
      isLoading = true;
      final response = await NotificationListRepo().fetchNotification();
      if (response.statusCode == 200) {
        final data = response.response!.data;

        final List<NotificationDataList> fetchedData = List<NotificationDataList>.from(
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
      final response = await NotificationListRepo().deleteNotification(notifyId: notifyId ?? "");

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? 'Notification deleted successfully');
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final response = await NotificationListRepo().deleteAllNotification();

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? 'All notifications deleted successfully');
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
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
          .where((notification) =>
          (notification.message ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          isSearch: true,
          controller: searchController,
          onClearCallback: () {
            searchController.clear();
          },
          iClearButton: true,
          onClearNotificationsTap: (){
            clearAllNotifications(0);
          },
          isSettingButton: true),
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
      case "Chats":
        return "CHATS";
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
            if (selectedType == null) {
              // Show all
              filteredNotifications = allNotifications;
            } else {
              filteredNotifications = allNotifications
                  .where((notification) => notification.type == selectedType)
                  .toList();
            }
          });
        },
        labelBuilder: (String label) => label);
  }

  Widget _buildNotificationList() {
    return Expanded(
        child: filteredNotifications.isNotEmpty
            ? ListView.builder(
              itemCount: filteredNotifications.length,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(top: SizeConfig.paddingXSL, bottom: SizeConfig.size20),
              itemBuilder: (_, index) {
                final data = filteredNotifications[index];
                final isLast = index == filteredNotifications.length - 1;

                final String imageUrl = data.user?.profileImage ?? '';
                final String id = data.sId??"";
                final String title = data.message ?? '';
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
                return Column(
                  children: [
                    Container(
                      color: status == "UNREAD"
                          ? AppColors.greenE0
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
                                backgroundColor:(index == 0 || index == 1)? AppColors.primaryColor : AppColors.transparent,
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
                                  padding: EdgeInsets.only(top: SizeConfig.size2),
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
                                maxLines: 2,
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
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      clearAllNotifications(1,notifyId: id);
                                    }
                                  },
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                                      child: Center(
                                        child: CustomText(
                                          'Delete',
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.mainTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  child: Icon(Icons.more_vert), // Your trigger widget
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
                );
              },
            )
            : EmptyStateWidget(message: "No notifications found"));
  }

  // Widget _buildNotificationList() {
  //   return Expanded(
  //     child: ListView.builder(
  //       itemCount: 15,
  //       keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  //       padding: EdgeInsets.all(SizeConfig.size15),
  //       itemBuilder: (_, index) {
  //
  //         return Row(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             InkWell(
  //               onTap: () {
  //                 navigatePushTo(
  //                     context,
  //                     ImageViewScreen(
  //                       appBarTitle: AppLocalizations.of(context)!.imageViewer,
  //                       imageUrls: [
  //                           'https://randomuser.me/api/portraits/men/32.jpg'
  //                       ],
  //                       initialIndex: 0,
  //                     )
  //                 );
  //               },
  //               child: Padding(
  //                 padding: EdgeInsets.symmetric(
  //                     vertical: SizeConfig.size8),
  //                 child: CircleAvatar(
  //                   radius: SizeConfig.size32,
  //                   backgroundColor: AppColors.orange35,
  //                   child: CachedCircleAvatar(
  //                     imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
  //                     radius: SizeConfig.size30,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             SizedBox(width: SizeConfig.size12),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 CustomText(
  //                     'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis),
  //                 SizedBox(width: SizeConfig.size5),
  //                 CustomText(
  //                   '1m ago.',
  //                   color: AppColors.grey9A,
  //                 ),
  //
  //                 // widget
  //                 //     .getNotificationsModel
  //                 //     .data![index]
  //                 //     .type ==
  //                 //     'LIKE' ||
  //                 //     widget
  //                 //         .getNotificationsModel
  //                 //         .data![index]
  //                 //         .type ==
  //                 //         'POST'
  //                 //     ? TextButton(
  //                 //     onPressed: () {
  //                 //       Navigator.pop(context);
  //                 //       // Navigator.push(
  //                 //       //     context,
  //                 //       //     MaterialPageRoute(
  //                 //       //         builder: (context) => SinglePostScreen(
  //                 //       //             postId: widget
  //                 //       //                 .getNotificationsModel
  //                 //       //                 .data![
  //                 //       //             index]
  //                 //       //                 .metadata!
  //                 //       //                 .postId
  //                 //       //                 .toString())));
  //                 //     },
  //                 //     style: ButtonStyle(
  //                 //         padding: WidgetStateProperty.all<
  //                 //             EdgeInsets>(
  //                 //             EdgeInsets.zero)),
  //                 //     child: Text(
  //                 //       "goToPost",
  //                 //       style: TextStyle(
  //                 //           color:
  //                 //           AppColors.white,
  //                 //           fontWeight:
  //                 //           FontWeight.bold),
  //                 //     ))
  //                 //     : widget
  //                 //     .getNotificationsModel
  //                 //     .data![index]
  //                 //     .type ==
  //                 //     'CONNECTION_RECEIVED'
  //                 //     ? TextButton(
  //                 //     style: ButtonStyle(
  //                 //         padding:
  //                 //         WidgetStateProperty.all<EdgeInsets>(
  //                 //             EdgeInsets.zero)),
  //                 //     onPressed: () {
  //                 //       Navigator.pop(
  //                 //           context);
  //                 //       // Navigator.pushReplacement(
  //                 //       //     context,
  //                 //       //     MaterialPageRoute(
  //                 //       //         builder: (context) => const Dashboard(
  //                 //       //             selectedTab:
  //                 //       //             0,
  //                 //       //             currentIndex:
  //                 //       //             0,
  //                 //       //             changeScreenTo:
  //                 //       //             '',
  //                 //       //             showDialog:
  //                 //       //             false)));
  //                 //     },
  //                 //     child: Text(
  //                 //       "goToRequests",
  //                 //       style: TextStyle(
  //                 //         // color: AppColors
  //                 //         //     .primaryColor,
  //                 //           color: AppColors
  //                 //               .white,
  //                 //           fontWeight:
  //                 //           FontWeight
  //                 //               .bold),
  //                 //     ))
  //                 //     : TextButton(
  //                 //     onPressed: () {
  //                 //       Navigator.pop(
  //                 //           context);
  //                 //       // Navigator.pushReplacement(
  //                 //       //     context,
  //                 //       //     MaterialPageRoute(
  //                 //       //         builder: (context) => const Dashboard(
  //                 //       //             selectedTab:
  //                 //       //             0,
  //                 //       //             currentIndex:
  //                 //       //             0,
  //                 //       //             changeScreenTo:
  //                 //       //             '',
  //                 //       //             showDialog:
  //                 //       //             false)));
  //                 //     },
  //                 //     style: ButtonStyle(padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero)),
  //                 //     child: Text(
  //                 //       '${"send"} ${widget.getNotificationsModel.data![index].metadata!.name!} ${"aMessage"}',
  //                 //       style: const TextStyle(
  //                 //           color: AppColors
  //                 //               .primaryColor,
  //                 //           fontWeight:
  //                 //           FontWeight
  //                 //               .bold),
  //                 //     ))
  //
  //               ],
  //             )
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }

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
            margin: EdgeInsets.symmetric(
                vertical: SizeConfig.size30, horizontal: SizeConfig.size40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.goldenNotificationIcon),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      selected == 0?"Clear All Notifications?":"Clear Notification?",
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.black30,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size7,
                ),
                CustomText(
                    selected == 0? "This will remove all your current notifications. You won’t be able to view them again.":"This will remove your current notifications. You won’t be able to view them again.",
                    fontSize: SizeConfig.medium,
                    textAlign: TextAlign.center,
                    color: AppColors.black30),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    Expanded(
                        child: IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: CustomText(
                        "Cancel",
                        fontSize: SizeConfig.large,
                        color: AppColors.black30,
                      ),
                    )),
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                         if(selected == 0){
                           handleNotificationDelete(0);
                         }else{
                           handleNotificationDelete(1,notifyId: notifyId);
                         }
                          Navigator.pop(context, false);
                          setState(() {});
                        },
                        title: selected == 0? "Clear All":"Clear",
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


  Future<void> handleNotificationDelete(int selected, {String? notifyId}) async {
    if (selected == 0) {
      // ✅ Clear all notifications
      try {
        final response = await NotificationListRepo().deleteAllNotification();

        if (response.isSuccess) {
          commonSnackBar(message: response.message ?? 'All notifications deleted successfully');

          setState(() {
            allNotifications.clear();
            filteredNotifications.clear();
          });
        } else {
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } else {
      if (notifyId == null || notifyId.isEmpty) return;

      try {
        final response = await NotificationListRepo().deleteNotification(notifyId: notifyId);

        if (response.isSuccess) {
          commonSnackBar(message: response.message ?? 'Notification deleted successfully');

          setState(() {
            allNotifications.removeWhere((item) => item.sId == notifyId);
            filteredNotifications.removeWhere((item) => item.sId == notifyId);
          });
        } else {
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
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
