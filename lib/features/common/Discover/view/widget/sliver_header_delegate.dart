import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  SliverHeaderDelegate({required this.child});

  @override
  double get minExtent => SizeConfig.size65;
  @override
  double get maxExtent => SizeConfig.size65;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(SliverHeaderDelegate oldDelegate) => true;
}