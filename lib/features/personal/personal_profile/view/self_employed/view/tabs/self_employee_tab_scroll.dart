import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

/// The scrollable body every self-employed dashboard tab sits in.
///
/// Each tab is its own widget now, but the three still have to scroll
/// identically — same top gap, same bottom room for the nav bar — or switching
/// tabs shifts the content under the user's thumb.
///
/// Takes a single child rather than a list, exactly as the screen's own
/// `_tabScroll` did: the child is handed the viewport's constraints directly,
/// and wrapping it in a Column would left-align anything that doesn't size
/// itself to the full width.
class SelfEmployeeTabScroll extends StatelessWidget {
  const SelfEmployeeTabScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + 30,
      ),
      child: child,
    );
  }
}
