import 'package:flutter/material.dart';

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  TabBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(TabBarDelegate oldDelegate) => false;
}