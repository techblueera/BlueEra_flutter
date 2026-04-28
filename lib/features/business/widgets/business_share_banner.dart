import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Share-worthy promo banner used at the bottom of every business home
/// screen (food, grocery, hospital, medical, hotel, laboratory, school,
/// product, manufacture, others). Reads the signed-in business from
/// [ViewBusinessDetailsController] so each host screen just drops
/// `const BusinessShareBanner()` at the end of its scroll — no
/// per-screen wiring.
///
/// Provides three share actions:
///   • **Share** – captures the banner PNG and opens the OS share sheet
///     (attached profile deep link, same pattern as visiting-card share).
///   • **PDF** – bottom sheet → save-to-device (A4 landscape in the
///     app's documents dir) or share-PDF.
///   • **Annotate** – opens a full-screen finger-drawing editor where
///     users can sketch on top of the captured banner and share.
class BusinessShareBanner extends StatefulWidget {
  const BusinessShareBanner({super.key});

  @override
  State<BusinessShareBanner> createState() => _BusinessShareBannerState();
}

class _BusinessShareBannerState extends State<BusinessShareBanner> {
  final GlobalKey _bannerKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final details = _safeBusinessDetails();
      if (details == null) return const SizedBox.shrink();
      final shopName =
          (details.businessName?.trim().isNotEmpty ?? false)
              ? details.businessName!
              : 'My Shop';
      final shopPhoto =
          (details.logo?.trim().isNotEmpty ?? false) ? details.logo : null;
      final subCategory = details.subCategoryDetails?.name ??
          details.subCategoryOfBusiness;

