import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/controller/earn_coin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/model/earn_coin_models.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Palette from the design: primary blue for structure/values, gold for the
// coin/XP accents, green for "credited"/verified/progress.
const _blue = AppColors.primaryColor;
const _gold = Color(0xFFF5B81C);
const _green = Color(0xFF16A34A);
const _cardBorder = AppColors.greyE5;
const _headerGrad = LinearGradient(
  colors: [Color(0xFF1C7EE8), Color(0xFF3D9BFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Coin Wallet dashboard — the 5-tab coin/gamification screen
/// (Dashboard, Tasks, History, Rank, Streak) opened from "View Details" on the
/// wallet. Contract: docs/backend/FLUTTER-MASTER-GUIDE.md
/// (frontend gaps: docs/backend/EARN-COIN-FRONTEND-GAPS.md).
class CoinWalletDashboardScreen extends StatefulWidget {
  const CoinWalletDashboardScreen({super.key});

  @override
  State<CoinWalletDashboardScreen> createState() =>
      _CoinWalletDashboardScreenState();
}

class _CoinWalletDashboardScreenState extends State<CoinWalletDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _controller = getOrPut(() => EarnCoinController());
  late final TabController _tab = TabController(length: 5, vsync: this)
    ..addListener(() => setState(() {}));

  static const _tabs = ['Dashboard', 'Tasks', 'History', 'Rank', 'Streak'];

  @override
  void initState() {
    super.initState();
    _controller.fetchBalance();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent so the app-wide themed background (AppHomeBackground, set
      // in App Background settings) shows through behind the white cards.
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _header(context),
          _pillTabs(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DashboardTab(controller: _controller, tab: _tab),
                _TasksTab(controller: _controller, tab: _tab),
                _HistoryTab(controller: _controller),
                _RankTab(controller: _controller),
                _StreakTab(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topInset + SizeConfig.size20,
        bottom: SizeConfig.size20,
        left: SizeConfig.size12,
        right: SizeConfig.size12,
      ),
      decoration: const BoxDecoration(
        gradient: _headerGrad,
        image: DecorationImage(
          image: AssetImage(AppImageAssets.coinHeaderBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size16, horizontal: SizeConfig.size12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              customBorder: const CircleBorder(),
              child: Container(
                height: SizeConfig.size34,
                width: SizeConfig.size34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 15, color: Colors.white),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  CustomText(
                    'Total Coins Balance',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LocalAssets(
                        imagePath: AppImageAssets.coinIcon,
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Obx(() => CustomText(
                            '${_controller.balance.value?.coins ?? 0}',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size34),
          ],
        ),
      ),
    );
  }

  Widget _pillTabs() {
    return Container(
      // White strip sitting behind the tab pills; the app background shows
      // below it, behind the tab content.
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      child: SizedBox(
        height: SizeConfig.size36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
          itemBuilder: (_, i) {
            final selected = _tab.index == i;
            return GestureDetector(
              onTap: () => _tab.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                decoration: BoxDecoration(
                  color: selected ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: selected ? _blue : const Color(0xFFD9DEE7)),
                ),
                child: CustomText(
                  _tabs[i],
                  fontSize: SizeConfig.medium,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.secondaryTextColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' //
];

String _fmtDate(DateTime? d) =>
    d == null ? '' : '${d.day} ${_months[d.month - 1]}, ${d.year}';

Widget _loader() => const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: _blue),
      ),
    );

Widget _empty(IconData icon, String title, String subtitle) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(icon, color: _blue, size: 28),
            ),
            SizedBox(height: SizeConfig.size12),
            CustomText(title,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center),
            SizedBox(height: SizeConfig.size6),
            CustomText(subtitle,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );

/// White panel used across the tabs.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A101828), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

/// The "🪙 50 Coins | ⭐ 20 XP" bordered chip used by task/history/recent rows.
class _CoinXpChip extends StatelessWidget {
  final int coins;
  final int xp;
  const _CoinXpChip({required this.coins, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
              imagePath: AppImageAssets.coinIcon, height: 16, width: 16),
          SizedBox(width: SizeConfig.size6),
          CustomText('${coins.abs()} Coins',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563)),
          SizedBox(width: SizeConfig.size10),
          Container(width: 1, height: 14, color: AppColors.greyE5),
          SizedBox(width: SizeConfig.size10),
          Icon(Icons.star_rounded, size: 17, color: _gold),
          SizedBox(width: SizeConfig.size4),
          CustomText('$xp XP',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563)),
        ],
      ),
    );
  }
}

Widget _statusPill(String status, {bool debit = false}) {
  final color = debit ? AppColors.redB4 : _green;
  final label = status.isEmpty
      ? (debit ? 'Debited' : 'Credited')
      : (status.capitalizeFirst ?? status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: CustomText(label,
        fontSize: SizeConfig.small, fontWeight: FontWeight.w700, color: color),
  );
}

Widget _dateText(DateTime? d) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 13, color: AppColors.secondaryTextColor),
        SizedBox(width: SizeConfig.size4),
        CustomText(_fmtDate(d),
            fontSize: SizeConfig.small, color: AppColors.secondaryTextColor),
      ],
    );

