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

class ChatThemeScreen extends StatefulWidget {
  const ChatThemeScreen({super.key});

  @override
  State<ChatThemeScreen> createState() => _ChatThemeScreenState();
}

class _ChatThemeScreenState extends State<ChatThemeScreen> {
  final ctrl = Get.find<ChatThemeController>();

  // ── Draft state (local copies, only applied on submit) ──
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
  late String _fontFamily;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _loadFromController();
  }

  void _loadFromController() {
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
    _fontFamily = ctrl.chatFontFamily.value;
    _fontSize = ctrl.chatFontSize.value;
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
      _scaffoldColor = Color(0xFFF1F1F3);
      _myMsgBgColor = AppColors.chat_bubble_my_bg;
      _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
    });
  }

  void _applyDarkDraft() {
    setState(() {
      _isDarkMode = true;
      _bgAsset = '';
      _bgFilePath = '';
      _bgColor = Color(0xFF0B141A);
      _textColor = Color(0xFFE9EDEF);
      _timeColor = Color(0xFF8696A0);
      _appBarColor = Color(0xFF1F2C34);
      _inputBgColor = Color(0xFF1F2C34);
      _scaffoldColor = Color(0xFF0B141A);
      _myMsgBgColor = Color(0xFF005C4B);
      _receiveMsgBgColor = Color(0xFF1F2C34);
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
      _scaffoldColor = Color(0xFFF1F1F3);
      _myMsgBgColor = AppColors.chat_bubble_my_bg;
      _receiveMsgBgColor = AppColors.chat_bubble_receive_bg;
    });
  }

  void _submitTheme() {
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
    ctrl.chatFontFamily.value = _fontFamily;
    ctrl.chatFontSize.value = _fontSize;
    ctrl.saveTheme();
    commonSnackBar(message: "Theme applied successfully");
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F8),
      body: CustomScrollView(
        slivers: [
          // ── Collapsing AppBar with live preview ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
              ),
            ),
            title: CustomText(
              'Chat Theme',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              collapseMode: CollapseMode.pin,
              background: _buildLivePreview(),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Theme Mode ──
                  _sectionHeader(icon: Icons.contrast_rounded, title: 'Appearance'),
                  SizedBox(height: 10),
                  _buildThemeModeCard(),
                  SizedBox(height: 28),

                  // ── Background Color ──
                  _sectionHeader(icon: Icons.palette_outlined, title: 'Background Color'),
                  SizedBox(height: 10),
                  _buildColorGrid(),
                  SizedBox(height: 28),

                  // ── Wallpaper ──
                  _sectionHeader(icon: Icons.wallpaper_rounded, title: 'Wallpaper'),
                  SizedBox(height: 10),
                  _buildWallpaperSection(),
                  SizedBox(height: 28),

                  // ── Font Style ──
                  _sectionHeader(icon: Icons.text_format_rounded, title: 'Font Style'),
                  SizedBox(height: 10),
                  _buildFontChips(),
                  SizedBox(height: 28),

                  // ── Font Size ──
                  _sectionHeader(icon: Icons.format_size_rounded, title: 'Font Size'),
                  SizedBox(height: 10),
                  _buildFontSizeCard(),
                  SizedBox(height: 32),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitTheme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          CustomText('Apply Theme', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // ── Reset ──
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _applyLightDraft();
                        setState(() {
                          _fontFamily = 'Default';
                          _fontSize = 16.0;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restart_alt_rounded, color: Colors.red.shade400, size: 18),
                            SizedBox(width: 8),
                            CustomText('Reset to Default', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade400),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────────────────
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        SizedBox(width: 10),
        CustomText(title, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // LIVE PREVIEW (inside SliverAppBar)
  // ─────────────────────────────────────────────────────────
  Widget _buildLivePreview() {
    return Stack(
      children: [
        // Background
        Positioned.fill(child: _previewBackground()),
        // Gradient fade at top for appbar readability
        Positioned(
          top: 0, left: 0, right: 0, height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        // Chat bubbles
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 56, 16, 8),
              child: Column(
                children: [
                  _previewBubble(
                    text: 'Hey! How are you doing?',
                    isMe: false,
                  ),
                  SizedBox(height: 10),
                  _previewBubble(
                    text: 'I\'m great, thanks! Working on some cool stuff',
                    isMe: true,
                  ),
                  SizedBox(height: 10),
                  _previewBubble(
                    text: 'This theme looks amazing!',
                    isMe: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        // "PREVIEW" badge
        Positioned(
          bottom: 8, right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded, size: 12, color: Colors.white70),
                SizedBox(width: 4),
                CustomText('PREVIEW', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
    // Default background image
    return Image.asset(AppImageAssets.chatDefaultBg, fit: BoxFit.cover);
  }

  Widget _previewBubble({required String text, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 260),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _myMsgBgColor : _receiveMsgBgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: _fontFamily == 'Default' ? null : _fontFamily,
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                color: isMe
                    ? (_isDarkMode ? Color(0xFFE9EDEF) : Colors.black87)
                    : _textColor,
              ),
            ),
            SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  isMe ? '10:30 AM' : '10:28 AM',
                  fontSize: 10,
                  color: _timeColor,
                ),
                if (isMe) ...[
                  SizedBox(width: 3),
                  Icon(Icons.done_all_rounded, size: 14, color: Colors.blue.shade300),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // THEME MODE CARD
  // ─────────────────────────────────────────────────────────
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
          SizedBox(width: 12),
          _modeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: _isDarkMode,
            selectedColor: Color(0xFF1F2C34),
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
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected
                ? [BoxShadow(color: selectedColor.withValues(alpha: 0.25), blurRadius: 10, offset: Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.grayText),
              SizedBox(width: 8),
              CustomText(label, fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.grayText),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COLOR GRID
  // ─────────────────────────────────────────────────────────
  Widget _buildColorGrid() {
    final colors = [
      [Colors.white, 'White'],
      [Color(0xFFF5F0E8), 'Cream'],
      [Color(0xFFE8F5E9), 'Mint'],
      [Color(0xFFE3F2FD), 'Sky'],
      [Color(0xFFFCE4EC), 'Rose'],
      [Color(0xFFFFF8E1), 'Honey'],
      [Color(0xFFF3E5F5), 'Lilac'],
      [Color(0xFFECEFF1), 'Ash'],
      [Color(0xFFE0F2F1), 'Teal'],
      [Color(0xFFFBE9E7), 'Peach'],
      [Color(0xFF0B141A), 'Night'],
      [Color(0xFF1B2838), 'Navy'],
    ];

    return _card(
      child: Wrap(
        spacing: 10,
        runSpacing: 14,
        children: colors.map((entry) {
          final color = entry[0] as Color;
          final name = entry[1] as String;
          final isSelected = _bgColor == color
              && _bgAsset.isEmpty
              && _bgFilePath.isEmpty;

          return GestureDetector(
            onTap: () {
              if (color == Color(0xFF0B141A)) {
                _applyDarkDraft();
              } else {
                _applyBgColorDraft(color);
              }
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 2))]
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          color: color.computeLuminance() > 0.5 ? AppColors.primaryColor : Colors.white,
                          size: 20)
                      : null,
                ),
                SizedBox(height: 4),
                CustomText(name, fontSize: 9, color: AppColors.grayText),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // WALLPAPER SECTION (assets + gallery)
  // ─────────────────────────────────────────────────────────
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
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          // ── None ──
          if (index == 0) {
            return _wallpaperTile(
              isSelected: noWallpaper,
              onTap: () {
                if (_isDarkMode) {
                  _applyDarkDraft();
                } else {
                  _applyLightDraft();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.block_rounded, color: AppColors.grayText, size: 20),
                  ),
                  SizedBox(height: 6),
                  CustomText('None', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.grayText),
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
                        errorBuilder: (_, __, ___) => _galleryPlaceholder(),
                      ),
                    )
                  else
                    _galleryPlaceholder(),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Center(
                        child: CustomText('Gallery', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
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
              setState(() {
                _bgAsset = wp['asset']!;
                _bgFilePath = '';
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
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    child: Center(
                      child: CustomText(wp['name']!, fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                      child: Icon(Icons.check, color: Colors.white, size: 12),
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
            Color(0xFF7C4DFF).withValues(alpha: 0.12),
            AppColors.primaryColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Color(0xFF7C4DFF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF7C4DFF), size: 20),
          ),
          SizedBox(height: 6),
          CustomText('Choose', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  Widget _wallpaperTile({required bool isSelected, required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: child,
      ),
    );
  }

  Future<void> _pickWallpaperFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final savedPath = '${dir.path}/chat_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(savedPath);

    // Remove old draft custom wallpaper file if different from controller's
    if (_bgFilePath.isNotEmpty && _bgFilePath != ctrl.chatBgFilePath.value) {
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

  // ─────────────────────────────────────────────────────────
  // FONT CHIPS
  // ─────────────────────────────────────────────────────────
  Widget _buildFontChips() {
    final fonts = ['Default', 'Roboto', 'Poppins', 'Lato', 'Montserrat', 'OpenSans'];

    return _card(
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: fonts.map((font) {
          final isSelected = _fontFamily == font;
          return GestureDetector(
            onTap: () => setState(() => _fontFamily = font),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: font == 'Default' ? null : font,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FONT SIZE SLIDER
  // ─────────────────────────────────────────────────────────
  Widget _buildFontSizeCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              CustomText('A', fontSize: 12, color: AppColors.grayText),
              Expanded(
                child: Center(
                  child: Text(
                    'The quick brown fox',
                    style: TextStyle(
                      fontFamily: _fontFamily == 'Default' ? null : _fontFamily,
                      fontSize: _fontSize,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              CustomText('A', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.grayText),
            ],
          ),
          SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppColors.primaryColor,
              inactiveTrackColor: AppColors.primaryColor.withValues(alpha: 0.12),
              thumbColor: AppColors.primaryColor,
              overlayColor: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: '${_fontSize.round()}',
              onChanged: (val) => setState(() => _fontSize = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText('12', fontSize: 10, color: AppColors.grayText),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomText(
                  '${_fontSize.round()} px',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              CustomText('24', fontSize: 10, color: AppColors.grayText),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED CARD WRAPPER
  // ─────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
