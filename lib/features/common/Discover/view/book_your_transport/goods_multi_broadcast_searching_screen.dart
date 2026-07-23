import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/goods_multi_call_tracking_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Finding a rider" screen for a multi-shop **broadcast** order.
///
/// Broadcast is the Rapido-style race: no rider was picked, the server rings
/// nearby riders in expanding waves and the first to accept wins. There is no
/// per-rider call here — the customer just waits.
///
/// Owns no polling of its own: [DiscoverController.makeMultiShopBroadcastOrder]
/// already started the status poll and the `ride:broadcast:*` listeners. This
/// screen only reacts — a winner replaces it with
/// [GoodsMultiCallTrackingScreen], an exhausted race pops it.
class GoodsMultiBroadcastSearchingScreen extends StatefulWidget {
  const GoodsMultiBroadcastSearchingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<GoodsMultiBroadcastSearchingScreen> createState() =>
      _GoodsMultiBroadcastSearchingScreenState();
}

class _GoodsMultiBroadcastSearchingScreenState
    extends State<GoodsMultiBroadcastSearchingScreen>
    with SingleTickerProviderStateMixin {
  final discoverController = getOrPut(() => DiscoverController());

  late final AnimationController _pulseController;
  late final Worker _acceptedWorker;
  late final Worker _exhaustedWorker;

  /// Guards the one-way exit: the poll and the socket can both report the
  /// winner within the same frame, and `Get.off` doesn't dispose this state
  /// synchronously — without this the second one pushes a duplicate screen.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _acceptedWorker =
        ever(discoverController.fareCallAcceptedRiderInfo, (riderInfo) {
      if (riderInfo != null) _onRiderWon();
    });
    _exhaustedWorker =
        ever(discoverController.isMultiShopBroadcastExhausted, (exhausted) {
      if (exhausted == true) _onNoRiders();
    });

    // A rider may have won between order creation and this screen mounting.
    if (discoverController.fareCallAcceptedRiderInfo.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onRiderWon());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _acceptedWorker.dispose();
    _exhaustedWorker.dispose();
    super.dispose();
  }

  void _onRiderWon() {
    if (!mounted || _navigated) return;
    _navigated = true;
    // `off` — once a rider has the order there is nothing to come back to here.
    Get.off(() => GoodsMultiCallTrackingScreen(orderId: widget.orderId));
  }

  void _onNoRiders() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Get.back();
    commonSnackBar(message: 'No riders available. Please try again.');
  }

  /// Backing out of a live search must cancel the order, not orphan it — the
  /// waves keep ringing riders server-side otherwise.
  Future<void> _confirmCancel() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: CustomText('Cancel request?',
            fontSize: SizeConfig.size16, fontWeight: FontWeight.w600),
        content: CustomText(
          'We are still looking for a rider for your order.',
          fontSize: SizeConfig.size13,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: CustomText('Keep searching',
                fontSize: SizeConfig.size13, color: AppColors.primaryColor),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: CustomText('Cancel request',
                fontSize: SizeConfig.size13, color: AppColors.red00),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final cancelled = await discoverController.cancelMultiShopBroadcast(
        reason: 'customer_cancelled');
    if (cancelled && mounted && !_navigated) {
      _navigated = true;
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: CustomBtn(
              height: 44,
              isValidate: true,
              bgColor: AppColors.white,
              borderColor: AppColors.red00,
              textColor: AppColors.red00,
              onTap: _confirmCancel,
              title: 'Cancel request',
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pulse(),
                SizedBox(height: SizeConfig.size24),
                CustomText(
                  'Finding a rider for you',
                  fontSize: SizeConfig.size18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                Obx(() => CustomText(
                      _waveText(),
                      textAlign: TextAlign.center,
                      fontSize: SizeConfig.size13,
                      color: AppColors.secondaryTextColor,
                    )),
                SizedBox(height: SizeConfig.size24),
                _routeSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wave progress, as much of it as the server has told us. Before the first
  /// `ride:broadcast:searching` lands there is no wave to report, so this stays
  /// generic rather than claiming "wave 0".
  String _waveText() {
    final wave = discoverController.multiShopBroadcastWave.value;
    final total = discoverController.multiShopBroadcastTotalWaves.value;
    final radius = discoverController.multiShopBroadcastRadiusKm.value;
    final notified = discoverController.multiShopBroadcastRidersNotified.value;

    if (wave <= 0) {
      return 'Nearby riders are being notified.\nThe first one to accept gets your order.';
    }
    final parts = <String>[
      total > 0 ? 'Wave $wave of $total' : 'Wave $wave',
      if (radius > 0) 'within ${radius.toStringAsFixed(radius % 1 == 0 ? 0 : 1)} km',
      if (notified > 0) '$notified rider${notified == 1 ? '' : 's'} notified',
    ];
    return '${parts.join(' • ')}\nThe first one to accept gets your order.';
  }

  Widget _pulse() {
    return SizedBox(
      height: 140,
      width: 140,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final t = _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Two rings, half a cycle apart, so the expansion reads as
              // continuous waves rather than a single blink.
              _ring(t),
              _ring((t + 0.5) % 1.0),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler,
                    color: Colors.white, size: 28),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t) {
    return Container(
      height: 56 + (84 * t),
      width: 56 + (84 * t),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withValues(alpha: 0.18 * (1 - t)),
      ),
    );
  }

  Widget _routeSummary() {
    return Obx(() {
      final shops = discoverController.multiShopSortedShops;
      final routeKm = discoverController.multiShopRouteDistanceKm.value;
      if (shops.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppShadows.bottomShadow],
          color: AppColors.white,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route,
                    size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomText(
                    '${shops.length} pickup${shops.length == 1 ? '' : 's'} • 1 drop',
                    fontSize: SizeConfig.size13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                if (routeKm > 0)
                  CustomText(
                    '${routeKm.toStringAsFixed(1)} km',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...shops.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        s.name.isNotEmpty ? s.name : s.address,
                        fontSize: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
