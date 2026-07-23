import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/add_lab_package_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/create_your_own_packages_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "My Packages" — the caller's own package catalog.
///
/// Wires to `GET /packages/me` via [LabPackageController.fetchMyPackages]
/// per FLUTTER_CATALOGUE_INTEGRATION.md PART 6. The list refreshes
/// automatically on open, on pull-to-refresh, and after create/edit/delete
/// (the controller re-runs the fetch itself, invalidating `myPackages`).
class MyLabPackagesScreen extends StatefulWidget {
  /// Optional appbar title. Defaults to "My Packages"; callers scoping the
  /// list to a preset (e.g. "Basic Health Checkup") can pass that name.
  final String? title;

  /// Restrict the list to a single preset. Backed by
  /// `/packages/me?packageType=<preset>` per PART 6 of the integration
  /// doc; the screen also falls back to matching legacy rows on `name`
  /// (pre-`packageType` records store the preset there instead).
  final String? packageType;

  const MyLabPackagesScreen({super.key, this.title, this.packageType});

  @override
  State<MyLabPackagesScreen> createState() => _MyLabPackagesScreenState();
}

class _MyLabPackagesScreenState extends State<MyLabPackagesScreen> {
  static const Color _accent = AppColors.primaryColor;

  late final LabPackageController _pkgCtrl =
      getOrPut(() => LabPackageController());

  @override
  void initState() {
    super.initState();
    _pkgCtrl.fetchMyPackages();
  }

  Future<void> _openAdd() async {
    // Route through the presets landing so the user sees preset options,
    // then the manual "Others (Add Manually)" tile inside it.
    await Get.to(() => const CreateYourOwnPackagesScreen());
    // Controller refreshes on successful create, but the presets flow may
    // exit without saving — no-op if nothing changed.
  }

  Future<void> _openEdit(LabPackage p) async {
    // Edit uses the same Add form, prefilled — PUT /packages/{id} per
    // FLUTTER_CATALOGUE_INTEGRATION.md PART 9B. Controller re-fetches
    // `myPackages` on success.
    await Get.to(() => AddLabPackageScreen(editingPackage: p));
  }

