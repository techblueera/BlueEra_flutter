import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/chat_theme_controller.dart';

class ChatFontStyleScreen extends StatefulWidget {
  const ChatFontStyleScreen({super.key});

  @override
  State<ChatFontStyleScreen> createState() => _ChatFontStyleScreenState();
}

class _ChatFontStyleScreenState extends State<ChatFontStyleScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<ChatThemeController>();

  late String _fontFamily;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  final _fonts = [
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

  @override
  void initState() {
    super.initState();
    _fontFamily = ctrl.chatFontFamily.value;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _applyFontSettings() {
    ctrl.chatFontFamily.value = _fontFamily;
    ctrl.saveTheme();
    Get.back();
  }

  String? get _effectiveFamily =>
      _fontFamily == 'Default' ? null : _fontFamily;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Fixed Chat Preview + AppBar ──
            _buildTopSection(),

            // ── Scrollable Font Cards ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      icon: Icons.font_download_rounded,
                      title: 'Choose Font Family',
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      'Tap a card to preview how it looks',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 16),
                    _buildFontGrid(),
                    const SizedBox(height: 28),

                    // ── Apply Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _applyFontSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor:
                              AppColors.primaryColor.withValues(alpha: 0.35),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            CustomText('Apply Font Style',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Reset ──
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _fontFamily = 'Default';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restart_alt_rounded,
                                  color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 8),
                              CustomText('Reset to Default',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade400),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP SECTION: AppBar + Live Chat Preview
  // ─────────────────────────────────────────────────────────
  Widget _buildTopSection() {
    final isDark = ctrl.isDarkMode.value;
    final myBg = ctrl.myMessageBgColor.value;
    final receiveBg = ctrl.receiveMessageBgColor.value;
    final textColor = ctrl.chatTextColor.value;
    final fontSize = ctrl.chatFontSize.value;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0EDFF),
            Color(0xFFE8F4FD),
            Color(0xFFF8F7FC),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87, size: 17),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: CustomText(
                        'Font Style',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),

            // ── Live Chat Preview ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0B141A)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Received message
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 230),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? receiveBg
                              : const Color(0xFFFFFFFF),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'What font do you like? 😊',
                          style: TextStyle(
                            fontFamily: _effectiveFamily,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: isDark ? textColor : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Sent message
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 230),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: myBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'This one looks perfect! ✨',
                          style: TextStyle(
                            fontFamily: _effectiveFamily,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE9EDEF)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Preview badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded,
                              size: 11, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          CustomText('LIVE PREVIEW',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  // FONT GRID — 3 columns, scrollable cards
  // ─────────────────────────────────────────────────────────
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
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
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
                // Card content
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Font preview letters
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
                      // Font name
                      Text(
                        font['display']!,
                        style: TextStyle(
                          fontFamily: family,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Sample text
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
                // Selected checkmark
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
}
