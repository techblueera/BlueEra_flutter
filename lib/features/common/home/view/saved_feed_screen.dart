import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';


class SavedFeedScreen extends StatefulWidget {
  final String? query;
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final SavedFeedTab selectedTab;
  final double headerHeight;

  const SavedFeedScreen({
    super.key,
    this.query,
    this.onHeaderVisibilityChanged,
    required this.selectedTab,
    required this.headerHeight
  });

  @override
  State<SavedFeedScreen> createState() => _SavedFeedScreenState();
}

class _SavedFeedScreenState extends State<SavedFeedScreen> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.savedPost,
      ),
        body: _buildTabView());
  }

  Widget _buildTabView() {
    switch (widget.selectedTab) {
      case SavedFeedTab.posts:
        return FeedScreen(
            key: ValueKey('feedScreen_saved'),
            postFilterType: PostType.saved,
            onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
            headerHeight: widget.headerHeight
        );
      // case SavedFeedTab.videos:
      //   return VideoSavedFeedSection(
      //     onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
      //     query: widget.query,
      //     headerHeight: widget.headerHeight
      //   );
      // case SavedFeedTab.shorts:
      //   return ShortsSavedFeedSection(
      //       onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
      //       query: widget.query,
      //       headerHeight: widget.headerHeight
      //   );


    }
  }

  void _toggleAppBarAndBottomNav(bool visible) {
    if (_isVisible != visible && mounted) {
      setState(() => _isVisible = visible);
      widget.onHeaderVisibilityChanged?.call(visible); // Notify parent to hide/show bottom nav
    }
  }

}
