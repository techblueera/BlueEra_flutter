import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/add_chat_symbol_controller.dart';
import '../add_symbol/add_symbol_screen.dart';
import '../chat_theme/chat_background_screen.dart';
import '../contacts/view/contact_list_page.dart';
import '../symbol_view/symbol_view_images.dart';
import '../../../../features/personal/personal_profile/view/manage_notification/notification.dart';
import '../wallet_chat/wallet_chat_screen.dart';

class _MenuItemData {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MenuItemData({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

void showChatProfileBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => const _ChatProfileSheet(),
  );
}

class _ChatProfileSheet extends StatefulWidget {
  const _ChatProfileSheet();

  @override
  State<_ChatProfileSheet> createState() => _ChatProfileSheetState();
}

class _ChatProfileSheetState extends State<_ChatProfileSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<_MenuItemData> _topItems = const [
    _MenuItemData(
      id: 'ADD_SYMBOL',
      title: 'Add Symbol',
      icon: Icons.add_circle_outline_rounded,
      iconColor: Color(0xFF0086FF),
      bgColor: Color(0xFFE8F3FF),
    ),
    _MenuItemData(
      id: 'VIEW_SYMBOL',
      title: 'View Symbol',
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFE88D1A),
      bgColor: Color(0xFFFFF3E0),
    ),
    _MenuItemData(
      id: 'CREATE_GROUP',
      title: 'Create Group',
      icon: Icons.group_add_rounded,
      iconColor: Color(0xFF2BB67F),
      bgColor: Color(0xFFE6F9F1),
    ),
    _MenuItemData(
      id: 'BACKGROUND',
      title: 'Background',
      icon: Icons.palette_rounded,
      iconColor: Color(0xFF9C27B0),
      bgColor: Color(0xFFF3E5F5),
    ),
  ];

  final List<_MenuItemData> _bottomItems = const [
    _MenuItemData(
      id: 'WALLET',
      title: 'Wallet',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFF0086FF),
      bgColor: Color(0xFFE8F3FF),
    ),
    _MenuItemData(
      id: 'PRIVATE_ROOM',
      title: 'Private Room',
      icon: Icons.shield_rounded,
      iconColor: Color(0xFFD94A42),
      bgColor: Color(0xFFFFEBEE),
    ),
    _MenuItemData(
      id: 'LINKED_DEVICE',
      title: 'Linked Device',
      icon: Icons.devices_rounded,
      iconColor: Color(0xFF505050),
      bgColor: Color(0xFFF0F0F0),
    ),
    _MenuItemData(
      id: 'LOCK_CHAT',
      title: 'Lock Chat',
      icon: Icons.lock_rounded,
      iconColor: Color(0xFFE88D1A),
      bgColor: Color(0xFFFFF3E0),
    ),
    _MenuItemData(
      id: 'NOTIFICATION',
      title: 'Notification',
      icon: Icons.notifications_rounded,
      iconColor: Color(0xFF2BB67F),
      bgColor: Color(0xFFE6F9F1),
    ),
    _MenuItemData(
      id: 'INVITE_FRIEND',
      title: 'Invite Friend',
      icon: Icons.person_add_alt_rounded,
      iconColor: Color(0xFF9C27B0),
      bgColor: Color(0xFFF3E5F5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleItemTap(String id) {
    Navigator.pop(context);
    switch (id) {
      case 'ADD_SYMBOL':
        Get.to(() => AddChatSymbolScreen());
        break;
      case 'VIEW_SYMBOL':
        final ctrl = Get.isRegistered<AddChatSymbolController>()
            ? Get.find<AddChatSymbolController>()
            : Get.put(AddChatSymbolController());
        Get.to(() => SymbolViewImages(mySymbols: ctrl.mySymbols));
        break;
      case 'CREATE_GROUP':
        Get.to(() => ContactsPage(from: "group"));
        break;
      case 'BACKGROUND':
        Get.to(() => ChatBackgroundScreen());
        break;
      case 'NOTIFICATION':
        Get.to(() => NotificationSettingScreen());
        break;
      case 'WALLET':
        Get.to(() => const WalletChatScreen());
        break;
      default:
        commonSnackBar(message: "Coming soon....");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileImage = authController.imgPath.value;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.58),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.greyE6,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Profile header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
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
                        imageUrl: profileImage,
                        size: 48,
                        borderRadius: 24,
                        showProfileOnFullScreen: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          userNameGlobal.isNotEmpty ? userNameGlobal : 'User',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.green0B,
                              ),
                            ),
                            const SizedBox(width: 5),
                            CustomText(
                              'Online',
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_rounded,
                      size: 22,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Top grid (4 items) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _topItems.asMap().entries.map((entry) {
                  return Expanded(
                    child: _buildGridItem(entry.value, entry.key),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 1,
                color: AppColors.whiteE5,
              ),
            ),

            // ── Bottom list items ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: _bottomItems.asMap().entries.map((entry) {
                    return _buildListItem(entry.value, entry.key);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(_MenuItemData item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _handleItemTap(item.id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: item.bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              CustomText(
                item.title,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(_MenuItemData item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: InkWell(
        onTap: () => _handleItemTap(item.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomText(
                  item.title,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.greyB3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
