import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Real Material tab scaffold for the "Me" business/individual home screens.
///
/// Built on a [NestedScrollView] so that on scroll the [topBar] **scrolls away**
/// (freeing screen space) while the [TabBar] **pins to the top** — and scrolls
/// back into view when the user scrolls up. Mirrors the header/tab behaviour
/// already used by `social_main.dart`.
///
/// The tab row is **adaptive**: when the labels fit the width they stretch to
/// fill it evenly (`TabAlignment.fill`, no left-clustered tabs); only when they
/// would overflow does it become horizontally scrollable.
///
/// The owning screen creates and owns the [TabController] (so it can listen for
/// tab changes to fire lazy per-tab fetches). Each entry in [tabViews] is the
/// full body for that tab and MUST be a scrollable (e.g. a SingleChildScrollView
/// / ListView) so the NestedScrollView can drive the collapsing header from it.
class HomeTabScaffold extends StatelessWidget {
  const HomeTabScaffold({
    super.key,
    required this.controller,
    required this.tabLabels,
    required this.tabViews,
    this.topBar,
    this.topBarHeight,
    this.tabBarColor = Colors.white,
  }) : assert(tabLabels.length == tabViews.length,
            'tabLabels and tabViews must have the same length');

  final TabController controller;
  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget? topBar;

  /// Full height of [topBar] **including** the status-bar inset (i.e. the
  /// `topInset + barHeight` the screen already computes).
  ///
  /// When provided, the header uses a collapsing [SliverAppBar]: the top bar
  /// collapses down to just the status-bar strip (so its gradient stays behind
  /// the notch) and the [TabBar] pins *below* the notch — never sliding under
  /// the status bar. When null, the top bar simply scrolls fully away and the
  /// tab bar pins at the very top (legacy behaviour).
  final double? topBarHeight;
  final Color tabBarColor;

  static const TextStyle _labelStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
  static const TextStyle _unselectedLabelStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  /// `kTabLabelPadding` is 16px on each side of a tab label.
  static const double _labelPadding = 32.0;

  /// Height of the pinned tab bar row.
  static const double _tabBarHeight = 48.0;

  /// Measures the tab labels: [total] = sum of all (text + per-tab padding),
  /// [widest] = the single widest one. Uses the bold (selected) style and the
  /// user's text scale so we never under-measure.
  ({double total, double widest}) _measureTabs(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    double total = 0;
    double widest = 0;
    for (final label in tabLabels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: _labelStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width + _labelPadding;
      total += w;
      if (w > widest) widest = w;
    }
    return (total: total, widest: widest);
  }

  Widget _buildTabBar() {
    return Material(
      color: tabBarColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final m = _measureTabs(context);
          // Three layouts, picked so labels are never crammed, never
          // left-clustered, and only scroll when they truly overflow:
          //   • FILL   — every tab fits its equal slot (maxW / count): stretch
          //              all tabs to fill the width evenly.
          //   • CENTER — tabs fit at their natural widths but unevenly (a long
          //              label wouldn't fit an equal slot): lay them at natural
          //              width, centred (no blank-on-the-right left-cluster).
          //   • START  — natural widths overflow the width: scroll from the left.
          final bool cleanFill = m.widest * tabLabels.length <= maxW;
          final bool fitsNatural = m.total <= maxW;
          final TabAlignment alignment = cleanFill
              ? TabAlignment.fill
              : (fitsNatural ? TabAlignment.center : TabAlignment.start);
          return TabBar(
            controller: controller,
            isScrollable: !cleanFill,
            tabAlignment: alignment,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.mainTextColor,
            indicatorColor: AppColors.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: _labelStyle,
            unselectedLabelStyle: _unselectedLabelStyle,
            tabs: [for (final label in tabLabels) Tab(text: label)],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        if (topBar != null && topBarHeight != null) {
          // Collapsing header: the top bar (flexibleSpace) shrinks to the
          // status-bar strip as you scroll, and the TabBar (bottom) pins just
          // below the notch — so the tabs never slide under the status bar.
          return [
            SliverAppBar(
              pinned: true,
              floating: false,
              primary: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              collapsedHeight: topInset > 0 ? topInset : null,
              // expandedHeight covers the top bar AND the bottom tab row; the
              // `bottom` is drawn over the flexibleSpace's lower edge, so the
              // tab height must be included here or it would cover the header.
              expandedHeight: topBarHeight! + _tabBarHeight,
              elevation: 0,
              // Transparent so the top bar's own BackdropFilter blurs the
              // content behind it (the frosted-glass header look) instead of a
              // flat app-bar fill. The pinned tab row carries its own opaque
              // background via `_buildTabBar()`.
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              // The bar is placed directly (NOT via FlexibleSpaceBar) so its
              // own BackdropFilter keeps frosting the content behind it — the
              // glassmorphic look. FlexibleSpaceBar composites in its own layer
              // and would kill the blur. Align-top + SizedBox keeps the bar at
              // its real height; as the app bar shrinks it's clipped down to the
              // status-bar strip, with the tab row pinned just below it.
              flexibleSpace: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(height: topBarHeight, child: topBar),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(_tabBarHeight),
                child: _buildTabBar(),
              ),
            ),
          ];
        }
        return [
          // Scrolls away on scroll-down, comes back on scroll-up.
          if (topBar != null) SliverToBoxAdapter(child: topBar!),
          // Pinned tab bar — stays stuck at the top once the header is gone.
          SliverAppBar(
            pinned: true,
            floating: false,
            primary: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            collapsedHeight: 0,
            expandedHeight: 0,
            elevation: 0,
            backgroundColor: tabBarColor,
            surfaceTintColor: tabBarColor,
            forceElevated: innerBoxIsScrolled,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_tabBarHeight),
              child: _buildTabBar(),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: controller,
        children: [
          for (final view in tabViews) _KeepAliveTab(child: view),
        ],
      ),
    );
  }
}

/// Keeps a tab's subtree alive while a different tab is on screen.
///
/// [TabBarView] disposes off-screen pages by default, so every switch back
/// re-ran that tab's `initState` — refetching data the controller already held
/// and, for the Post tab, resetting [FeedScreen] to page 1, throwing away the
/// pages loaded so far along with the scroll position. Keeping the page alive
/// makes a tab load once per screen visit; the explicit refresh paths
/// (pull-to-refresh, post-publish) still reload it.
///
/// Cost: every tab the user has opened stays in memory until the screen is
/// popped — the usual trade for not re-fetching.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
