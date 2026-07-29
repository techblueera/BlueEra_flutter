import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/view/medical_product_selection_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Level-1 categories of a tapped medical root (the screen is named for the
/// level-2 leaves its tiles lead to).
///
/// Opens IMMEDIATELY on tap and fetches its own subtree, showing a shimmer of
/// the grid while the call is in flight. The fetch used to run on the previous
/// screen with a spinner on the tapped tile, which left the user staring at the
/// grid they'd just tapped with no sense that anything had happened.
///
/// [level2Categories] is the escape hatch for a caller that already holds the
/// children — on the pre-`?level=` backend the roots arrive with the whole tree
/// attached, so there's nothing to fetch and the grid paints on the first frame.
class MedicalLevel2CategoryScreen extends StatefulWidget {
  final String title;

  /// Children the caller already has. When non-empty no request is made.
  final List<MedicalNestedCategoryModel> level2Categories;

  /// Root category id to expand when [level2Categories] is empty.
  final String? categoryId;

  const MedicalLevel2CategoryScreen({
    super.key,
    required this.title,
    this.level2Categories = const [],
    this.categoryId,
  });

  @override
  State<MedicalLevel2CategoryScreen> createState() =>
      _MedicalLevel2CategoryScreenState();
}

class _MedicalLevel2CategoryScreenState
    extends State<MedicalLevel2CategoryScreen> {
  final _controller = getOrPut(() => MedicalController());

  late List<MedicalNestedCategoryModel> _categories;
  bool _loading = false;

  // 4 soft pastel tile backgrounds — picked pseudo-randomly per item
  // (deterministic so a given index keeps the same color across rebuilds).
  static const List<Color> _tileColors = [
    Color(0xFFE3F2FD), // soft blue
    Color(0xFFFFF3E0), // soft peach
    Color(0xFFE8F5E9), // soft mint
    Color(0xFFFCE4EC), // soft pink
  ];

  Color _tileColorFor(MedicalNestedCategoryModel category, int index) {
    // Mix index with name hash so order changes still feel random.
    final seed = (category.name?.hashCode ?? 0) ^ (index * 31);
    return _tileColors[seed.abs() % _tileColors.length];
  }

  String get title => widget.title;

  @override
  void initState() {
    super.initState();
    _categories = widget.level2Categories;
    if (_categories.isEmpty && (widget.categoryId ?? '').isNotEmpty) {
      _loadSubtree();
    }
  }

  Future<void> _loadSubtree() async {
    setState(() => _loading = true);
    final subtree =
        await _controller.fetchMedicalCategorySubtree(widget.categoryId!);
    if (!mounted) return;
    setState(() {
      _categories = subtree?.children ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: title),
      body: _loading
          ? _buildShimmer()
          : _categories.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12,
                    SizeConfig.size4,
                    SizeConfig.size12,
                    SizeConfig.size40,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: SizeConfig.size10,
                      mainAxisSpacing: SizeConfig.size10,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = _categories[index];
                        return _buildSubCategoryCard(category, index);
                      },
                      childCount: _categories.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: SizeConfig.size30),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.95),
            AppColors.primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                CustomText(
                  '${_categories.length} ${AppStrings.medicalCategoriesAvailableSuffix.tr}',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton of this screen's own layout — the gradient header block, then a
  /// 3-column grid of tiles at the same aspect ratio and spacing as the real
  /// one, so the swap to content reads as a load rather than a layout jump.
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size14,
              SizeConfig.size14,
              SizeConfig.size10,
            ),
            child: buildLoadingShimmer(
              child: shimmerContainer(height: 74, radius: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size4,
              SizeConfig.size12,
              SizeConfig.size40,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _shimmerTileCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (_, __) => buildLoadingShimmer(
                child: shimmerContainer(radius: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enough tiles to fill a phone screen — the real count isn't known until the
  /// subtree lands.
  static const int _shimmerTileCount = 9;

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 56,
              color: AppColors.primaryColor.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            AppStrings.medicalNoSubcategoriesAvailable,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.medicalPleaseCheckBackLater,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryCard(MedicalNestedCategoryModel category, int index) {
    final childCount = category.children?.length ?? 0;
    final hasChildren = childCount > 0;
    final tileColor = _tileColorFor(category, index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Always navigates. The old `if (children.isNotEmpty)` meant that
          // tapping a LEAF sub-category did nothing at all — no screen, no
          // message — which is the level most medical categories bottom out
          // at. A leaf opens on itself; see
          // [MedicalProductSelectionScreen.categoriesToOpen].
          Get.to(() => MedicalProductSelectionScreen(
                arrLevel3Category:
                    MedicalProductSelectionScreen.categoriesToOpen(category),
              ));
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image fills its area â€” no extra padding around it
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          child: _buildImage(category),
                        ),
                      ),
                    ),
                    if (hasChildren)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CustomText(
                            '$childCount',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tight footer â€” name only (compact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: CustomText(
                  category.name ?? '',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(MedicalNestedCategoryModel category) {
    final placeholder = Center(
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        width: 56,
        height: 56,
      ),
    );

    final url = (category.image ?? '').trim();
    if (url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: placeholder,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
