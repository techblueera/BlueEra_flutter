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

class _PackageTile extends StatefulWidget {
  final LabPackage pkg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageTile({
    required this.pkg,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PackageTile> createState() => _PackageTileState();
}

class _PackageTileState extends State<_PackageTile> {
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _green = Color(0xff008000);
  static const Color _muted = Color(0xFF7A8290);

  bool _descExpanded = false;

  int get _testCount {
    // Prefer populated list; fall back to id list.
    if ((widget.pkg.tests?.isNotEmpty ?? false))
      return widget.pkg.tests!.length;
    return widget.pkg.testIds.length;
  }

  int? get _discountPercent {
    final mrp = widget.pkg.packageMrp;
    final price = widget.pkg.customerPrice;
    if (mrp == null || price == null || mrp <= 0 || price >= mrp) return null;
    return (((mrp - price) / mrp) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.pkg;
    final img = (pkg.imageUrl ?? '').trim();
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // No IntrinsicHeight: it walks children for intrinsic sizing, which
      // breaks the LayoutBuilder used to detect description overflow. The
      // cover carries an explicit height; the right column drives the rest.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 140,
              height: 150,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                      placeholder: (_, __) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size2,
                SizeConfig.size2,
                SizeConfig.size2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomText(
                          pkg.name ?? 'Untitled package',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _actionsMenu(),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size4),
                  _priceRow(),
                  SizedBox(height: SizeConfig.size4),
                  _descriptionRow(),
                  // Mockup has no divider between the description and the
                  // tests pill — just whitespace, so the pill reads as its
                  // own primary CTA.
                  SizedBox(height: SizeConfig.size10),
                  _testsPill(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF4F6FA),
        alignment: Alignment.center,
        child: Icon(Icons.inventory_2_outlined,
            size: 26, color: Colors.grey.shade400),
      );

  Widget _priceRow() {
    final price = widget.pkg.customerPrice;
    final mrp = widget.pkg.packageMrp;
    final discount = _discountPercent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (price != null)
          CustomText(
            '₹$price',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          )
        else if (mrp != null)
          CustomText(
            '₹$mrp',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
        if (mrp != null && price != null && mrp > price) ...[
          SizedBox(width: SizeConfig.size6),
          CustomText(
            '₹$mrp',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _muted,
            decoration: TextDecoration.lineThrough,
          ),
        ],
        if (discount != null) ...[
          SizedBox(width: SizeConfig.size10),
          // Container(
          //   width: 6,
          //   height: 6,
          //   decoration: const BoxDecoration(
          //     color: _green,
          //     shape: BoxShape.circle,
          //   ),
          // ),
          // SizedBox(width: SizeConfig.size4),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: AppColors.green7F.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
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
                  color: _green,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _descriptionRow() {
    final desc = (widget.pkg.description ?? '').trim();
    if (desc.isEmpty) {
      return const SizedBox.shrink();
    }
    final baseStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: _muted,
      height: 1.35,
    );
    const linkStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryColor,
    );
    // Only surface the "…Read More" toggle when the description actually
    // overflows 2 lines at the current row width — short descriptions
    // render plain, matching the mockup.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: desc, style: baseStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;
        if (!overflows) {
          return Text(desc, style: baseStyle);
        }
        return GestureDetector(
          onTap: () => setState(() => _descExpanded = !_descExpanded),
          child: RichText(
            maxLines: _descExpanded ? null : 2,
            overflow:
                _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            text: TextSpan(
              style: baseStyle,
              children: [
                TextSpan(text: desc),
                TextSpan(
                  text: _descExpanded ? '  Show Less' : '  …Read More',
                  style: linkStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _testsPill() {
    // Solid green pill matching the mockup: laboratory glyph on the left,
    // "N Tests Available" on the right, centered inside a moderately tall
    // (~size8 vertical) rounded container so it reads as a primary CTA.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.laboratoryIcon,
            imgColor: AppColors.white,
            width: 18,
            height: 18,
          ),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            '$_testCount ${_testCount == 1 ? 'Test' : 'Tests'} Available',
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _actionsMenu() {
    return SizedBox(
      width: 28,
      height: 24,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert,
            size: 18, color: AppColors.secondaryTextColor),
        padding: EdgeInsets.zero,
        onSelected: (v) {
          if (v == 'edit') widget.onEdit();
          if (v == 'delete') widget.onDelete();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}
