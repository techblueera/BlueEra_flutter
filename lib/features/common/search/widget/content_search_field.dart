import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/search/controller/content_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Header search field with an inline type-ahead dropdown.
///
/// Looks like [CommonSearchBar] (same height, hint, icons) so it drops into
/// the frosted pill in the Connect header without a visual change, but it owns
/// a focus node and floats its suggestion panel in an [Overlay] anchored to the
/// field via a [LayerLink]. The overlay approach keeps the panel above the
/// TabBar/TabBarView and above the header's own BackdropFilter — inlining it in
/// the header Column would push the tabs down on every keystroke.
///
/// Shows recent searches while the field is empty and up to
/// [ContentSearchController.maxSuggestions] live results once there is a query.
class ContentSearchField extends StatefulWidget {
  const ContentSearchField({super.key, this.hintText});

  final String? hintText;

  @override
  State<ContentSearchField> createState() => _ContentSearchFieldState();
}

class _ContentSearchFieldState extends State<ContentSearchField> {
  final ContentSearchController controller =
      getOrPut(() => ContentSearchController());

  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    controller.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (controller.focusNode.hasFocus) {
      _showPanel();
    } else {
      _hidePanel();
    }
  }

  void _showPanel() {
    if (_entry != null || !mounted) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    controller.isPanelOpen.value = true;
  }

  /// Close the panel, then open the result. Ordering matters: the entry lives
  /// in the Navigator's overlay, so it would hang above the pushed screen for a
  /// frame if navigation went first.
  void _open(SearchResultItem item) {
    _dismiss();
    controller.openResult(item);
  }

  void _hidePanel() {
    _entry?.remove();
    _entry = null;
    controller.isPanelOpen.value = false;
  }

  void _dismiss() {
    controller.focusNode.unfocus();
    _hidePanel();
  }

  @override
  void dispose() {
    controller.focusNode.removeListener(_onFocusChange);
    // The entry lives in the Overlay, not this subtree — it has to be pulled
    // out by hand or it survives the field (e.g. when the collapsing header
    // hides the search row mid-scroll).
    _hidePanel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _link, child: _buildField());
  }

  // ── Field ───────────────────────────────────────────────────────────

  Widget _buildField() {
    return Obx(() {
      final hasText = controller.query.value.isNotEmpty;
      return SizedBox(
        height: SizeConfig.size40,
        child: TextField(
          controller: controller.queryController,
          focusNode: controller.focusNode,
          onChanged: controller.onQueryChanged,
          onTap: _showPanel,
          onSubmitted: (_) {
            // Enter opens the top hit when there is one; otherwise the panel
            // just stays put with whatever state it is showing.
            final list = controller.suggestions;
            if (list.isNotEmpty) _open(list.first);
          },
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(color: AppColors.black, fontSize: SizeConfig.medium),
          decoration: InputDecoration(
            hintText: widget.hintText?.tr ?? AppStrings.searchHere.tr,
            hintStyle: TextStyle(
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8, vertical: SizeConfig.size5),
              child: LocalAssets(
                imagePath: AppIconAssets.chat_search,
                imgColor: AppColors.mainTextColor,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: SizeConfig.size36),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: controller.clearQuery,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      child: Icon(Icons.clear,
                          color: AppColors.black28, size: SizeConfig.paddingXL),
                    ),
                  )
                : null,
            isDense: true,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    });
  }

  // ── Dropdown ────────────────────────────────────────────────────────

  Widget _buildOverlay(BuildContext overlayContext) {
    final screenWidth = MediaQuery.of(overlayContext).size.width;

    // The follower tracks the field, so shifting it left by the field's own
    // global x lands the panel on the screen's left edge — full-bleed width
    // while still riding the field vertically (keyboard, header animation).
    final fieldBox = context.findRenderObject() as RenderBox?;
    final fieldLeft = (fieldBox != null && fieldBox.hasSize)
        ? fieldBox.localToGlobal(Offset.zero).dx
        : 0.0;

    return Stack(
      children: [
        // Tap-outside barrier. Translucent so it closes the panel without
        // eating the tap's visual affordance elsewhere on screen.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismiss,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(-fieldLeft, 8),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: screenWidth,
              child: Obx(() {
                final child = _panelBody();
                if (child == null) return const SizedBox.shrink();
                return Material(
                  color: AppColors.white,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  // Edge-to-edge, so only the bottom corners are rounded —
                  // rounding the sides would leave slivers of background at
                  // the screen edges.
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: child,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// The panel's contents for the current state, or null when there is nothing
  /// worth showing (empty field with no recents) so no empty card is drawn.
  Widget? _panelBody() {
    final hasQuery = controller.query.value.trim().isNotEmpty;

    if (!hasQuery) {
      if (controller.recentSearches.isEmpty) return null;
      return _recentsList();
    }

    if (controller.suggestions.isNotEmpty) return _suggestionList();

    if (controller.isLoading.value || !controller.hasSearched.value) {
      return _statusRow(
        child: SizedBox(
          height: SizeConfig.size16,
          width: SizeConfig.size16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
        label: 'Searching…',
      );
    }

    return _statusRow(
      child: Icon(Icons.search_off,
          size: SizeConfig.size18, color: AppColors.secondaryTextColor),
      label: AppStrings.noResultsFound.tr,
    );
  }

  Widget _statusRow({required Widget child, required String label}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          SizedBox(width: SizeConfig.size10),
          Flexible(
            child: CustomText(
              label,
              fontSize: 12.5,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recents ─────────────────────────────────────────────────────────

  Widget _recentsList() {
    final recents = controller.recentSearches;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              SizeConfig.size14, SizeConfig.size10, SizeConfig.size6, 0),
          child: Row(
            children: [
              Expanded(
                child: CustomText(
                  'Recent searches',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              InkWell(
                onTap: controller.clearRecentSearches,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size5),
                  child: CustomText(
                    'Clear all',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: SizeConfig.size6),
            itemCount: recents.length,
            itemBuilder: (_, i) => _recentRow(recents[i]),
          ),
        ),
      ],
    );
  }

  Widget _recentRow(String term) {
    return InkWell(
      onTap: () => controller.applyRecentSearch(term),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14, vertical: SizeConfig.size9),
        child: Row(
          children: [
            Icon(Icons.history,
                size: SizeConfig.size18, color: AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                term,
                fontSize: 13,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => controller.removeRecentSearch(term),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size4),
                child: Icon(Icons.close,
                    size: SizeConfig.size14,
                    color: AppColors.secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Suggestions ─────────────────────────────────────────────────────

  Widget _suggestionList() {
    final items = controller.suggestions;
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: SizeConfig.size57,
        color: AppColors.greyE5,
      ),
      itemBuilder: (_, i) => _suggestionRow(items[i]),
    );
  }

  Widget _suggestionRow(SearchResultItem item) {
    return InkWell(
      onTap: () => _open(item),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
        child: Row(
          children: [
            _thumb(item),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    item.title,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      item.subtitle!,
                      fontSize: 11,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            _typeBadge(item.entityType),
          ],
        ),
      ),
    );
  }

  Widget _thumb(SearchResultItem item) {
    final isPerson =
        item.entityType == 'user' || item.entityType == 'business';
    final size = SizeConfig.size36;
    final radius = isPerson ? size / 2 : 8.0;
    final url = item.imageUrl ?? '';

    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: Icon(_entityIcon(item.entityType),
          size: SizeConfig.size18, color: AppColors.secondaryTextColor),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }

  Widget _typeBadge(String entityType) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size6, vertical: SizeConfig.size2),
      decoration: BoxDecoration(
        color: AppColors.greyE5,
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        _entityLabel(entityType),
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  String _entityLabel(String type) {
    switch (type) {
      case 'post':
        return 'Post';
      case 'video':
        return 'Video';
      case 'user':
        return 'Profile';
      case 'business':
        return 'Business';
      default:
        return type.isEmpty
            ? 'Result'
            : '${type[0].toUpperCase()}${type.substring(1)}';
    }
  }

  IconData _entityIcon(String type) {
    switch (type) {
      case 'post':
        return Icons.article_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'user':
        return Icons.person_outline;
      case 'business':
        return Icons.storefront_outlined;
      default:
        return Icons.search;
    }
  }
}
