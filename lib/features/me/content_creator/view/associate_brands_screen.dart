import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/model/business_filter_res_model.dart';
import 'package:BlueEra/features/me/content_creator/controller/associate_brands_controller.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen "Add associate brands" search. The signature element is the
/// circular dark brand mark (mirrors how brands appear on the Overview strip):
/// a business is "worn" as its logo, and selecting it flips the mark to a
/// primary ring + check so the row previews exactly how the brand will read on
/// the profile.
class AssociateBrandsScreen extends StatefulWidget {
  const AssociateBrandsScreen({super.key});

  @override
  State<AssociateBrandsScreen> createState() => _AssociateBrandsScreenState();
}

class _AssociateBrandsScreenState extends State<AssociateBrandsScreen> {
  static const _brandBg = Color(0xFF15151A);
  static const _cardBorder = Color(0xFFEDEFF4);

  late final AssociateBrandsController _c;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // The Overview owns the EarnArtistController; reuse it so a save writes
    // straight back to the profile the strip is reading.
    final earn = Get.isRegistered<EarnArtistController>()
        ? Get.find<EarnArtistController>()
        : Get.put(EarnArtistController());
    _c = Get.put(AssociateBrandsController(earn));
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    Get.delete<AssociateBrandsController>();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      _c.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent body so the app-wide [AppHomeBackground] (painted in
    // GetMaterialApp.builder, driven by the App Background settings) shows
    // through; the shared white app bar / result cards / save bar stay opaque.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        isLeading: true,
        backArrowColor: AppColors.mainTextColor,
        onBackTap: () => Get.back(),
        isCustomTitleWidget: _titleBlock,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _searchField(),
            Expanded(child: _body()),
          ],
        ),
      ),
      bottomNavigationBar: _saveBar(),
    );
  }

  // ─── TITLE ───────────────────────────────────────────────────────────────
  /// Two-line title for the shared app bar: the section name over a reactive
  /// selected-count / prompt line.
  Widget _titleBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText('Associate Brands',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
        Obx(() => CustomText(
              _c.selectedCount == 0
                  ? 'Search & tag the brands you work with'
                  : '${_c.selectedCount} selected',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _c.selectedCount == 0
                  ? AppColors.secondaryTextColor
                  : AppColors.primaryColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
      ],
    );
  }

  // ─── SEARCH FIELD ────────────────────────────────────────────────────────
  Widget _searchField() {
    // White band behind the search bar so it reads as part of the header
    // chrome (continuous with the app bar) rather than floating over the
    // themed app background. The field itself is a light-grey pill on top.
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size8, SizeConfig.size16, SizeConfig.size12),
      child: Container(
        // Light-greyish fill + textField shadow + border — same treatment as
        // the shared [CommonTextField], with a soft grey pill on the white band.
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(width: SizeConfig.size12),
            Icon(Icons.search_rounded,
                size: 20, color: AppColors.secondaryTextColor),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                // Debounced in [onQueryChanged] — no separate onSubmitted call
                // is needed (it would just fire a duplicate request).
                onChanged: _c.onQueryChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: SizeConfig.size14),
                  hintText: 'Search shops, brands, stores…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor.withValues(alpha: 0.7),
                  ),
                  // Transparent fill so the grey pill shows uniformly — the app
                  // theme's inputDecorationTheme otherwise fills the text area
                  // white, leaving the prefix/suffix icons on grey.
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: null,
                ),
              ),
            ),
            Obx(() => _c.query.value.isEmpty
                ? const SizedBox.shrink()
                : InkWell(
                    onTap: () {
                      _searchCtrl.clear();
                      _c.onQueryChanged('');
                    },
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(SizeConfig.size8),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.secondaryTextColor),
                    ),
                  )),
            SizedBox(width: SizeConfig.size4),
          ],
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────────────
  Widget _body() {
    return Obx(() {
      if (_c.isLoading.value) return _loadingList();
      if (!_c.didSearch.value) return _initialPrompt();
      if (_c.error.value.isNotEmpty && _c.results.isEmpty) {
        return _message(
          icon: Icons.wifi_off_rounded,
          title: 'Couldn’t load results',
          subtitle: _c.error.value,
        );
      }
      if (_c.results.isEmpty) {
        return _message(
          icon: Icons.storefront_outlined,
          title: 'No brands found',
          subtitle: 'Try a different name or a broader search.',
        );
      }
      return ListView.separated(
        controller: _scrollCtrl,
        padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size4,
            SizeConfig.size16, SizeConfig.size24),
        itemCount: _c.results.length + (_c.hasMore.value ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (_, i) {
          if (i >= _c.results.length) return _loadMoreTile();
          return _resultRow(_c.results[i]);
        },
      );
    });
  }

  Widget _loadMoreTile() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
          ),
        ),
      ),
    );
  }

  // ─── RESULT ROW ──────────────────────────────────────────────────────────
  Widget _resultRow(BusinessFilterData b) {
    return Obx(() {
      final selected = _c.isSelected(b.id);
      return InkWell(
        onTap: () => _c.toggle(b),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(SizeConfig.size12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primaryColor.withValues(alpha: 0.55)
                  : _cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _brandMark(b, selected),
              SizedBox(width: SizeConfig.size12),
              Expanded(child: _brandInfo(b)),
              SizedBox(width: SizeConfig.size8),
              _addToggle(selected),
            ],
          ),
        ),
      );
    });
  }

  /// The signature circular brand mark — dark logo disc that gains a primary
  /// ring + check badge when selected (echoing the Overview strip).
  Widget _brandMark(BusinessFilterData b, bool selected) {
    final logo = b.logo ?? '';
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brandBg,
              border: Border.all(
                color: selected ? AppColors.primaryColor : _cardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: logo.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: _brandBg),
                    errorWidget: (_, __, ___) => _initialMark(b.businessName),
                  )
                : _initialMark(b.businessName),
          ),
          if (selected)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialMark(String? name) {
    final ch = (name != null && name.trim().isNotEmpty)
        ? name.trim().characters.first.toUpperCase()
        : '?';
    return Center(
      child: CustomText(ch,
          fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
    );
  }

  Widget _brandInfo(BusinessFilterData b) {
    final category =
        b.subCategoryDetails?.name ?? b.categoryDetails?.name ?? b.typeOfBusiness;
    final place = b.cityStatePincode?.trim().isNotEmpty == true
        ? b.cityStatePincode!.trim()
        : (b.address ?? '');
    final dist = _distanceLabel(b.distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          b.businessName?.trim().isNotEmpty == true
              ? b.businessName!.trim()
              : 'Unnamed business',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (category != null && category.trim().isNotEmpty) ...[
          SizedBox(height: SizeConfig.size4),
          _categoryChip(category.trim()),
        ],
        if (place.trim().isNotEmpty || dist != null) ...[
          SizedBox(height: SizeConfig.size6),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 13, color: AppColors.secondaryTextColor),
              const SizedBox(width: 3),
              Flexible(
                child: CustomText(
                  [
                    if (place.trim().isNotEmpty) place.trim(),
                    if (dist != null) dist,
                  ].join('  ·  '),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        label,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _addToggle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_rounded : Icons.add_rounded,
            size: 15,
            color: selected ? Colors.white : AppColors.primaryColor,
          ),
          const SizedBox(width: 3),
          CustomText(
            selected ? 'Added' : 'Add',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  String? _distanceLabel(num? km) {
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
  }

  // ─── STATES ──────────────────────────────────────────────────────────────
  Widget _initialPrompt() {
    return _message(
      icon: Icons.storefront_rounded,
      title: 'Find the brands you work with',
      subtitle:
          'Search nearby shops, stores and businesses, then add them as your associate brands.',
    );
  }

  Widget _message(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primaryColor),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(title,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center),
            SizedBox(height: SizeConfig.size8),
            CustomText(subtitle,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _loadingList() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size4,
          SizeConfig.size16, SizeConfig.size24),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
      itemBuilder: (_, __) => buildLoadingShimmer(
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1),
          ),
          child: Row(
            children: [
              shimmerContainer(width: 60, height: 60, radius: 30),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmerContainer(width: 150, height: 14),
                    SizedBox(height: SizeConfig.size8),
                    shimmerContainer(width: 90, height: 12),
                    SizedBox(height: SizeConfig.size8),
                    shimmerContainer(width: 120, height: 10),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              shimmerContainer(width: 64, height: 30, radius: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SAVE BAR ────────────────────────────────────────────────────────────
  Widget _saveBar() {
    return Obx(() {
      if (!_c.hasChanges) return const SizedBox.shrink();
      final saving = _c.isSaving.value;
      return Container(
        padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
            SizeConfig.size16, SizeConfig.size16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: saving ? null : _c.save,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      _c.selectedCount == 0
                          ? 'Save'
                          : 'Save ${_c.selectedCount} brand${_c.selectedCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }
}
