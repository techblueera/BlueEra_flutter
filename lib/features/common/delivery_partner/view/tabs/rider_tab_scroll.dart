import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

/// The scrollable body every rider-dashboard tab sits in.
///
/// Each tab is its own widget now, but the four of them still have to scroll
/// identically — same top gap, same bottom room for the nav bar — or switching
/// tabs shifts the content under the user's thumb. One shell, four tabs.
class RiderTabScroll extends StatelessWidget {
  const RiderTabScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
