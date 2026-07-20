import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/view/packages/create_your_own_packages_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
  const MyLabPackagesScreen({super.key});

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
            child: Text('Delete',
                style: TextStyle(color: Colors.red.shade600)),
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
      appBar: const CommonBackAppBar(title: 'My Packages'),
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
          if (_pkgCtrl.myPackages.isEmpty) {
            return _emptyState();
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
            itemCount: _pkgCtrl.myPackages.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
            itemBuilder: (_, i) => _PackageTile(
              pkg: _pkgCtrl.myPackages[i],
              onDelete: () => _confirmDelete(_pkgCtrl.myPackages[i]),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Package',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _emptyState() {
    // Wrapped in a scrollable so RefreshIndicator still works on empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: SizeConfig.size48),
        Icon(Icons.inventory_2_outlined,
            size: 56, color: Colors.grey.shade400),
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
            'Tap "Add Package" to bundle your tests into a package.',
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

class _PackageTile extends StatelessWidget {
  final LabPackage pkg;
  final VoidCallback onDelete;

  const _PackageTile({required this.pkg, required this.onDelete});

  static const Color _accent = AppColors.primaryColor;
  static const Color _line = Color(0xFFE5E7EB);

  int get _testCount {
    // Prefer populated list; fall back to id list.
    if ((pkg.tests?.isNotEmpty ?? false)) return pkg.tests!.length;
    return pkg.testIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final img = (pkg.imageUrl ?? '').trim();
    final mrp = pkg.packageMrp;
    final price = pkg.customerPrice;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
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
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  pkg.name ?? 'Untitled package',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 12, color: AppColors.secondaryTextColor),
                    const SizedBox(width: 4),
                    CustomText(
                      _testCount == 1 ? '1 test' : '$_testCount tests',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (price != null)
                      CustomText(
                        '₹$price',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    if (mrp != null && price != null && mrp > price) ...[
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        '₹$mrp',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ] else if (mrp != null && price == null) ...[
                      CustomText(
                        '₹$mrp',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _actionsMenu(),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF4F6FA),
        alignment: Alignment.center,
        child: Icon(Icons.inventory_2_outlined,
            size: 22, color: Colors.grey.shade400),
      );

  Widget _actionsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          size: 18, color: AppColors.secondaryTextColor),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}
