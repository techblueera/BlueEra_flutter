import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_booking_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Booking inbox for both sides of the connect flow:
///  * **My Requests** — orders the buyer has sent (`GET /bookings/me`),
///    cancellable while pending.
///  * **Received** — requests on the caller's listings
///    (`GET /bookings/seller/me`), acceptable/declinable while pending.
///
/// Each tab carries a status-filter chip row and infinite-scroll
/// pagination. [initialTab] selects which side opens first (0 = buyer,
/// 1 = seller).
class VehicleBookingsScreen extends StatefulWidget {
  final int initialTab;

  const VehicleBookingsScreen({super.key, this.initialTab = 0});

  @override
  State<VehicleBookingsScreen> createState() => _VehicleBookingsScreenState();
}

class _VehicleBookingsScreenState extends State<VehicleBookingsScreen>
    with SingleTickerProviderStateMixin {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchMyBookings();
      _ctrl.fetchSellerBookings(showProgress: false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: CommonBackAppBar(title: AppStrings.bookingsTitle.tr),
      body: Column(
        children: [
          Material(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.mainTextColor,
              indicatorColor: AppColors.primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: AppStrings.bookingsTabSent.tr),
                Tab(text: AppStrings.bookingsTabReceived.tr),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingsList(
                  role: VehicleBookingRole.buyer,
                  controller: _ctrl,
                ),
                _BookingsList(
                  role: VehicleBookingRole.seller,
                  controller: _ctrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One side's list — owns its own scroll controller, status filter and
/// pagination wiring, reading from the role-appropriate controller state.
class _BookingsList extends StatefulWidget {
  final VehicleBookingRole role;
  final VehicleController controller;

  const _BookingsList({required this.role, required this.controller});

  @override
  State<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends State<_BookingsList> {
  final ScrollController _scrollCtrl = ScrollController();

  // null = "All". Order shown as filter chips.
  static const List<VehicleBookingStatus?> _filters = [
    null,
    VehicleBookingStatus.pending,
    VehicleBookingStatus.accepted,
    VehicleBookingStatus.declined,
    VehicleBookingStatus.cancelled,
  ];
  VehicleBookingStatus? _selected;

  bool get _isBuyer => widget.role == VehicleBookingRole.buyer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (_isBuyer) {
        widget.controller.loadMoreMyBookings();
      } else {
        widget.controller.loadMoreSellerBookings();
      }
    }
  }

  Future<void> _refresh() => _isBuyer
      ? widget.controller.fetchMyBookings(status: _selected?.wire)
      : widget.controller.fetchSellerBookings(status: _selected?.wire);

  void _onFilterTap(VehicleBookingStatus? status) {
    if (status == _selected) return;
    setState(() => _selected = status);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Obx(() {
              final state = _isBuyer
                  ? widget.controller.myBookingsState.value
                  : widget.controller.sellerBookingsState.value;
              final items = _isBuyer
                  ? widget.controller.myBookings
                  : widget.controller.sellerBookings;
              final hasMore = _isBuyer
                  ? widget.controller.myBookingsHasMore.value
                  : widget.controller.sellerBookingsHasMore.value;

              if (state.status == Status.LOADING && items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == Status.ERROR && items.isEmpty) {
                return _MessageView(
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.redB4,
                  message: state.message ?? AppStrings.somethingWentWrong.tr,
                  onRetry: _refresh,
                );
              }
              if (items.isEmpty) {
                return _MessageView(
                  icon: Icons.inbox_outlined,
                  iconColor: AppColors.primaryColor,
                  message: _isBuyer
                      ? AppStrings.bookingsEmptySent.tr
                      : AppStrings.bookingsEmptyReceived.tr,
                  onRetry: _refresh,
                );
              }
              return ListView.separated(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(SizeConfig.size12,
                    SizeConfig.size12, SizeConfig.size12, SizeConfig.size16),
                itemCount: items.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, __) =>
                    SizedBox(height: SizeConfig.size12),
                itemBuilder: (_, i) {
                  if (i >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final b = items[i];
                  return Obx(() {
                    final inFlight =
                        widget.controller.bookingActionInFlightId.value == b.id;
                    return VehicleBookingCard(
                      booking: b,
                      role: widget.role,
                      isActionInFlight: inFlight,
                      onCancel: () => _confirmCancel(b),
                      onAccept: () => widget.controller
                          .respondToBooking(id: b.id, accept: true),
                      onDecline: () => _confirmDecline(b),
                    );
                  });
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(VehicleBooking b) async {
    final ok = await _confirm(
      title: AppStrings.bookingCancelRequest.tr,
      body: AppStrings.bookingCancelConfirm.tr,
      confirmLabel: AppStrings.bookingCancelRequest.tr,
    );
    if (ok) await widget.controller.cancelBooking(b.id);
  }

  Future<void> _confirmDecline(VehicleBooking b) async {
    final ok = await _confirm(
      title: AppStrings.bookingDecline.tr,
      body: AppStrings.bookingDeclineConfirm.tr,
      confirmLabel: AppStrings.bookingDecline.tr,
    );
    if (ok) {
      await widget.controller.respondToBooking(id: b.id, accept: false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(title,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
        content: CustomText(body,
            fontSize: SizeConfig.medium, color: AppColors.secondaryTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.no.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel,
                style: TextStyle(color: AppColors.redB4)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Widget _filterBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Row(
          children: [
            for (final f in _filters) ...[
              _filterChip(f),
              SizedBox(width: SizeConfig.size8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(VehicleBookingStatus? status) {
    final selected = status == _selected;
    final label = status == null ? AppStrings.all.tr : status.label;
    return GestureDetector(
      onTap: () => _onFilterTap(status),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : AppColors.fillColor,
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.secondaryTextColor,
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final Future<void> Function() onRetry;

  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Icon(icon, size: 64, color: iconColor.withValues(alpha: 0.5)),
        SizedBox(height: SizeConfig.size12),
        CustomText(
          message,
          textAlign: TextAlign.center,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(AppStrings.retry.tr),
          ),
        ),
      ],
    );
  }
}