      return CustomFormCard(
        padding: const EdgeInsets.all(10.0),
        margin: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            RepaintBoundary(
              key: _bannerKey,
              child: _BannerArt(
                shopName: shopName,
                shopPhoto: shopPhoto,
                subCategory: subCategory,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            _buildActions(shopName),
          ],
        ),
      );
    });
  }

  BusinessProfileDetails? _safeBusinessDetails() {
    try {
      final ctrl = Get.find<ViewBusinessDetailsController>();
      return ctrl.businessProfileDetails.value?.data;
    } catch (_) {
      return null;
    }
  }

  // ───── Action row + buttons ───────────────────────────────────────

  Widget _buildActions(String shopName) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: _isExporting ? null : () => _shareAsImage(shopName),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: _actionTile(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            onTap: _isExporting ? null : () => _offerPdf(shopName),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: _actionTile(
            icon: Icons.edit_rounded,
            label: 'Annotate',
            onTap: _isExporting ? null : () => _openDrawEditor(shopName),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primaryColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(
                alpha: enabled ? 0.22 : 0.10,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              CustomText(
                label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───── Capture + share plumbing ───────────────────────────────────

  /// Builds the deep-link caption attached to every shared artefact.
  /// Matches the visiting-card share helper.
  String _buildShareMessage(String shopName) {
    final link = profileDeepLink(
      userId: userId,
      accountType: accountTypeGlobal == AppConstants.business
          ? AppConstants.business
          : AppConstants.individual,
    );
    return 'Visit $shopName on BlueEra:\n$link\n';
  }

  Future<Uint8List?> _captureBannerPng({double pixelRatio = 3.0}) async {
    try {
      final boundary = _bannerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Banner capture failed: $e');
      return null;
    }
  }

  Future<void> _shareAsImage(String shopName) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureBannerPng();
      if (bytes == null) {
        commonSnackBar(message: 'Could not capture banner');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/shop_banner_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      final caption = _buildShareMessage(shopName);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'shop_banner.png')],
        text: caption,
        subject: caption,
      );
    } catch (e) {
      commonSnackBar(message: 'Share failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _offerPdf(String shopName) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  CustomText(
                    'Export banner as PDF',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.save_alt, color: AppColors.primaryColor),
              title: const Text('Save to device'),
              subtitle: const Text('Store the PDF in your app files'),
              onTap: () => Navigator.of(ctx).pop('save'),
            ),
            ListTile(
              leading: Icon(Icons.ios_share, color: AppColors.primaryColor),
              title: const Text('Share PDF'),
              subtitle: const Text('Send via WhatsApp, Email, etc.'),
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    await _exportPdf(save: choice == 'save', shopName: shopName);
  }

  Future<void> _exportPdf({
    required bool save,
    required String shopName,
  }) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureBannerPng();
      if (bytes == null) {
        commonSnackBar(message: 'Could not capture banner');
        return;
      }
      final pdf = pw.Document();
      final img = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Center(
            child: pw.Image(img, fit: pw.BoxFit.cover),
          ),
        ),
      );
      final pdfBytes = await pdf.save();
      final filename =
          'shop_banner_${DateTime.now().millisecondsSinceEpoch}.pdf';
      if (save) {
        final docDir = await getApplicationDocumentsDirectory();
        final file = File('${docDir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        commonSnackBar(message: 'Saved to ${file.path}');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        final caption = _buildShareMessage(shopName);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: filename)],
          text: caption,
          subject: caption,
        );
      }
    } catch (e) {
      commonSnackBar(message: 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openDrawEditor(String shopName) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureBannerPng();
      if (bytes == null) {
        commonSnackBar(message: 'Could not capture banner');
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _BannerAnnotateScreen(
            bannerPng: bytes,
            shareCaption: _buildShareMessage(shopName),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Banner artwork — background image + dark wash + identity column.
// ═══════════════════════════════════════════════════════════════════

class _BannerArt extends StatelessWidget {
  final String shopName;
  final String? shopPhoto;
  final String? subCategory;

  const _BannerArt({
    required this.shopName,
    required this.shopPhoto,
    required this.subCategory,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Market-scene artwork.
            Image.asset(
              AppImageAssets.shopBanner,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            // 2. Dark gradient wash for text legibility.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x99000000)],
                ),
              ),
            ),
            // 3. Corner accents.
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                  width: 40, height: 3, color: AppColors.primaryColor),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                  width: 40, height: 3, color: Colors.amber.shade400),
            ),
            // 4. Shop identity column — nudged into the left artwork
            //    area, aligned under the banner's "AB HUM BHI ONLINE"
            //    headline centre-line.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnWidth = constraints.maxWidth * 0.48;
                  final leftOffset = constraints.maxWidth * 0.10;
                  final logoSize =
                      (columnWidth * 0.24).clamp(42.0, 52.0);
                  return Align(
                    alignment: const Alignment(-1.0, -0.4),
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: leftOffset, top: SizeConfig.size12),
                      child: SizedBox(
                        width: columnWidth,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _logoDisc(logoSize),
                              SizedBox(height: SizeConfig.size10),
                              _nameDisplay(),
                              if ((subCategory ?? '').trim().isNotEmpty) ...[
                                SizedBox(height: SizeConfig.size6),
                                _subcategoryPill(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoDisc(double size) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE5F1FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: shopPhoto != null
            ? CachedNetworkImage(
                imageUrl: shopPhoto!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.greyE5),
                errorWidget: (_, __, ___) => Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primaryColor,
                  size: size * 0.45,
                ),
              )
            : Icon(
                Icons.storefront_rounded,
                color: AppColors.primaryColor,
                size: size * 0.45,
              ),
      ),
    );
  }

  Widget _nameDisplay() {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow layer.
            Text(
              shopName,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AsapCondensed',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.08,
                color: Colors.transparent,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.85),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            // Gradient fill.
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE082),
                  Color(0xFFFFC857),
                  Color(0xFFFFA726),
                ],
                stops: [0.0, 0.55, 1.0],
              ).createShader(bounds),
              child: Text(
                shopName,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'AsapCondensed',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  height: 1.08,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subcategoryPill() {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: CustomText(
            subCategory!.toUpperCase(),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Annotate Screen — draw on the banner PNG, then share.
// ═══════════════════════════════════════════════════════════════════

class _BannerAnnotateScreen extends StatefulWidget {
  final Uint8List bannerPng;
  final String shareCaption;
  const _BannerAnnotateScreen({
    required this.bannerPng,
    required this.shareCaption,
  });

  @override
  State<_BannerAnnotateScreen> createState() => _BannerAnnotateScreenState();
}

class _BannerAnnotateScreenState extends State<_BannerAnnotateScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<_AnnotationStroke> _strokes = [];
  _AnnotationStroke? _active;

  Color _penColor = const Color(0xFFE11D48);
  double _penWidth = 4;
  bool _isSharing = false;

  static const List<Color> _palette = [
    Color(0xFFE11D48),
    Color(0xFFFFC857),
    Color(0xFF1D4ED8),
    Color(0xFF059669),
    Color(0xFF111827),
    Color(0xFFFFFFFF),
  ];

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _active = _AnnotationStroke(color: _penColor, width: _penWidth)
        ..points.add(d.localPosition);
      _strokes.add(_active!);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_active == null) return;
    setState(() => _active!.points.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) => _active = null;

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.clear());
  }

  Future<Uint8List?> _captureCanvas() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareAnnotated() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureCanvas();
      if (bytes == null) {
        commonSnackBar(message: 'Could not capture canvas');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/shop_banner_annotated_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'shop_banner.png')],
        text: widget.shareCaption,
        subject: widget.shareCaption,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      commonSnackBar(message: 'Share failed: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Annotate & Share'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _clear,
            icon: const Icon(Icons.layers_clear_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: AspectRatio(
                        aspectRatio: 3 / 2,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(widget.bannerPng, fit: BoxFit.cover),
                            GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: CustomPaint(
                                painter: _AnnotationPainter(_strokes),
                                size: Size.infinite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              color: const Color(0xFF111827),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final c in _palette)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _penColor = c),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _penColor == c
                                      ? Colors.white
                                      : Colors.white
                                          .withValues(alpha: 0.2),
                                  width: _penColor == c ? 2.5 : 1,
                                ),
                                boxShadow: _penColor == c
                                    ? [
                                        BoxShadow(
                                          color: c.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      PopupMenuButton<double>(
                        tooltip: 'Pen size',
                        color: const Color(0xFF1F2937),
                        icon: Icon(Icons.brush_rounded,
                            color: Colors.white.withValues(alpha: 0.9)),
                        onSelected: (v) => setState(() => _penWidth = v),
                        itemBuilder: (_) => [
                          for (final w in [2.0, 4.0, 6.0, 10.0, 16.0])
                            PopupMenuItem<double>(
                              value: w,
                              child: Row(
                                children: [
                                  Container(
                                    width: w * 2,
                                    height: w,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(w),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${w.toInt()} px',
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSharing ? null : _shareAnnotated,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded),
                      label: const Text(
                        'Share annotated image',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationStroke {
  final Color color;
  final double width;
  final List<Offset> points = [];
  _AnnotationStroke({required this.color, required this.width});
}

class _AnnotationPainter extends CustomPainter {
  final List<_AnnotationStroke> strokes;
  _AnnotationPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) {
        if (s.points.isNotEmpty) {
          canvas.drawCircle(
            s.points.first,
            s.width / 2,
            Paint()..color = s.color,
          );
        }
        continue;
      }
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter old) =>
      old.strokes != strokes;
}
