import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lets the user theme the profile / home ("me" tab) pages with ONE active
/// background at a time: either a background colour (applied app-wide via the
/// theme) OR a home-page banner image — never both. Picking a colour clears the
/// banner and vice-versa. Held as draft state and committed (persisted) on Apply.
class AppBackgroundScreen extends StatefulWidget {
  const AppBackgroundScreen({super.key});

  @override
  State<AppBackgroundScreen> createState() => _AppBackgroundScreenState();
}

class _AppBackgroundScreenState extends State<AppBackgroundScreen> {
  final AppBackgroundController ctrl =
      getOrPut(() => AppBackgroundController(), permanent: true);

  // ── Draft state (color XOR banner — only one is ever active) ──
  late Color _bgColor;
  late String _bannerAsset;

  @override
  void initState() {
    super.initState();
    _bgColor = ctrl.bgColor.value;
    _bannerAsset = ctrl.bannerAsset.value;
  }

  void _apply() {
    // Exactly one background is committed: banner if chosen, else colour.
    ctrl.applyBackground(color: _bgColor, asset: _bannerAsset);
    commonSnackBar(message: 'Background applied');
    Get.back();
  }

  /// Pick a photo from the gallery, persist it to app storage, and select it
  /// as the (custom) banner. Drops any colour selection — banner wins.
  Future<void> _pickFromGallery() async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      'Choose background',
      isOnlyCamera: false,
      isGallery: true,
      cropAspectRatio: CropAspectRatio(width: 9, height: 16),
    );
    if (path == null || path.isEmpty) return;
    final stable = await AppBackgroundController.persistPickedBanner(path);
    if (!mounted) return;
    setState(() => _bannerAsset = stable);
  }

  /// Reset BOTH settings to the app defaults immediately (and persist).
  void _reset() {
    ctrl.resetAll();
    setState(() {
      _bgColor = ctrl.bgColor.value;
      _bannerAsset = '';
    });
    commonSnackBar(message: 'Background reset to default');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Column(
        children: [
          _topSection(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                      icon: Icons.palette_outlined, title: 'Background Color'),
                  const SizedBox(height: 12),
                  _colorGrid(),
                  const SizedBox(height: 28),
                  _sectionTitle(icon: Icons.wallpaper_rounded, title: 'Banner'),
                  const SizedBox(height: 6),
                  const CustomText(
                    'Choosing a banner replaces the background colour. Pick '
                    '"None" to use a colour instead.',
                    fontSize: 11.5,
                    color: AppColors.grayText,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _bannerRow(),
                ],
              ),
            ),
          ),
          _applyBar(),
        ],
      ),
    );
  }

  // ── Fixed top: back row + live preview ──
  Widget _topSection() {
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
                      'App Background',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _previewBackground(),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8),
                            ],
                          ),
                          child: const CustomText('Your content',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  /// Preview mirrors the home page: a preset banner shown plain, a gallery photo
  /// lightly blurred + frosted (glassmorphic), else the background colour.
  Widget _previewBackground() {
    if (_bannerAsset.isEmpty) return Container(color: _bgColor);
    if (AppBackgroundController.bannerIsAsset(_bannerAsset)) {
      return Image.asset(_bannerAsset, fit: BoxFit.cover);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_bannerAsset), fit: BoxFit.cover),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ],
    );
  }

  // ── Color grid ──
  Widget _colorGrid() {
    return _card(
      child: Wrap(
        spacing: 10,
        runSpacing: 14,
        children: AppBackgroundController.colorOptions.map((entry) {
          final color = entry[0] as Color;
          final name = entry[1] as String;
          // Highlighted only when colour is the active background (no banner).
          final isSelected = _bannerAsset.isEmpty &&
              // ignore: deprecated_member_use
              _bgColor.value == color.value;
          // Picking a colour makes it the single background → drop any banner.
          return GestureDetector(
            onTap: () => setState(() {
              _bgColor = color;
              _bannerAsset = '';
            }),
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
                                color: Colors.black.withValues(alpha: 0.04),
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
                CustomText(name, fontSize: 9, color: AppColors.grayText),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Banner row (None + image banners) ──
  Widget _bannerRow() {
    final banners = AppBackgroundController.bannerOptions;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // None + predefined banners + Gallery (pick from photos).
        itemCount: banners.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _bannerTile(
              isSelected: _bannerAsset.isEmpty,
              onTap: () => setState(() => _bannerAsset = ''),
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
          // Gallery tile (last): pick a photo; shows the picked image when one
          // is the active (custom) banner.
          if (index == banners.length + 1) {
            return _galleryTile();
          }
          final banner = banners[index - 1];
          final asset = banner['asset']!;
          final isSelected = _bannerAsset == asset;
          return _bannerTile(
            isSelected: isSelected,
            onTap: () => setState(() => _bannerAsset = asset),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(asset, fit: BoxFit.cover),
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
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    child: Center(
                      child: CustomText(banner['name']!,
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
                      child:
                          const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Gallery" tile — pick a photo as the background. When a user-picked image
  /// is the active banner, the tile shows that image (tap to re-pick).
  Widget _galleryTile() {
    final hasCustom = _bannerAsset.isNotEmpty &&
        !AppBackgroundController.bannerIsAsset(_bannerAsset);
    return _bannerTile(
      isSelected: hasCustom,
      onTap: _pickFromGallery,
      child: hasCustom
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(_bannerAsset), fit: BoxFit.cover),
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
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: AppColors.primaryColor, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryColor, size: 20),
                ),
                const SizedBox(height: 6),
                const CustomText('Gallery',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grayText),
              ],
            ),
    );
  }

  Widget _bannerTile({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
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
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
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

  Widget _applyBar() {
    return Container(
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
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
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
    );
  }

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
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
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
