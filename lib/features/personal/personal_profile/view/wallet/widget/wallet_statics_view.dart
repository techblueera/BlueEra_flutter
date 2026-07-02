import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_history_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/stat_donut_chart.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/controller/earn_coin_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/view/coin_wallet_dashboard_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/joining_bounce_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/model/joining_bounce_progress.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Statics section of the wallet screen — the scrollable body shown beneath the
/// blue balance header. Replaces the old two-tab (Statics / Transactions)
/// switcher: transactions now live behind the header "History" button, and this
/// view stacks the redesigned Joining Bonus card + the income donut cards.
///
/// Self-contained on purpose — it does NOT reuse `StaticsTab` (still used by the
/// referral dashboard); the wallet redesign owns its own card widgets.
class WalletStaticsView extends StatefulWidget {
  final ReferralController controller;
  const WalletStaticsView({super.key, required this.controller});

  @override
  State<WalletStaticsView> createState() => _WalletStaticsViewState();
}

class _WalletStaticsViewState extends State<WalletStaticsView> {
  // ─── Palette used across the legend dots / donut segments ─────────
  static const _grey = Color(0xFFB6BBC4);
  static const _green = Color(0xFF34C77B);
  static const _yellow = Color(0xFFFFC93C);
  static const _red = Color(0xFFEF4444);
  static const _purple = Color(0xFF7B61FF);

  ReferralController get controller => widget.controller;

  /// Drives the Joining Bonus card from the Joining Bounce flow —
  /// see docs/backend/JOINING_BOUNCE_FLUTTER_INTEGRATION.md.
  final _joiningBounceController = getOrPut(() => JoiningBounceController());

  /// Coin balance for the Coin Wallet card — GET /earn/balance.
  final _earnController = getOrPut(() => EarnCoinController());

  /// Joining Bonus checklist expand/collapse — "See More" / "Show Less".
  bool _bonusExpanded = false;

  @override
  void initState() {
    super.initState();
    controller.fetchDirectReferralIncome();
    // Active joining bonus (progress + bonus amount) for the Joining Bonus card.
    // tag_id = the user's business category; account_type = BUSINESS so the
    // backend auto-creates / resolves the right plan on first visit.
    _joiningBounceController.getCurrentApi(
      tagId: businessCategoryGlobal,
      accountType: 'BUSINESS',
    );
    // Coin balance is fetched once by WalletScreen (the parent) — this view
    // shares the same singleton and just reads it, so no fetch here.
  }

  // ── Money / count formatting ────────────────────────────────────────────
  String _money(num? v) {
    final n = v ?? 0;
    final body = n == n.truncateToDouble()
        ? _withCommas(n.toInt())
        : n.toStringAsFixed(2);
    return '₹$body';
  }

  String _count(num? v) {
    final n = v ?? 0;
    return n == n.truncateToDouble() ? _withCommas(n.toInt()) : n.toString();
  }