/// An earning/redemption row (Dashboard "Recent Earning" + History tab).
class _EarnRow extends StatelessWidget {
  final EarnHistoryItem item;
  const _EarnRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.all(SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(item.title,
                    fontSize: SizeConfig.medium15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: SizeConfig.size8),
              _statusPill(item.status, debit: item.isDebit),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          Row(
            children: [
              _CoinXpChip(coins: item.coins, xp: item.xp),
              const Spacer(),
              _dateText(item.createdAt),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _sectionCardHeader(String title, {Widget? trailing}) => Row(
      children: [
        Expanded(
          child: CustomText(title,
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor),
        ),
        if (trailing != null) trailing,
      ],
    );

// ═══════════════════════════════════════════════════════════════════
// Dashboard tab
// ═══════════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  final EarnCoinController controller;
  final TabController tab;
  const _DashboardTab({required this.controller, required this.tab});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final d = widget.controller.dashboard.value;
      if (widget.controller.dashboardLoading.value && d == null) {
        return _loader();
      }
      if (d == null) {
        return _empty(Icons.dashboard_customize_outlined, 'Nothing here yet',
            'Your coin activity will show up here.');
      }
      return RefreshIndicator(
        color: _blue,
        onRefresh: widget.controller.fetchDashboard,
        child: ListView(
          padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
              SizeConfig.size12, SizeConfig.size20),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText('Earn Dashboard',
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor),
                  SizedBox(height: SizeConfig.size14),
                  _statGrid(d),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCardHeader(
                    'Recent Earning',
                    trailing: GestureDetector(
                      onTap: () => widget.tab.animateTo(2),
                      child: CustomText('View All',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: _blue),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  if (d.recent.isEmpty)
                    CustomText(
                      'No earnings yet — open the app daily to start earning coins.',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    )
                  else
                    for (int i = 0; i < d.recent.length; i++) ...[
                      _EarnRow(item: d.recent[i]),
                      if (i != d.recent.length - 1)
                        SizedBox(height: SizeConfig.size10),
                    ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statGrid(EarnDashboard d) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _statCell(Icons.shield_outlined, '${d.balance.coins}',
                        'Coins')),
                Container(width: 1, color: _cardBorder),
                Expanded(
                    child: _statCell(Icons.local_fire_department_outlined,
                        '${d.streak}', 'Streak')),
              ],
            ),
          ),
          Container(height: 1, color: _cardBorder),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _statCell(
                        Icons.star_border_rounded, '${d.balance.xp}', 'XP')),
                Container(width: 1, color: _cardBorder),
                Expanded(
                    child: _statCell(Icons.calendar_today_outlined,
                        '${d.activeDays}', 'Days')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(IconData icon, String value, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: _blue),
          ),
          SizedBox(width: SizeConfig.size10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(value,
                  fontSize: SizeConfig.extraLarge,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor),
              CustomText(label,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tasks tab
// ═══════════════════════════════════════════════════════════════════
class _TasksTab extends StatefulWidget {
  final EarnCoinController controller;
  final TabController tab;
  const _TasksTab({required this.controller, required this.tab});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchTasks();
  }

  /// Picks the illustration for a task from its event/title keywords.
  String _taskImage(EarnTask t) {
    final key = '${t.eventName} ${t.title}'.toUpperCase();
    if (key.contains('PROFILE')) return AppImageAssets.taskProfile;
    return AppImageAssets.taskDocuments;
  }

  /// Navigate by `event_name` — the stable task type — per
  /// docs/backend/FLUTTER-TASK-NAVIGATION.md. Events without a dedicated
  /// in-app route (or that need context this screen doesn't have) fall back to
  /// Home; unknown/new types never crash (guide §6).
  void _onTaskTap(EarnTask t) {
    // A completed, non-repeatable task has nothing left to do.
    if (t.completed && !t.repeatable) return;

    void goHome() =>
        Get.toNamed(RouteHelper.getBottomNavigationBarScreenRoute());

    switch (t.eventName) {
      // ── Universal ──
      case 'PROFILE_COMPLETED':
      case 'BANNER_UPLOADED':
        // No dedicated profile-edit route is exposed; land on Home.
        goHome();
        break;
      case 'KYC_APPROVED':
      case 'ACCOUNT_VERIFIED':
      case 'HOTEL_VERIFIED':
      case 'LAB_VERIFIED':
        Get.toNamed(RouteHelper.getBusinessVerificationScreenRoute());
        break;
      case 'DAILY_LOGIN':
        // In-app: jump to the Streak tab instead of leaving the screen.
        widget.tab.animateTo(4);
        break;
      case 'FIRST_LOGIN':
        // Auto-completes server-side — nothing to open.
        break;

      // ── Business by category ──
      case 'PRODUCT_UPLOADED':
      case 'FIRST_SELL':
      case 'INVENTORY_ADDED':
      case 'FIRST_ORDER':
      case 'ORDER_COMPLETED':
      case 'REVIEW_RECEIVED':
      case 'REFERRAL_SUCCESS':
        // These deep screens need business/owner context not available here.
        goHome();
        break;

      // ── Individual / creator ──
      case 'VIDEO_UPLOADED':
        Get.toNamed(RouteHelper.getVideoReelRecorderScreenRoute(),
            arguments: <String, dynamic>{});
        break;
      case 'POST_CREATED':
        Get.toNamed(RouteHelper.getCreateMessagePostScreenRoute(),
            arguments: <String, dynamic>{});
        break;
      case 'CHANNEL_CREATED':
      case 'CHANNEL_VERIFIED':
      case 'FOLLOWER_MILESTONE':
        Get.toNamed(RouteHelper.getManageChannelScreenRoute());
        break;
      case 'JOB_POSTED':
      case 'JOB_HIRED':
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute());
        break;
      case 'RIDE_COMPLETED':
        goHome();
        break;

      // ── Fallback (unknown/new type) ──
      default:
        goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final c = widget.controller;
      if (c.tasksLoading.value && c.tasks.isEmpty) return _loader();
      if (c.tasks.isEmpty) {
        return _empty(Icons.checklist_rtl_outlined, 'No tasks yet',
            'New tasks to earn coins will appear here.');
      }
      return RefreshIndicator(
        color: _blue,
        onRefresh: c.fetchTasks,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
              SizeConfig.size12, SizeConfig.size20),
          itemCount: c.tasks.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) => _taskCard(c.tasks[i]),
        ),
      );
    });
  }

  Widget _taskCard(EarnTask t) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(t.title,
                        fontSize: SizeConfig.extraLarge,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor),
                    if (t.badge.isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size8),
                      Row(
                        children: [
                          CustomText('Badge: ',
                              fontSize: SizeConfig.medium,
                              color: AppColors.secondaryTextColor),
                          Icon(Icons.verified_rounded, size: 16, color: _green),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(t.badge,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: _green),
                        ],
                      ),
                    ],
                    SizedBox(height: SizeConfig.size12),
                    _CoinXpChip(coins: t.coin, xp: t.xp),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              // Per-task 3D illustration, chosen from the task's event/title.
              LocalAssets(
                imagePath: _taskImage(t),
                height: 76,
                width: 76,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size14),
          Container(height: 1, color: _cardBorder),
          SizedBox(height: SizeConfig.size14),
          Row(
            children: [
              CustomText('Progress',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor),
              const Spacer(),
              CustomText('${t.progress}%',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w800,
                  color: _green),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (t.progress.clamp(0, 100)) / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDF0F4),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          if (!t.completed && t.cta.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size16),
            // Tap → navigate by event_name (see [_onTaskTap]).
            GestureDetector(
              onTap: () => _onTaskTap(t),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(t.cta,
                          fontSize: SizeConfig.medium15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      SizedBox(width: SizeConfig.size8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// History tab
// ═══════════════════════════════════════════════════════════════════
class _HistoryTab extends StatefulWidget {
  final EarnCoinController controller;
  const _HistoryTab({required this.controller});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  String _filter = 'All'; // All | Credited | Debited (client-side)

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchHistory(refresh: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        widget.controller.loadMoreHistory();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in const ['All', 'Credited', 'Debited'])
              ListTile(
                title: CustomText(f,
                    fontSize: SizeConfig.medium15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor),
                trailing: _filter == f
                    ? const Icon(Icons.check_rounded, color: _blue)
                    : null,
                onTap: () {
                  setState(() => _filter = f);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final c = widget.controller;
      if (c.historyLoading.value && c.history.isEmpty) return _loader();

      final all = c.history;
      final list = _filter == 'All'
          ? all
          : all
              .where((e) => _filter == 'Debited' ? e.isDebit : !e.isDebit)
              .toList();

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
                SizeConfig.size12, SizeConfig.size12),
            child: Row(
              children: [
                Expanded(
                  child: CustomText('See All History',
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor),
                ),
                GestureDetector(
                  onTap: _openFilter,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size12,
                        vertical: SizeConfig.size8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD9DEE7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(_filter == 'All' ? 'Filter' : _filter,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor),
                        SizedBox(width: SizeConfig.size6),
                        Icon(Icons.tune_rounded,
                            size: 16, color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? _empty(Icons.receipt_long_outlined, 'No history yet',
                    'Your coin credits and redemptions will appear here.')
                : RefreshIndicator(
                    color: _blue,
                    onRefresh: () => c.fetchHistory(refresh: true),
                    child: ListView.separated(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(SizeConfig.size12, 0,
                          SizeConfig.size12, SizeConfig.size20),
                      itemCount: list.length +
                          (c.historyHasMore.value && _filter == 'All' ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          SizedBox(height: SizeConfig.size10),
                      itemBuilder: (_, i) {
                        if (i >= list.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _blue)),
                            ),
                          );
                        }
                        return _EarnRow(item: list[i]);
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
// Rank tab
// ═══════════════════════════════════════════════════════════════════
class _RankTab extends StatefulWidget {
  final EarnCoinController controller;
  const _RankTab({required this.controller});

  @override
  State<_RankTab> createState() => _RankTabState();
}

class _RankTabState extends State<_RankTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final c = widget.controller;
      final lb = c.leaderboard.value;
      if (c.leaderboardLoading.value && lb == null) return _loader();
      if (lb == null || lb.entries.isEmpty) {
        return _empty(Icons.leaderboard_outlined, 'No ranking yet',
            'Earn coins to climb the leaderboard.');
      }
      return RefreshIndicator(
        color: _blue,
        onRefresh: c.fetchLeaderboard,
        child: ListView(
          padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
              SizeConfig.size12, SizeConfig.size20),
          children: [
            if (lb.me != null) _myRankCard(lb.me!),
            SizedBox(height: SizeConfig.size10),
            _table(lb.entries),
          ],
        ),
      );
    });
  }

  Widget _myRankCard(LeaderboardEntry me) {
    return _Card(
      child: Row(
        children: [
          LocalAssets(
            imagePath: AppImageAssets.earnTrophy,
            height: 96,
            width: 96,
          ),
          SizedBox(width: SizeConfig.size16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText('My Rank',
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor),
                SizedBox(height: SizeConfig.size4),
                CustomText('#${me.rank}',
                    fontSize: 40, fontWeight: FontWeight.w800, color: _blue),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    LocalAssets(
                        imagePath: AppImageAssets.coinIcon,
                        height: 18,
                        width: 18),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('${me.coins} Coins',
                        fontSize: SizeConfig.medium15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  ],
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 18, color: _gold),
                    SizedBox(width: SizeConfig.size6),
                    CustomText('${me.xp} XP',
                        fontSize: SizeConfig.medium15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(List<LeaderboardEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _row(
            rank: 'Rank',
            user: 'User',
            coins: 'Coins',
            xp: 'XP',
            header: true,
          ),
          for (final e in entries) ...[
            Container(height: 1, color: _cardBorder),
            _row(
              rank: '#${e.rank}',
              user: e.isMe ? 'You' : (e.name.isEmpty ? '—' : e.name),
              coins: '${e.coins}',
              xp: '${e.xp}',
              isMe: e.isMe,
              avatar: e.avatar,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row({
    required String rank,
    required String user,
    required String coins,
    required String xp,
    bool header = false,
    bool isMe = false,
    String? avatar,
  }) {
    final weight = header || isMe ? FontWeight.w800 : FontWeight.w500;
    final color = isMe
        ? _blue
        : (header ? AppColors.mainTextColor : AppColors.secondaryTextColor);
    Widget cell(String t, {TextAlign align = TextAlign.center, int flex = 1}) =>
        Expanded(
          flex: flex,
          child: CustomText(t,
              fontSize: SizeConfig.medium,
              fontWeight: weight,
              color: color,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        );

    return Container(
      color: isMe ? _blue.withValues(alpha: 0.08) : Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size14),
      child: Row(
        children: [
          cell(rank),
          Container(width: 1, height: 20, color: _cardBorder),
          Expanded(
            flex: 2,
            child: (header || (avatar == null))
                ? CustomText(user,
                    fontSize: SizeConfig.medium,
                    fontWeight: weight,
                    color: color,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (avatar.isNotEmpty) ...[
                        CachedAvatarWidget(
                            imageUrl: avatar,
                            size: 22,
                            borderColor: Colors.transparent,
                            borderRadius: 11),
                        SizedBox(width: SizeConfig.size6),
                      ],
                      Flexible(
                        child: CustomText(user,
                            fontSize: SizeConfig.medium,
                            fontWeight: weight,
                            color: color,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
          ),
          Container(width: 1, height: 20, color: _cardBorder),
          cell(coins),
          Container(width: 1, height: 20, color: _cardBorder),
          cell(xp),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Streak tab
// ═══════════════════════════════════════════════════════════════════
class _StreakTab extends StatefulWidget {
  final EarnCoinController controller;
  const _StreakTab({required this.controller});

  @override
  State<_StreakTab> createState() => _StreakTabState();
}

class _StreakTabState extends State<_StreakTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchStreak();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final c = widget.controller;
      final s = c.streak.value;
      if (c.streakLoading.value && s == null) return _loader();
      if (s == null) {
        return _empty(Icons.local_fire_department_outlined, 'No streak yet',
            'Open the app daily to build your streak.');
      }
      return RefreshIndicator(
        color: _blue,
        onRefresh: c.fetchStreak,
        child: ListView(
          padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
              SizeConfig.size12, SizeConfig.size20),
          children: [
            _Card(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size24),
              child: SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative ring.
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF7D774), width: 12),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText('Current Streak',
                            fontSize: SizeConfig.medium15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryTextColor),
                        SizedBox(height: SizeConfig.size6),
                        CustomText('${s.streak} ${s.streak == 1 ? 'Day' : 'Days'}',
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: _blue),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          'Keep it up!\nGreat things happen\nwith consistency.',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // Flame sitting on top of the ring.
                    Positioned(
                      top: 0,
                      child: LocalAssets(
                        imagePath: AppImageAssets.earnFlame,
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            _Card(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: Column(
                children: [
                  _infoRow(AppImageAssets.earnFlame, const Color(0xFFF97316),
                      'Longest Streak', 'Your best so far',
                      valueText: '${s.longestStreak} Days'),
                  Container(height: 1, color: _cardBorder),
                  _infoRow(AppImageAssets.earnVerifiedBadge, _green,
                      'Checked In Today', "You're on track",
                      valuePill: s.checkedInToday),
                  Container(height: 1, color: _cardBorder),
                  _infoRow(AppImageAssets.earnCalendar, _blue, 'Last Earned',
                      'When you earned last',
                      valueText: _fmtDate(s.lastEarnedAt)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _infoRow(
      String imagePath, Color tint, String title, String subtitle,
      {String? valueText, bool? valuePill}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LocalAssets(imagePath: imagePath, height: 26, width: 26),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(title,
                    fontSize: SizeConfig.medium15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
                SizedBox(height: 2),
                CustomText(subtitle,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          if (valuePill != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (valuePill ? _green : AppColors.redB4)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(valuePill ? 'Yes' : 'No',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: valuePill ? _green : AppColors.redB4),
            )
          else
            CustomText(valueText ?? '',
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w800,
                color: _blue),
        ],
      ),
    );
  }
}
