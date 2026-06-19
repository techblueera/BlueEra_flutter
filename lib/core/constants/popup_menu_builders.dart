// ignore_for_file: constant_identifier_names

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/chat/auth/controller/add_chat_symbol_controller.dart';
import '../../features/chat/view/chat_theme/chat_background_screen.dart';
import '../../features/chat/view/contacts/view/contact_list_page.dart';
import '../../features/chat/view/symbol_view/symbol_view_images.dart';
import '../../features/chat/view/add_symbol/add_symbol_screen.dart';
import '../../features/personal/personal_profile/view/manage_notification/notification.dart';
import '../../features/chat/view/wallet_chat/wallet_chat_screen.dart';

class PopupMenuBuilders {
  static List<PopupMenuEntry<PostCreationMenu>> popupMenuItems() {
    final bool isBusiness =
        accountTypeGlobal.toUpperCase() == AppConstants.business;

    final List<PostCreationMenu> items = [
      PostCreationMenu.message,
      PostCreationMenu.symbol,
      PostCreationMenu.poll,

      /// Reel/short upload — available to business accounts and to individual
      /// users who already created a channel (matches the old `videos` gate).
      if (isBusiness || channelId.isNotEmpty) PostCreationMenu.reel,
      if (isBusiness) PostCreationMenu.jobPost,
      // PostCreationMenu.place,
      // PostCreationMenu.travel,
    ];

    const iconMap = {
      PostCreationMenu.message: AppIconAssets.message_post,
      // PostCreationMenu.symbol:  AppIconAssets.message_post,
      PostCreationMenu.symbol: "assets/icons/add_symbol_color.png",
      PostCreationMenu.poll: AppIconAssets.qa_ask_questionOutlinedIcon,
      // PostCreationMenu.photos: AppIconAssets.photosOutlinedIcon,
      PostCreationMenu.reel: AppIconAssets.video_outline,
      PostCreationMenu.jobPost: AppIconAssets.uilSuitcaseOutlinedIcon,
      // PostCreationMenu.place: AppIconAssets.locationOutlineIconGreyIcon,
      // PostCreationMenu.travel: AppIconAssets.travelOutlinedIcon,
    };

    const titleMap = {
      PostCreationMenu.message: AppStrings.lekha,
      PostCreationMenu.poll: AppStrings.poll,
      PostCreationMenu.symbol: AppStrings.symbol,
      // PostCreationMenu.photos: AppStrings.symbol,
      PostCreationMenu.reel: 'Reel',
      PostCreationMenu.jobPost: AppStrings.jobPost,
      // PostCreationMenu.travel: AppStrings.travel,
    };

    final List<PopupMenuEntry<PostCreationMenu>> entries = [];

    for (var i = 0; i < items.length; i++) {
      final menu = items[i];
      entries.add(
        PopupMenuItem<PostCreationMenu>(
          height: SizeConfig.size35,
          value: menu,
          child: Row(
            children: [
              LocalAssets(
                imagePath: iconMap[menu]!,
                width: 25,
                height: 25,
              ),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                titleMap[menu]!,
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<PostCreationMenu>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> inventoryPopupMenuItems() {
    final items = <Map<String, dynamic>>[
      {"id": "ADD_PRODUCT", 'title': 'Add Product'},
      {"id": "BUSINESS_CARDS", 'title': AppStrings.myBusinessCard}
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['id'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.6,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupMenuResumeCardItems() {
    final items = <Map<String, dynamic>>[
      {
        "id": "EDIT",
        'icon': AppIconAssets.tablerEditIcon,
        'title': AppStrings.edit
      },
      {
        "id": "SHARE",
        'icon': AppIconAssets.uploadIcon,
        'title': AppStrings.share
      },
      {
        "id": "DOWNLOAD",
        'icon': AppIconAssets.downloadIcon,
        'title': AppStrings.download
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['id'],
          onTap: () {
            if (items[i]['id'] == "EDIT") {
              Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
            }
            if (items[i]['id'] == "SHARE") {}
            if (items[i]['id'] == "DOWNLOAD") {
              // Get.toNamed(RouteHelper.getResumeTemplateScreenRoute());
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                  imagePath: items[i]['icon'],
                  height: SizeConfig.size20,
                  width: SizeConfig.size20),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupMenuOrderTabItems() {
    final items = <Map<String, dynamic>>[
      {"id": "PENDING", 'title': AppStrings.pending},
      {"id": "COMPLETED", 'title': AppStrings.completed},
      {"id": "CANCELED", 'title': AppStrings.canceled},
      {"id": "LATEST", 'title': AppStrings.latest},
      {"id": "OLDEST", 'title': AppStrings.oldest},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['id'],
          onTap: () {
            if (items[i]['id'] == "EDIT") {
              Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
            }
            if (items[i]['id'] == "SHARE") {}
            if (items[i]['id'] == "DOWNLOAD") {
              // Get.toNamed(RouteHelper.getResumeTemplateScreenRoute());
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.6,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupMenuChatCardItems() {
    final items = <Map<String, dynamic>>[
      {
        "id": "ADD_SYMBOL",
        'title': "Add Symbol",
        'icon': Icons.add_circle_outline
      },
      {"id": "VIEW_SYMBOL", 'title': "View Symbol", 'icon': Icons.auto_awesome},
      {
        "id": "CREATE_GROUP",
        'title': AppStrings.createGroup,
        'icon': Icons.group_add
      },
      {
        "id": "BACKGROUND",
        'title': AppStrings.background,
        'icon': Icons.wallpaper
      },
      {
        "id": "LOCK_CHAT",
        'title': AppStrings.lockChat,
        'icon': Icons.lock_outline
      },
      {"id": "LINKED_DEVICE", 'title': "Linked Device", 'icon': Icons.devices},
      {
        "id": "NOTIFICATION",
        'title': "Notification",
        'icon': Icons.notifications_outlined
      },
      {
        "id": "INVITE_FRIEND",
        'title': "Invite Friend",
        'icon': Icons.person_add_alt_1_outlined
      },
      {
        "id": "WALLET",
        'title': "Wallet",
        'icon': Icons.account_balance_wallet_outlined
      },
      {
        "id": "PRIVATE_ROOM",
        'title': "Private Room",
        'icon': Icons.meeting_room_outlined
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['id'],
          onTap: () {
            if (items[i]['id'] == "ADD_SYMBOL") {
              Get.to(() => AddChatSymbolScreen());
            } else if (items[i]['id'] == "VIEW_SYMBOL") {
              final addSymbolController =
                  Get.isRegistered<AddChatSymbolController>()
                      ? Get.find<AddChatSymbolController>()
                      : Get.put(AddChatSymbolController());
              Get.to(() => SymbolViewImages(
                    mySymbols: addSymbolController.mySymbols,
                  ));
            } else if (items[i]['id'] == "CREATE_GROUP") {
              Get.to(() => ContactsPage(
                    from: "group",
                  ));
            } else if (items[i]['id'] == "BACKGROUND") {
              Get.to(() => ChatBackgroundScreen());
            } else if (items[i]['id'] == "LOCK_CHAT") {
              commonSnackBar(message: "Coming soon....");
            } else if (items[i]['id'] == "LINKED_DEVICE") {
              commonSnackBar(message: "Coming soon....");
            } else if (items[i]['id'] == "NOTIFICATION") {
              Get.to(() => NotificationSettingScreen());
            } else if (items[i]['id'] == "INVITE_FRIEND") {
              commonSnackBar(message: "Coming soon....");
            } else if (items[i]['id'] == "WALLET") {
              Get.to(() => const WalletChatScreen());
            } else if (items[i]['id'] == "PRIVATE_ROOM") {
              commonSnackBar(message: "Coming soon....");
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i]['icon'], size: 18, color: AppColors.black30),
              const SizedBox(width: 8),
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupMenuVisitProfileItems() {
    final items = <Map<String, dynamic>>[
      {
        "id": "SHARE",
        'icon': AppIconAssets.share_bold,
        'slud_id': 'Share',
        'title': AppStrings.share
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          // onTap: () {
          //
          //   if (items[i]['id'] == "SHARE") {}
          //
          // },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                imagePath: items[i]['icon'],
                height: SizeConfig.size20,
                width: SizeConfig.size20,
              ),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                items[i]['title'],
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupMenuVisitProfileActionItems(
      {bool? isSavePost, bool? isShowSaveOption = true}) {
    final items = <Map<String, dynamic>>[
      if (isShowSaveOption == true)
        {
          "id": "SAVE",
          'icon': AppIconAssets.save_new,
          'title': (isSavePost ?? false) ? AppStrings.unsave : AppStrings.save,
          'slud_id': (isSavePost ?? false) ? "Unsave" : "Save"
        },
      {
        "id": "REPORT_POST",
        'icon': AppIconAssets.report_new,
        'slud_id': 'Report Post',
        'title': AppStrings.reportPost,
      },
      {
        "id": "BLOCK_USER",
        'icon': AppIconAssets.block_user,
        'slud_id': 'Block User',
        'title': AppStrings.blockUser
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                imagePath: items[i]['icon'],
                height: SizeConfig.size20,
                width: SizeConfig.size20,
              ),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                items[i]['title'],
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupPostMenuItems(bool? is_reposted) {
    final items = <Map<String, dynamic>>[
      if ((is_reposted == null) || (is_reposted == false))
        {'title': AppStrings.editPost, "slud_id": 'Edit Post'},
      {'title': AppStrings.deletePost, "slud_id": "Delete Post"},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popPupMenuForAiChat() {
    final items = <Map<String, dynamic>>[
      {'title': "Change Profile", "slud_id": 'change_profile'},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  /// Three-dot menu for the AI chat screen: mute (toggles label/icon based on
  /// [isMuted]), language, clear chat and background.
  static List<PopupMenuEntry<String>> popupMenuForAiChatOptions(bool isMuted) {
    final items = <Map<String, dynamic>>[
      {
        'title': isMuted ? 'Unmute' : 'Mute',
        'slud_id': 'mute',
        'icon': isMuted
            ? Icons.notifications_off
            : Icons.notifications_active_outlined,
      },
      {'title': 'Language', 'slud_id': 'language', 'icon': Icons.language},
      {'title': 'Clear Chat', 'slud_id': 'clear', 'icon': Icons.delete_outline},
      {
        'title': 'Background',
        'slud_id': 'background',
        'icon': Icons.wallpaper_outlined
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i]['icon'], size: 18, color: AppColors.black30),
              const SizedBox(width: 8),
              CustomText(
                items[i]['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popPupMenuForPersonalChat() {
    final items = <Map<String, dynamic>>[
      {'title': "Report", "slud_id": 'report'},
      {'title': "Block", "slud_id": 'block'},
      {'title': "Clear Chat", "slud_id": 'clear_chat'},
      {'title': "Media & Docs", "slud_id": 'media_docs'},
      {'title': "Chat Theme", "slud_id": 'chat_theme'},
      {'title': "Add Shortcut", "slud_id": 'add_shortcut'},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popPupMenuForGroupChat() {
    final items = <Map<String, dynamic>>[
      {'title': "Clear Chat", "slud_id": 'clear_chat'},
      {'title': "Background Change", "slud_id": "background_change"},
      {'title': "Exit Group", "slud_id": "exit_group"},
      {'title': "Pin Group", "slud_id": "pin_group"},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupVideoMenuItems() {
    final items = <Map<String, dynamic>>[
      {
        'slud_id': 'Edit Video',
        'title': AppStrings.editVideo,
      },
      {'slud_id': 'Delete Video', 'title': AppStrings.deleteVideo},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupShortsMenuItems() {
    final items = <Map<String, dynamic>>[
      {'title': 'Edit Short'},
      {'title': 'Delete Short'},
      {'title': 'Change Thumbnail'},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['title'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupProductMenuItems() {
    final items = <Map<String, dynamic>>[
      {'slud_id': 'Edit Product', 'title': AppStrings.editProduct},
      {'slud_id': 'Delete Product', 'title': AppStrings.deleteProduct},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> photoPostMenuItems() {
    final items = <Map<String, dynamic>>[
      {
        'id': "Square",
        'title': AppStrings.square,
        'icon': Icons.square_outlined
      },
      {
        'id': "Portrait",
        'title': AppStrings.portrait,
        'icon': Icons.crop_portrait_outlined
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      final menu = items[i];
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['id'],
          child: Row(
            children: [
              Icon(menu['icon'], color: AppColors.grey5B),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                menu['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> groceryPopUpMenuItems() {
    final List<Map<String, String>> items = [
      {
        'id': AppConstants.EDIT,
        'title': 'Edit Product',
        'icon': AppIconAssets.pen_line
      },
      {
        'id': AppConstants.REMOVE,
        'title': 'Remove From List',
        'icon': AppIconAssets.removeOutlinedIcon
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (var i = 0; i < items.length; i++) {
      final menu = items[i];
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: menu['id'],
          child: Row(
            children: [
              LocalAssets(imagePath: menu['icon']!),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                menu['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> medicalPopUpMenuItems() {
    final List<Map<String, String>> items = [
      {
        'id': AppConstants.EDIT,
        'title': 'Edit Product',
        'icon': AppIconAssets.pen_line
      },
      {
        'id': AppConstants.REMOVE,
        'title': 'Remove From List',
        'icon': AppIconAssets.removeOutlinedIcon
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (var i = 0; i < items.length; i++) {
      final menu = items[i];
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: menu['id'],
          child: Row(
            children: [
              LocalAssets(imagePath: menu['icon']!),
              SizedBox(width: SizeConfig.size5),
              CustomText(
                menu['title'],
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
            ],
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }

  static List<PopupMenuEntry<String>> popupSchoolDepartmentMenuItems() {
    final items = <Map<String, dynamic>>[
      {'title': AppStrings.editPost, "slud_id": 'Edit'},
      {'title': AppStrings.deletePost, "slud_id": "Delete"},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['slud_id'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }
}