  Future<void> _confirmDelete(LabPackage p) async {
    final id = (p.id ?? '').trim();
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete package'),
        content: Text('Remove "${p.name ?? ''}" from your catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _pkgCtrl.deletePackage(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title ?? 'My Packages',
        showRightTextButton: true,
        rightTextButtonText: '+ Add More',
        rightTextButtonColor: _accent,
        onRightTextButtonTap: _openAdd,
      ),
      body: RefreshIndicator(
        onRefresh: () => _pkgCtrl.fetchMyPackages(),
        child: Obx(() {
          if (_pkgCtrl.isLoading.value && _pkgCtrl.myPackages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            );
          }
          // Preset scope: keep packages whose `packageType` matches, and
          // include legacy rows (packageType null) whose display `name`
          // still carries the preset — see the widget's field doc.
          final filter = (widget.packageType ?? '').trim();
          final list = filter.isEmpty
              ? _pkgCtrl.myPackages.toList()
              : _pkgCtrl.myPackages.where((p) {
                  final pt = (p.packageType ?? '').trim();
                  if (pt.isNotEmpty) return pt == filter;
                  return (p.name ?? '').trim() == filter;
                }).toList();
          if (list.isEmpty) {
            return _emptyState();
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
            itemBuilder: (_, i) => _PackageTile(
              pkg: list[i],
              onEdit: () => _openEdit(list[i]),
              onDelete: () => _confirmDelete(list[i]),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState() {
    // Wrapped in a scrollable so RefreshIndicator still works on empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: SizeConfig.size48),
        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          'No packages yet',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.size6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size24),
          child: CustomText(
            'Tap "+ Add More" to bundle your tests into a package.',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Package tile — mirrors the school course card
/// ([SchoolCourseListItemCard]) visual language: 165×165 image, radius-20
/// shell with a soft shadow, header row (name + overflow menu), price row
/// (₹price + strikethrough MRP + discount pill), 2-line description with
/// Read More, optional mini chip for packageType, and a small green pill
/// for the tests-available count. Data + actions are unchanged.
class _PackageTile extends StatelessWidget {
  final LabPackage pkg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageTile({
    required this.pkg,
    required this.onEdit,
    required this.onDelete,
  });

  int get _testCount {
    if ((pkg.tests?.isNotEmpty ?? false)) return pkg.tests!.length;
    return pkg.testIds.length;
  }

  int? get _discountPercent {
    final mrp = pkg.packageMrp;
    final price = pkg.customerPrice;
    if (mrp == null || price == null || mrp <= 0 || price >= mrp) return null;
    return (((mrp - price) / mrp) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final img = (pkg.imageUrl ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 165,
              height: 165,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _bannerFallback(),
                      placeholder: (_, __) => _bannerFallback(),
                    )
                  : _bannerFallback(),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + overflow menu — allow 2 lines so wrapping names
                // ("Basic Health Check - Up") read cleanly, matching the
                // mock.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        pkg.name ?? 'N/A',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.black22,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _CardMenu(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                const SizedBox(height: 6),
                _priceRow(),
                const SizedBox(height: 10),
                // Description occupies the mid-section of the right column —
                // three lines with an inline "Read More" per the mock.
                _CardDescription(text: pkg.description ?? ''),
                const SizedBox(height: 30),
                Divider(height: 0.5, thickness: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                // Fit-content pill (not full-width) so it hugs the "N Tests
                // Available" copy the way the mock does.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xff2E7D32),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.laboratoryIcon,
                          imgColor: AppColors.white,
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: SizeConfig.size6),
                        CustomText(
                          '$_testCount ${_testCount == 1 ? 'Test' : 'Tests'} Available',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
      );

  /// Price row kept from the previous tile so pricing stays legible:
  /// ₹price + strikethrough MRP + discount chip. Slotted in where the
  /// school card renders its fee label.
  Widget _priceRow() {
    final price = pkg.customerPrice;
    final mrp = pkg.packageMrp;
    final discount = _discountPercent;
    if (price == null && mrp == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (price != null)
          CustomText(
            '₹$price',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
          )
        else if (mrp != null)
          CustomText(
            '₹$mrp',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
          ),
        if (mrp != null && price != null && mrp > price) ...[
          SizedBox(width: SizeConfig.size6),
          CustomText(
            '₹$mrp',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey7E,
            decoration: TextDecoration.lineThrough,
          ),
        ],
        if (discount != null) ...[
          SizedBox(width: SizeConfig.size10),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.green7F.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.discountIcon,
                  width: 10,
                  height: 10,
                ),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  '$discount% Off',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff008000),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Two-line description with an inline "Read More" tap target when the
/// text overflows. Uses [LayoutBuilder] (not screen-width guesses) to get
/// the row's actual available width, then measures the "Read More" label
/// with a second [TextPainter] so the cut always reserves room for it —
/// without that reservation the link gets clipped off the last line.
class _CardDescription extends StatelessWidget {
  final String text;
  const _CardDescription({required this.text});

  static const _style = TextStyle(color: AppColors.grey7E, fontSize: 12);
  static const _maxLines = 2;
  static const _readMoreLabel = ' Read More';

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final readMoreStyle = _style.copyWith(
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w700,
    );

    void openFull() {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: SingleChildScrollView(
            child: Text(text, style: _style),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final tp = TextPainter(
          text: TextSpan(text: text, style: _style),
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);

        if (!tp.didExceedMaxLines) {
          return Text(text, style: _style, maxLines: _maxLines);
        }

        // Measure the link so we know how much room to reserve for it on
        // the last line — this is what keeps "Read More" from getting
        // clipped away.
        final rmPainter = TextPainter(
          text: TextSpan(text: _readMoreLabel, style: readMoreStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        // Character index at the position just before where "Read More"
        // must start on the final line.
        final cutOffset = tp
            .getPositionForOffset(
              Offset(availableWidth - rmPainter.width, tp.height - 1),
            )
            .offset;

        int cut = cutOffset.clamp(0, text.length);
        // Small buffer so the ellipsis + link isn't jammed against the
        // preceding word.
        if (cut > 3) cut -= 3;
        final truncated = text.substring(0, cut).trimRight();

        return Text.rich(
          TextSpan(children: [
            TextSpan(text: '$truncated...', style: _style),
            TextSpan(
              text: _readMoreLabel,
              style: readMoreStyle,
              recognizer: TapGestureRecognizer()..onTap = openFull,
            ),
          ]),
          maxLines: _maxLines,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}

/// Overflow menu — same shape [SchoolCourseListItemCard] uses.
class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _CardMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[
      if (onEdit != null)
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
      if (onDelete != null)
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 20,
      height: 20,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: AppColors.grey7E),
        padding: EdgeInsets.zero,
        onSelected: (v) {
          if (v == 'edit') onEdit?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => items,
      ),
    );
  }
}