  String _withCommas(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _joiningBonusCard(),
          _directReferralCard(),
          _orderIncomeCard(),
          _coinWalletCard(),
        ],
      ),
    );
  }

  // ─── Joining Bonus ────────────────────────────────────────────────
  // Driven by the Joining Bounce flow (GET /joining-bounce/current). The
  // progress object's `requirements` block carries each metric as
  // current/required and a named-milestone tracker — see
  // docs/backend/JOINING_BOUNCE_FLUTTER_INTEGRATION.md §1.
  Widget _joiningBonusCard() {
    return Obx(() {
      final jb = _joiningBounceController.currentBounce.value;
      // No active bonus (404 / credited / cancelled) → omit the card entirely.
      if (jb == null || jb.isCancelled || jb.isExpired) {
        return const SizedBox.shrink();
      }

      final items = _checklistItems(jb);
      // "X of Y Completed" comes from the backend counts (Y = all 9 metrics),
      // not just the milestone rows shown in the checklist.
      final completed = jb.completedCount;
      final total = jb.totalCount;
      final percent = jb.progressPercent.clamp(0, 100);

      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.paddingXSL),
        child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reward header: bag + amount + status pill ──────────
              Row(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.moneyBagIcon,
                    height: 34,
                    width: 34,
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Your Reward',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            CustomText(
                              _money(jb.bonusInr),
                              fontSize: SizeConfig.extraLarge,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mainTextColor,
                            ),
                            SizedBox(width: SizeConfig.size6),
                            CustomText(
                              'Bonus',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _statusPill(jb),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              const _DashedDivider(),
              SizedBox(height: SizeConfig.size12),
              // ── Progress row ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Progress',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: 2),
                      CustomText(
                        '$completed of $total Completed',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(child: _progressBar(percent / 100)),
                  SizedBox(width: SizeConfig.size10),
                  CustomText(
                    '$percent%',
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ],
              ),
              // ── Claim CTA — only when eligible (per the guide) ─────
              if (jb.isEligible && !jb.isCredited) ...[
                SizedBox(height: SizeConfig.size12),
                _claimButton(jb),
              ],
              // ── Task checklist + task-completion donut (expandable) ─
              if (_bonusExpanded) ...[
                SizedBox(height: SizeConfig.size12),
                const _DashedDivider(),
                SizedBox(height: SizeConfig.size12),
                _checklist(items),
                SizedBox(height: SizeConfig.size12),
                _taskDonutCard(jb),
              ],
              SizedBox(height: SizeConfig.size8),
              Center(
                child: InkWell(
                  onTap: () => setState(() => _bonusExpanded = !_bonusExpanded),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
                    child: CustomText(
                      _bonusExpanded ? 'Show Less' : 'See More',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.skyBlueDF,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Task checklist rows — one per milestone (Profile Update, Inventory, Store
  /// Open, Ready Order, Completed Order) from `requirements.milestones.items`,
  /// which carries a friendly label + current/target + met per milestone.
  /// Falls back to the legacy key lists if the richer `items` aren't present.
  List<_CheckItem> _checklistItems(JoiningBounceProgress jb) {
    final ms = jb.requirements?.milestones;
    if (ms == null) return const [];
    if (ms.items.isNotEmpty) {
      return ms.items
          .map((m) => _CheckItem(
                label: m.label.isNotEmpty ? m.label : _milestoneLabel(m.key),
                met: m.met,
                current: m.current,
                target: m.target,
              ))
          .toList();
    }
    // Legacy fallback (older API without `items`).
    return ms.required
        .map((key) => _CheckItem(
              label: _milestoneLabel(key),
              met: ms.completed.contains(key),
              current: ms.completed.contains(key) ? 1 : 0,
              target: 1,
            ))
        .toList();
  }

  /// Friendly label for a backend milestone key (e.g. `inventory_added` →
  /// "Inventory"). Falls back to a Title-Cased version of the raw key.
  String _milestoneLabel(String key) {
    const map = {
      'business_profile_verified': 'Profile',
      'profile_verified': 'Profile',
      'profile_completed': 'Profile',
      'kyc_approved': 'KYC',
      'inventory_added': 'Inventory',
      'first_inventory_added': 'Inventory',
      'store_open': 'Store Open',
      'store_opened': 'Store Open',
      'order_ready': 'Ready Order',
      'ready_order': 'Ready Order',
      'order_completed': 'Completed Order',
      'first_order_completed': 'Completed Order',
      'channel_created': 'Channel',
      'product_published': 'Product',
    };
    final k = key.toLowerCase();
    if (map.containsKey(k)) return map[k]!;
    return key
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _statusPill(JoiningBounceProgress jb) {
    final Color color = jb.isCredited
        ? _green
        : jb.isEligible
            ? _green
            : _yellow;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: CustomText(
        jb.statusLabel,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _progressBar(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 8,
        color: AppColors.greyE5,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: f,
            child: Container(
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bordered table of checklist rows (divider between each).
  Widget _checklist(List<_CheckItem> items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) Container(height: 1, color: AppColors.greyE5),
            _checkRow(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _checkRow(_CheckItem item) {
    // "4/10 (Pending)" — the count in the main text colour, the status suffix
    // tinted green (Completed) / amber (Pending) like the design.
    final statusColor = item.met ? _green : _yellow;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          Icon(
            item.met ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: item.met ? _green : _grey,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              item.label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CustomText(
            '${_count(item.current)}/${_count(item.target)} ',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          CustomText(
            item.met ? '(Completed)' : '(Pending)',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  /// Task-completion donut card shown under the checklist — Go Live Count,
  /// Live Hour and Assign Task metrics with a "% Task Complete" centre.
  Widget _taskDonutCard(JoiningBounceProgress jb) {
    final r = jb.requirements;
    final days = r?.days;
    final hours = r?.hours;
    final tasks = r?.tasks;
    final pct = _taskCompletePercent([days, hours, tasks]);
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: _ChartRow(
        donut: StatDonutChart(
          size: 116,
          strokeWidth: 10,
          segments: [
            DonutSegment(color: _green, value: days?.current ?? 0),
            DonutSegment(color: _purple, value: hours?.current ?? 0),
            DonutSegment(color: _yellow, value: tasks?.current ?? 0),
          ],
          center: _CenterText(value: '$pct%', label: 'Task Complete'),
        ),
        rows: [
          _LegendRow(
            color: _green,
            label: days?.label ?? 'Go Live Count (Days)',
            value: _metricValue(days),
          ),
          _LegendRow(
            color: _purple,
            label: hours?.label ?? 'Live Hour',
            value: _metricValue(hours),
          ),
          _LegendRow(
            color: _yellow,
            label: tasks?.label ?? 'Assign Task',
            value: _metricValue(tasks),
          ),
        ],
      ),
    );
  }

  /// "current/required unit" for a requirement metric (e.g. "20/100 Days").
  String _metricValue(JoiningBounceRequirement? r) {
    if (r == null) return '-';
    final unit = (r.unit ?? '').trim();
    final base = '${_count(r.current)}/${_count(r.required)}';
    return unit.isEmpty ? base : '$base $unit';
  }

  /// Average completion (0–100) across the supplied metrics — the donut centre.
  int _taskCompletePercent(List<JoiningBounceRequirement?> metrics) {
    final fracs = <double>[];
    for (final m in metrics) {
      if (m == null || m.required <= 0) continue;
      fracs.add((m.current / m.required).clamp(0.0, 1.0).toDouble());
    }
    if (fracs.isEmpty) return 0;
    final avg = fracs.reduce((a, b) => a + b) / fracs.length;
    return (avg * 100).round();
  }

  Widget _claimButton(JoiningBounceProgress jb) {
    return Obx(() {
      final claiming = _joiningBounceController.isClaiming.value;
      return InkWell(
        onTap: claiming ? null : () => _onClaim(jb),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: SizeConfig.size45,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: claiming
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : CustomText(
                  'Claim Bonus',
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
        ),
      );
    });
  }

  Future<void> _onClaim(JoiningBounceProgress jb) async {
    final ok = await _joiningBounceController.claimBounce(jb);
    if (!ok) return;
    // Refresh the bonus (becomes credited → card hides) and the wallet balance.
    await _joiningBounceController.getCurrentApi(
      tagId: businessCategoryGlobal,
      accountType: 'BUSINESS',
    );
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().getWalletApi();
    }
  }

  // ─── Direct Referral Income ───────────────────────────────────────
  Widget _directReferralCard() {
    return Obx(() {
      final dr = controller.walletStatics.value?.directReferralIncome;
      final bk = dr?.breakdown;
      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.paddingXSL),
        child: _StatsCard(
          title: 'Direct Referral Income',
          onViewDetails: () => Get.to(() => const ReferralHistoryScreenNew()),
          body: _ChartRow(
            donut: StatDonutChart(
              segments: [
                DonutSegment(color: _green, value: bk?.subscribed ?? 0),
                DonutSegment(color: _grey, value: bk?.pending ?? 0),
                DonutSegment(color: _yellow, value: bk?.unsubscribed ?? 0),
                DonutSegment(color: _red, value: bk?.expired ?? 0),
              ],
              center: _CenterText(
                value: _count(dr?.referralCount),
                label: 'Referral Count',
              ),
            ),
            rows: [
              _LegendRow(
                  color: _green,
                  label: 'Subscribe',
                  value: _count(bk?.subscribed)),
              _LegendRow(
                  color: _grey,
                  label: 'Pending',
                  value: _count(bk?.pending)),
              _LegendRow(
                  color: _yellow,
                  label: 'Un-Subscribe',
                  value: _count(bk?.unsubscribed)),
              _LegendRow(
                  color: _red, label: 'Expired', value: _count(bk?.expired)),
            ],
          ),
        ),
      );
    });
  }

  // ─── Order Income ─────────────────────────────────────────────────
  Widget _orderIncomeCard() {
    return Obx(() {
      final oi = controller.walletStatics.value?.orderIncome;
      final bk = oi?.breakdown;
      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.paddingXSL),
        child: _StatsCard(
          title: 'Order Income',
          onViewDetails: () {},
          body: _ChartRow(
            donut: StatDonutChart(
              segments: [
                DonutSegment(color: _grey, value: bk?.myOrder ?? 0),
                DonutSegment(color: _green, value: bk?.referralOrder ?? 0),
                DonutSegment(color: _yellow, value: bk?.bonus ?? 0),
              ],
              center: _CenterText(
                value: _money(oi?.totalAmount),
                label: 'Total Amount',
              ),
            ),
            rows: [
              _LegendRow(
                  color: _grey, label: 'My Order', value: _money(bk?.myOrder)),
              _LegendRow(
                  color: _green,
                  label: 'Referral Order',
                  value: _money(bk?.referralOrder)),
              _LegendRow(
                  color: _yellow, label: 'Bonus', value: _money(bk?.bonus)),
            ],
          ),
        ),
      );
    });
  }

  // ─── Coin Wallet ──────────────────────────────────────────────────
  // Donut of Current / Lifetime / Redeemed coins + XP with a "Total Amount"
  // (₹ equivalent) centre. Bound to GET /earn/balance; "View Details" opens
  // the 5-tab earn screen. See docs/backend/FLUTTER-MASTER-GUIDE.md.
  Widget _coinWalletCard() {
    return Obx(() {
      final b = _earnController.balance.value;
      final num currentCoins = b?.coins ?? 0;
      final num lifetimeCoins = b?.lifetimeCoins ?? 0;
      final num redeemedCoins = b?.redeemedCoins ?? 0;
      final num xp = b?.xp ?? 0;
      final num totalAmount = b?.rupeeEquivalent ?? 0;

      return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row: "Coin Wallet" + "View Details".
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      'Coin Wallet',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.to(() => const CoinWalletDashboardScreen()),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: CustomText(
                        'View Details',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.skyBlueDF,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.greyE5),
            Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size14, SizeConfig.size12,
                  SizeConfig.size14, SizeConfig.size14),
              child: _ChartRow(
                donut: StatDonutChart(
                  segments: [
                    DonutSegment(color: _green, value: currentCoins),
                    DonutSegment(color: _purple, value: lifetimeCoins),
                    DonutSegment(color: _yellow, value: xp),
                    DonutSegment(color: _red, value: redeemedCoins),
                  ],
                  center: _CenterText(
                    value: _money(totalAmount),
                    label: 'Total Amount',
                  ),
                ),
                rows: [
                  _LegendRow(
                      color: _green,
                      label: 'Current Coins',
                      value: _count(currentCoins)),
                  _LegendRow(
                      color: _purple,
                      label: 'Lifetime Coins',
                      value: _count(lifetimeCoins)),
                  _LegendRow(
                      color: _red,
                      label: 'Redeemed Coins',
                      value: _count(redeemedCoins)),
                  _LegendRow(color: _yellow, label: 'XP', value: _count(xp)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// One Joining-Bonus checklist entry.
class _CheckItem {
  final String label;
  final bool met;
  final num current;
  final num target;
  const _CheckItem({
    required this.label,
    required this.met,
    required this.current,
    required this.target,
  });
}

// ─────────────────────────────────────────────────────────────────────
// Shared sub-widgets (income donut cards)
// ─────────────────────────────────────────────────────────────────────

/// White card shell: title row at top, body + footer below, separated by a
/// hairline divider.
class _StatsCard extends StatelessWidget {
  final String title;
  final VoidCallback onViewDetails;
  final Widget body;
  const _StatsCard({
    required this.title,
    required this.onViewDetails,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size10, SizeConfig.size10,
                SizeConfig.size10, SizeConfig.size10),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onViewDetails,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: CustomText(
                      'View Details',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.skyBlueDF,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.greyE5),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size14, SizeConfig.size12,
                SizeConfig.size14, SizeConfig.size14),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// Donut on the left, vertical legend on the right.
class _ChartRow extends StatelessWidget {
  final Widget donut;
  final List<_LegendRow> rows;
  const _ChartRow({required this.donut, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One legend row — coloured dot, label on the left, value on the right.
class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            label,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }
}

/// Big value + small caption inside the donut.
class _CenterText extends StatelessWidget {
  final String value;
  final String label;
  const _CenterText({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 2),
        CustomText(
          label,
          fontSize: 10,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

/// Horizontal dashed line spanning the full available width.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  static const _color = Color(0xFFCFD4DA);
  static const _thickness = 1.0;
  static const _dashWidth = 4.0;
  static const _dashSpace = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount =
            (boxWidth / (_dashWidth + _dashSpace)).floor().clamp(0, 10000);
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: _dashWidth,
              height: _thickness,
              child: DecoratedBox(decoration: BoxDecoration(color: _color)),
            ),
          ),
        );
      },
    );
  }
}
