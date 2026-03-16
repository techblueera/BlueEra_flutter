import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/controller/chat_theme_controller.dart';

class ChatBackgroundScreen extends StatefulWidget {
  const ChatBackgroundScreen({super.key});

  @override
  State<ChatBackgroundScreen> createState() => _ChatBackgroundScreenState();
}

class _ChatBackgroundScreenState extends State<ChatBackgroundScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<ChatThemeController>();
  late TabController _tabController;

  // ── Draft state ──
  late bool _isDarkMode;
  late Color _bgColor;
  late String _bgAsset;
  late String _bgFilePath;
  late Color _textColor;
  late Color _timeColor;
  late Color _appBarColor;
  late Color _inputBgColor;
  late Color _scaffoldColor;
  late Color _myMsgBgColor;
  late Color _receiveMsgBgColor;
  late double _fontSize;
  late String _fontFamily;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isDarkMode = ctrl.isDarkMode.value;
    _bgColor = ctrl.chatBgColor.value;
    _bgAsset = ctrl.chatBgAsset.value;
    _bgFilePath = ctrl.chatBgFilePath.value;
    _textColor = ctrl.chatTextColor.value;
    _timeColor = ctrl.chatTimeColor.value;
    _appBarColor = ctrl.chatAppBarColor.value;
    _inputBgColor = ctrl.chatInputBgColor.value;
    _scaffoldColor = ctrl.chatScaffoldColor.value;
    _myMsgBgColor = ctrl.myMessageBgColor.value;
    _receiveMsgBgColor = ctrl.receiveMessageBgColor.value;
    _fontSize = ctrl.chatFontSize.value;
    _fontFamily = ctrl.chatFontFamily.value;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyLightDraft() {
    setState(() {
      _isDarkMode = false;
      _bgAsset = '';
      _bgFilePath = '';
      _bgColor = Colors.white;
      _textColor = Colors.black;
      _timeColor = AppColors.grayText;
      _appBarColor = Colors.white;
      _inputBgColor = Colors.white;
      _scaffoldColor = const Color(0xFFF1F1F3);
      _myMsgBgColor = AppColors.chat_bubble_my_bg;
      _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
    });
  }

  void _applyDarkDraft() {
    setState(() {
      _isDarkMode = true;
      _bgAsset = '';
      _bgFilePath = '';
      _bgColor = const Color(0xFF0B141A);
      _textColor = const Color(0xFFE9EDEF);
      _timeColor = const Color(0xFF8696A0);
      _appBarColor = const Color(0xFF1F2C34);
      _inputBgColor = const Color(0xFF1F2C34);
      _scaffoldColor = const Color(0xFF0B141A);
      _myMsgBgColor = const Color(0xFF005C4B);
      _receiveMsgBgColor = const Color(0xFF1F2C34);
    });
  }

  void _applyBgColorDraft(Color color) {
    setState(() {
      _isDarkMode = false;
      _bgAsset = '';
      _bgFilePath = '';
      _bgColor = color;
      _textColor = Colors.black;
      _timeColor = AppColors.grayText;
      _appBarColor = Colors.white;
      _inputBgColor = Colors.white;
      _scaffoldColor = const Color(0xFFF1F1F3);
      _myMsgBgColor = AppColors.chat_bubble_my_bg;
      _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
    });
  }

  void _submitAll() {
    ctrl.isDarkMode.value = _isDarkMode;
    ctrl.chatBgColor.value = _bgColor;
    ctrl.chatBgAsset.value = _bgAsset;
    ctrl.chatBgFilePath.value = _bgFilePath;
    ctrl.chatTextColor.value = _textColor;
    ctrl.chatTimeColor.value = _timeColor;
    ctrl.chatAppBarColor.value = _appBarColor;
    ctrl.chatInputBgColor.value = _inputBgColor;
    ctrl.chatScaffoldColor.value = _scaffoldColor;
    ctrl.myMessageBgColor.value = _myMsgBgColor;
    ctrl.receiveMessageBgColor.value = _receiveMsgBgColor;
    ctrl.chatFontSize.value = _fontSize;
    ctrl.chatFontFamily.value = _fontFamily;
    ctrl.saveTheme();
    commonSnackBar(message: "Settings applied successfully");
    Get.back();
  }

  void _resetToDefault() {
    setState(() {
      _isDarkMode = false;
      _bgAsset = '';
      _bgFilePath = '';
      _bgColor = Colors.white;
      _textColor = Colors.black;
      _timeColor = AppColors.grayText;
      _appBarColor = Colors.white;
      _inputBgColor = Colors.white;
      _scaffoldColor = const Color(0xFFF1F1F3);
      _myMsgBgColor = AppColors.chat_bubble_my_bg;
      _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
      _fontSize = 16.0;
      _fontFamily = 'Default';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Column(
        children: [
          // ── Fixed Top: AppBar + Live Preview + Tabs ──
          _buildFixedTopSection(),

          // ── Tab Content (scrollable) ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBackgroundTab(),
                _buildChatBannerTab(),
                _buildFontStyleTab(),
              ],
            ),
          ),

          // ── Apply Button (always visible) ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor:
                        AppColors.primaryColor.withValues(alpha: 0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      CustomText('Apply',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FIXED TOP: AppBar + Live Preview + TabBar
  // ─────────────────────────────────────────────────────────
  Widget _buildFixedTopSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── AppBar Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: CustomText(
                      'Background',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resetToDefault,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restart_alt_rounded,
                              color: Colors.red.shade400, size: 16),
                          const SizedBox(width: 4),
                          CustomText('Reset',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Live Chat Preview ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Background
                      Positioned.fill(child: _previewBackground()),

                      // Chat bubbles
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _previewBubble(
                                text: 'Hey! How are you? 👋',
                                isMe: false),
                            const SizedBox(height: 8),
                            _previewBubble(
                                text: 'Great, working on cool stuff! ✨',
                                isMe: true),
                          ],
                        ),
                      ),

                      // Preview badge
                      Positioned(
                        bottom: 6,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 10, color: Colors.white70),
                              SizedBox(width: 3),
                              CustomText('LIVE PREVIEW',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── TabBar ──
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Background'),
                Tab(text: 'Chat Banner'),
                Tab(text: 'Font Style'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PREVIEW HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _previewBackground() {
    if (_bgFilePath.isNotEmpty) {
      return Image.file(
        File(_bgFilePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: _bgColor),
      );
    }
    if (_bgAsset.isNotEmpty) {
      return Image.asset(_bgAsset, fit: BoxFit.cover);
    }
    // Solid color background
    return Container(color: _bgColor);
  }

  Widget _previewBubble({required String text, required bool isMe}) {
    final effectiveFamily = _fontFamily == 'Default' ? null : _fontFamily;

    // Text color: dark mode -> white for both sender & receiver
    // Light mode: sender -> black87, receiver -> _textColor
    final Color bubbleTextColor;
    if (_isDarkMode) {
      bubbleTextColor = const Color(0xFFE9EDEF);
    } else {
      bubbleTextColor = isMe ? Colors.black87 : _textColor;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? _myMsgBgColor : _receiveMsgBgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: effectiveFamily,
            fontSize: _fontSize,
            fontWeight: FontWeight.w500,
            color: bubbleTextColor,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1 — BACKGROUND (color grid + appearance toggle)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBackgroundTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Appearance Toggle ──
          _sectionTitle(icon: Icons.contrast_rounded, title: 'Appearance'),
          const SizedBox(height: 12),
          _buildThemeModeCard(),
          const SizedBox(height: 28),

          // ── Color Grid ──
          _sectionTitle(
              icon: Icons.palette_outlined, title: 'Background Color'),
          const SizedBox(height: 12),
          _buildColorGrid(),
        ],
      ),
    );
  }

  Widget _buildThemeModeCard() {
    return _card(
      child: Row(
        children: [
          _modeOption(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            isSelected: !_isDarkMode,
            selectedColor: AppColors.primaryColor,
            onTap: () => _applyLightDraft(),
          ),
          const SizedBox(width: 12),
          _modeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: _isDarkMode,
            selectedColor: const Color(0xFF1F2C34),
            onTap: () => _applyDarkDraft(),
          ),
        ],
      ),
    );
  }

  Widget _modeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border:
                isSelected ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: selectedColor.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.grayText),
              const SizedBox(width: 8),
              CustomText(label,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.grayText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = [
      [Colors.white, 'White'],
      [const Color(0xFFF5F0E8), 'Cream'],
      [const Color(0xFFE8F5E9), 'Mint'],
      [const Color(0xFFE3F2FD), 'Sky'],
      [const Color(0xFFFCE4EC), 'Rose'],
      [const Color(0xFFFFF8E1), 'Honey'],
      [const Color(0xFFF3E5F5), 'Lilac'],
      [const Color(0xFFECEFF1), 'Ash'],
      [const Color(0xFFE0F2F1), 'Teal'],
      [const Color(0xFFFBE9E7), 'Peach'],
      [const Color(0xFF0B141A), 'Night'],
      [const Color(0xFF1B2838), 'Navy'],
    ];

    return _card(
      child: Wrap(
        spacing: 10,
        runSpacing: 14,
        children: colors.map((entry) {
          final color = entry[0] as Color;
          final name = entry[1] as String;
          // ignore: deprecated_member_use
          final isSelected = _bgColor.value == color.value &&
              _bgAsset.isEmpty &&
              _bgFilePath.isEmpty;

          return GestureDetector(
            onTap: () {
              // ignore: deprecated_member_use
              if (color.value == const Color(0xFF0B141A).value ||
                  // ignore: deprecated_member_use
                  color.value == const Color(0xFF1B2838).value) {
                _applyDarkDraft();
                setState(() => _bgColor = color);
              } else {
                _applyBgColorDraft(color);
              }
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4)
                          ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          color: color.computeLuminance() > 0.5
                              ? AppColors.primaryColor
                              : Colors.white,
                          size: 20)
                      : null,
                ),
                const SizedBox(height: 4),
                CustomText(name,
                    fontSize: 9, color: AppColors.grayText),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2 — CHAT BANNER (wallpaper)
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatBannerTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              icon: Icons.wallpaper_rounded, title: 'Chat Wallpaper'),
          const SizedBox(height: 12),
          _buildWallpaperSection(),
        ],
      ),
    );
  }

  Widget _buildWallpaperSection() {
    final wallpapers = [
      {'asset': AppImageAssets.chatDefaultBg, 'name': 'Default'},
      {'asset': AppImageAssets.chatBgLight, 'name': 'Light'},
      {'asset': AppImageAssets.chatBgDark, 'name': 'Dark'},
      {'asset': AppImageAssets.chatBgBlueShade, 'name': 'Blue'},
    ];

    final bool hasCustomWp = _bgFilePath.isNotEmpty;
    final bool noWallpaper = _bgAsset.isEmpty && !hasCustomWp;

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallpapers.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // ── None ──
          if (index == 0) {
            return _wallpaperTile(
              isSelected: noWallpaper,
              onTap: () {
                setState(() {
                  _bgAsset = '';
                  _bgFilePath = '';
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block_rounded,
                        color: AppColors.grayText, size: 20),
                  ),
                  const SizedBox(height: 6),
                  const CustomText('None',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grayText),
                ],
              ),
            );
          }

          // ── Gallery Pick ──
          if (index == 1) {
            return _wallpaperTile(
              isSelected: hasCustomWp,
              onTap: () => _pickWallpaperFromGallery(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCustomWp)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_bgFilePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _galleryPlaceholder(),
                      ),
                    )
                  else
                    _galleryPlaceholder(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(14)),
                      ),
                      child: const Center(
                        child: CustomText('Gallery',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Asset wallpapers ──
          final wp = wallpapers[index - 2];
          final isSelected = _bgAsset == wp['asset'] && !hasCustomWp;
          return _wallpaperTile(
            isSelected: isSelected,
            onTap: () {
              final isDarkWallpaper =
                  wp['asset'] == AppImageAssets.chatBgDark;
              setState(() {
                _bgAsset = wp['asset']!;
                _bgFilePath = '';
                if (isDarkWallpaper) {
                  // Dark wallpaper → use dark theme colors
                  _isDarkMode = true;
                  _textColor = const Color(0xFFE9EDEF);
                  _timeColor = const Color(0xFF8696A0);
                  _appBarColor = const Color(0xFF1F2C34);
                  _inputBgColor = const Color(0xFF1F2C34);
                  _scaffoldColor = const Color(0xFF0B141A);
                  _myMsgBgColor = const Color(0xFF005C4B);
                  _receiveMsgBgColor = const Color(0xFF1F2C34);
                } else {
                  // Light wallpapers → use light theme colors
                  _isDarkMode = false;
                  _textColor = Colors.black;
                  _timeColor = AppColors.grayText;
                  _appBarColor = Colors.white;
                  _inputBgColor = Colors.white;
                  _scaffoldColor = const Color(0xFFF1F1F3);
                  _myMsgBgColor = AppColors.chat_bubble_my_bg;
                  _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
                }
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(wp['asset']!, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    child: Center(
                      child: CustomText(wp['name']!,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _galleryPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C4DFF).withValues(alpha: 0.12),
            AppColors.primaryColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined,
                color: Color(0xFF7C4DFF), size: 20),
          ),
          const SizedBox(height: 6),
          const CustomText('Choose',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  Widget _wallpaperTile(
      {required bool isSelected,
      required VoidCallback onTap,
      required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4)
                ],
        ),
        child: child,
      ),
    );
  }

  Future<void> _pickWallpaperFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final savedPath =
        '${dir.path}/chat_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(savedPath);

    if (_bgFilePath.isNotEmpty &&
        _bgFilePath != ctrl.chatBgFilePath.value) {
      try {
        final old = File(_bgFilePath);
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }

    setState(() {
      _bgFilePath = savedPath;
      _bgAsset = '';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3 — FONT STYLE (font family + font size)
  // ═══════════════════════════════════════════════════════════
  static const _fonts = [
    {'name': 'Default', 'display': 'System Default'},
    {'name': 'Roboto', 'display': 'Roboto'},
    {'name': 'Poppins', 'display': 'Poppins'},
    {'name': 'Lato', 'display': 'Lato'},
    {'name': 'Montserrat', 'display': 'Montserrat'},
    {'name': 'OpenSans', 'display': 'Open Sans'},
    {'name': 'Raleway', 'display': 'Raleway'},
    {'name': 'NotoSans', 'display': 'Noto Sans'},
    {'name': 'Ubuntu', 'display': 'Ubuntu'},
    {'name': 'Nunito', 'display': 'Nunito'},
    {'name': 'Quicksand', 'display': 'Quicksand'},
    {'name': 'Comfortaa', 'display': 'Comfortaa'},
    {'name': 'DancingScript', 'display': 'Dancing Script'},
    {'name': 'Pacifico', 'display': 'Pacifico'},
    {'name': 'CaveatBrush', 'display': 'Caveat Brush'},
  ];

  Widget _buildFontStyleTab() {

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Font Family ──
          _sectionTitle(
              icon: Icons.font_download_rounded, title: 'Font Family'),
          const SizedBox(height: 6),
          CustomText(
            'Tap a card to preview how it looks',
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 14),
          _buildFontGrid(),
          const SizedBox(height: 28),

          // ── Font Size ──
          _sectionTitle(
              icon: Icons.format_size_rounded, title: 'Font Size'),
          const SizedBox(height: 14),
          _card(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText('A',
                        fontSize: 12, color: Color(0xFF9E9E9E)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        '${_fontSize.round()} px',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const CustomText('A',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9E9E9E)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20),
                    activeTrackColor: AppColors.primaryColor,
                    inactiveTrackColor: AppColors.primaryColor
                        .withValues(alpha: 0.12),
                    thumbColor: AppColors.primaryColor,
                    overlayColor: AppColors.primaryColor
                        .withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 6,
                    label: '${_fontSize.round()}',
                    onChanged: (val) =>
                        setState(() => _fontSize = val),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText('Small',
                        fontSize: 10, color: Color(0xFF9E9E9E)),
                    CustomText('Large',
                        fontSize: 10, color: Color(0xFF9E9E9E)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Font Grid (3 columns) ──
  Widget _buildFontGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _fonts.length,
      itemBuilder: (context, index) {
        final font = _fonts[index];
        final isSelected = _fontFamily == font['name'];
        final family = font['name'] == 'Default' ? null : font['name'];

        return GestureDetector(
          onTap: () => setState(() => _fontFamily = font['name']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color:
                        AppColors.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontFamily: family,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        font['display']!,
                        style: TextStyle(
                          fontFamily: family,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hello!',
                        style: TextStyle(
                          fontFamily: family,
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════
  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 10),
        CustomText(title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
