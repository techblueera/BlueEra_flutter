import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/model/rider_orders_details_model.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Rapido-inspired daily-driver dashboard for bike-rider users.
///
/// This is a *separate* Me screen from [RiderServiceScreen]; the existing
/// rider/onboarding flow is left unchanged. Use this screen when you want
/// a focused, action-first dashboard for an already-onboarded rider.
class RiderMeScreen extends StatefulWidget {
  final bool fromBottomNavBar;

  const RiderMeScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<RiderMeScreen> createState() => _RiderMeScreenState();
}

enum _OrderStatusFilter { all, upcoming, completed, cancelled }

enum _OrderPeriodFilter { today, week, month, all }

class _RiderMeScreenState extends State<RiderMeScreen>
    with WidgetsBindingObserver, RouteAware {
  final DeliveryPartnerController _riderCtrl =
      getOrPut(() => DeliveryPartnerController());
  final DeliverPartnerOrdersController _ordersCtrl =
      getOrPut(() => DeliverPartnerOrdersController());
  final ViewPersonalDetailsController _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  _OrderStatusFilter _statusFilter = _OrderStatusFilter.all;
  _OrderPeriodFilter _periodFilter = _OrderPeriodFilter.today;

  /// How many orders to render right now. Grows in steps via "Show more" so a
  /// long history renders incrementally instead of building every row at once.
  static const int _orderPageSize = 8;
  int _visibleOrderCount = _orderPageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer to after the first frame so the screen paints immediately (from
    // cache) and the network work never blocks the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer so we can re-check the onboarding/payment
    // status every time this screen becomes visible again (e.g. after the rider
    // returns from RiderServiceScreen where they finish docs / pay the deposit).
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // A screen pushed on top of this one was popped — we're visible again.
    // Re-fetch the onboarding/payment status so the Go-Live gate is current.
    _refreshOnboardingStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background (e.g. after paying in an external flow) —
    // re-check the payment status so the rider isn't left on a stale gate.
    if (state == AppLifecycleState.resumed) {
      _refreshOnboardingStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _bootstrap({bool forceRefresh = false}) async {
    // Each of these reads its local cache and renders instantly, then refreshes
    // in the background — so fire them together instead of awaiting in
    // sequence. A pull-to-refresh passes forceRefresh: true to skip the cache.
    _viewCtrl.UserFollowersAndPostsCount(userId, forceRefresh: forceRefresh);
    _ordersCtrl.getRidersBookingOrders(forceRefresh: forceRefresh);

    await _refreshOnboardingStatus();
  }

  /// Always hits the network for onboarding/payment status so the rider's
  /// current payment + verification state is never served stale from cache.
  /// Payment can be completed on the backend at any time, so this is called on
  /// every screen open, on return to the screen, and on app resume — not just
  /// pull-to-refresh. Awaited because the live-orders stream decision depends
  /// on the verification state it produces.
  Future<void> _refreshOnboardingStatus() async {
    await _riderCtrl.ridersOnboardingStatusRepoApi(forceRefresh: true);
    if (_riderCtrl.riderVerificationState == RiderVerificationState.completed) {
      _ordersCtrl.fetchStream();
    }
  }

  Future<void> _onRefresh() async {
    await _bootstrap(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isRiderRole = userProfessionGlobal == BIKE_RIDER ||
        userProfessionGlobal == CAR_TAXI_DRIVER;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: !isRiderRole
            ? _buildNonRiderState()
            : RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildVerificationBanner(),
                      _buildGoLiveCard(),
                      _buildTodayStats(),
                      _buildQuickActionsGrid(),
                      _buildOrderHistorySection(),
                      SizedBox(height: SizeConfig.size20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final name = (user?.name ?? '').trim();
      final firstName = name.isNotEmpty ? name.split(' ').first : 'Rider';
      final profileImg = user?.profileImage ?? '';
      return Container(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size12,
          SizeConfig.size16,
          SizeConfig.size16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(SizeConfig.size20),
            bottomRight: Radius.circular(SizeConfig.size20),
          ),
        ),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: profileImg,
              size: SizeConfig.size48,
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    _greeting(),
                    fontSize: SizeConfig.small,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    firstName,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _headerIcon(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                if (isGuestUser()) return;
                Navigator.pushNamed(
                  context,
                  RouteHelper.getNotificationScreenRoute(),
                );
              },
            ),
            SizedBox(width: SizeConfig.size8),
            _headerIcon(
              icon: Icons.person_outline_rounded,
              onTap: () {
                Get.to(() => const RiderServiceScreen());
              },
            ),
          ],
        ),
      );
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _headerIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.size20),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: SizeConfig.size18),
      ),
    );
  }

  // ============================================================
  // VERIFICATION BANNER
  // ============================================================

  Widget _buildVerificationBanner() {
    return Obx(() {
      final state = _riderCtrl.riderVerificationState;
      // Profession-aware completion: PAN is not required for bike riders / cab
      // drivers, and vehicle images are always optional.
      final allSteps = _riderCtrl.mandatoryStepsCompleted;
      if (state == RiderVerificationState.completed) {
        return const SizedBox.shrink();
      }
      String title;
      String subtitle;
      Color bgColor;
      Color iconColor;
      IconData icon;
      VoidCallback? onTap;

      if (!allSteps) {
        title = 'Complete your rider profile';
        subtitle = 'Finish all KYC steps to start receiving orders.';
        bgColor = AppColors.primaryColor.withValues(alpha: 0.08);
        iconColor = AppColors.primaryColor;
        icon = Icons.assignment_outlined;
        onTap = () => Get.to(() => const RiderServiceScreen());
      } else if (state == RiderVerificationState.pending) {
        title = AppStrings.verificationPending.tr;
        subtitle = 'Your documents are under review.';
        bgColor = const Color(0xFFFFF4E5);
        iconColor = const Color(0xFFE08600);
        icon = Icons.hourglass_top_rounded;
      } else {
        title = AppStrings.verificationRejected.tr;
        subtitle = 'Please re-upload the requested documents.';
        bgColor = AppColors.redLite.withValues(alpha: 0.15);
        iconColor = AppColors.redLite;
        icon = Icons.error_outline_rounded;
        onTap = () => Get.to(() => const RiderServiceScreen());
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size12,
          SizeConfig.size16,
          0,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(SizeConfig.size12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: SizeConfig.size22),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        subtitle,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: iconColor,
                    size: SizeConfig.size20,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // GO LIVE / DUTY TOGGLE
  // ============================================================

  Widget _buildGoLiveCard() {
    return Obx(() {
      final statusData = serviceProviderStatusGlobal.toUpperCase();
      final isOpenInitial = statusData == AppConstants.OPEN.toUpperCase();
      if (_viewCtrl.shopStatusOpenClose.value != isOpenInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewCtrl.shopStatusOpenClose.value = isOpenInitial;
        });
      }
      final isOnline = _viewCtrl.shopStatusOpenClose.value;
      final isUpdating = _viewCtrl.isShopStatusUpdating.value;

      return Container(
        margin: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size12,
          SizeConfig.size16,
          0,
        ),
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size14),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: SizeConfig.size12,
              height: SizeConfig.size12,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : AppColors.greyE5,
                shape: BoxShape.circle,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    isOnline ? 'You are Online' : 'You are Offline',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    isOnline
                        ? 'Looking for nearby orders…'
                        : 'Go online to start receiving orders',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            if (isUpdating)
              SizedBox(
                width: SizeConfig.size20,
                height: SizeConfig.size20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  // Go Live is allowed only once the rider is verified
                  // (isVerified == approved). Otherwise route them to finish
                  // document upload / verification first.
                  final isVerified = _riderCtrl.riderVerificationState ==
                      RiderVerificationState.completed;
                  if (!isVerified) {
                    commonSnackBar(
                        message:
                            'Please upload your documents and get verified before going live.');
                    Get.to(() => const RiderServiceScreen());
                    return;
                  }
                  // After document verification, the security deposit must be
                  // paid before going online. This gate applies only to bike
                  // riders / cab drivers (the professions that pay a deposit).
                  // ensureSecurityDepositPaid re-fetches the onboarding
                  // status when the snapshot says unpaid, so a freshly paid
                  // deposit is honored instead of re-routing to payment.
                  final isRiderRole = userProfessionGlobal == BIKE_RIDER ||
                      userProfessionGlobal == CAR_TAXI_DRIVER;
                  if (isRiderRole &&
                      !await _riderCtrl.ensureSecurityDepositPaid()) {
                    commonSnackBar(
                        message:
                            'Your payment is incomplete. Please complete the payment process to go live.');
                    Get.to(() => const RiderServiceScreen());
                    return;
                  }
                  _viewCtrl.toggleShopStatus();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: SizeConfig.size48,
                  height: SizeConfig.size26,
                  padding: EdgeInsets.all(SizeConfig.size3),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.primaryColor
                        : Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isOnline
                          ? AppColors.primaryColor
                          : AppColors.greyE5,
                      width: 0.6,
                    ),
                  ),
                  alignment:
                      isOnline ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: SizeConfig.size20,
                    height: SizeConfig.size20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // TODAY STATS
  // ============================================================

  Widget _buildTodayStats() {
    return Obx(() {
      final stats = _computeTodayStats();
      return Container(
        margin: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size16,
          SizeConfig.size16,
          0,
        ),
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size14),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded,
                    size: SizeConfig.size18, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  "Today's Performance",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF12A150),
                    label: 'Earnings',
                    value: '₹${stats.earnings.toStringAsFixed(0)}',
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: _statTile(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.primaryColor,
                    label: 'Rides',
                    value: '${stats.completedCount}',
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: _statTile(
                    icon: Icons.directions_bike_rounded,
                    iconColor: const Color(0xFFE08600),
                    label: 'Distance',
                    value: '${stats.distanceKm.toStringAsFixed(1)} km',
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: _statTile(
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.redLite,
                    label: 'Cancelled',
                    value: '${stats.cancelledCount}',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: SizeConfig.size22),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          value,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: SizeConfig.size40,
      color: AppColors.greyE5,
    );
  }

  _TodayStats _computeTodayStats() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    double earnings = 0;
    int completed = 0;
    double distanceKm = 0;
    int cancelled = 0;

    for (final order in _ordersCtrl.completedOrders) {
      final ts = _parseDate(order.createdAt);
      if (ts == null || ts.isBefore(start)) continue;
      completed++;
      earnings += (order.fare ?? 0).toDouble();
      distanceKm += _km(order.distancePickupToDrop);
    }
    for (final order in _ordersCtrl.cancelledOrders) {
      final ts = _parseDate(order.createdAt);
      if (ts == null || ts.isBefore(start)) continue;
      cancelled++;
    }
    return _TodayStats(
      earnings: earnings,
      completedCount: completed,
      cancelledCount: cancelled,
      distanceKm: distanceKm,
    );
  }

  double _km(String? distance) {
    if (distance == null || distance.isEmpty) return 0;
    final parsed = double.tryParse(distance);
    if (parsed == null) return 0;
    // API often returns metres — convert if value is large.
    return parsed > 1000 ? parsed / 1000.0 : parsed;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActionsGrid() {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.assignment_ind_outlined,
        label: AppStrings.document.tr,
        onTap: () => Get.to(() => const RiderServiceScreen()),
      ),
      _QuickAction(
        icon: Icons.two_wheeler_rounded,
        label: 'Vehicle Info',
        onTap: () => Get.to(() => const RiderServiceScreen()),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: 'My Stores',
        onTap: () => Get.to(() => const RiderServiceScreen()),
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Earnings',
        onTap: _showComingSoon,
      ),
      _QuickAction(
        icon: Icons.headset_mic_outlined,
        label: 'Support',
        onTap: _showComingSoon,
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: AppStrings.statistics.tr,
        onTap: () => Get.to(() => const RiderServiceScreen()),
      ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size16,
        0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size14,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size14),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: SizeConfig.size10,
          crossAxisSpacing: SizeConfig.size6,
          childAspectRatio: 1.05,
          children: actions
              .map((a) => InkWell(
                    onTap: a.onTap,
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            a.icon,
                            color: AppColors.primaryColor,
                            size: SizeConfig.size20,
                          ),
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          a.label,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainTextColor,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showComingSoon() {
    Get.snackbar(
      AppStrings.comingSoon.tr,
      'This feature is coming soon.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ============================================================
  // ORDER HISTORY
  // ============================================================

  Widget _buildOrderHistorySection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size18,
        SizeConfig.size16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                'Order History',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              const Spacer(),
              InkWell(
                onTap: () => Get.to(() => const RiderServiceScreen()),
                child: CustomText(
                  AppStrings.viewAll.tr,
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _statusFilterRow(),
          SizedBox(height: SizeConfig.size8),
          _periodFilterRow(),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            final status = _ordersCtrl.ordersListResponse.value.status;
            final filtered = _filteredOrders();

            if (filtered.isEmpty) {
              // First load with no cached data yet → skeleton, not a spinner.
              if (status == Status.LOADING || status == Status.INITIAL) {
                return _orderHistorySkeleton();
              }
              return _emptyOrders();
            }

            final visible = filtered.length < _visibleOrderCount
                ? filtered.length
                : _visibleOrderCount;
            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: SizeConfig.size10),
                  // RepaintBoundary keeps each row's painting isolated so
                  // scrolling stays smooth as the list grows.
                  itemBuilder: (_, index) => RepaintBoundary(
                    child: _orderHistoryTile(filtered[index]),
                  ),
                ),
                if (filtered.length > visible)
                  Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size12),
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _visibleOrderCount += _orderPageSize),
                      child: CustomText(
                        'Show more',
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _statusFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'All',
            selected: _statusFilter == _OrderStatusFilter.all,
            onTap: () =>
                setState(() => _statusFilter = _OrderStatusFilter.all),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: 'Upcoming',
            selected: _statusFilter == _OrderStatusFilter.upcoming,
            onTap: () =>
                setState(() => _statusFilter = _OrderStatusFilter.upcoming),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: AppStrings.completed.tr,
            selected: _statusFilter == _OrderStatusFilter.completed,
            onTap: () =>
                setState(() => _statusFilter = _OrderStatusFilter.completed),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: 'Cancelled',
            selected: _statusFilter == _OrderStatusFilter.cancelled,
            onTap: () =>
                setState(() => _statusFilter = _OrderStatusFilter.cancelled),
          ),
        ],
      ),
    );
  }

  Widget _periodFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Today',
            selected: _periodFilter == _OrderPeriodFilter.today,
            outlined: true,
            onTap: () =>
                setState(() => _periodFilter = _OrderPeriodFilter.today),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: 'This Week',
            selected: _periodFilter == _OrderPeriodFilter.week,
            outlined: true,
            onTap: () =>
                setState(() => _periodFilter = _OrderPeriodFilter.week),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: 'This Month',
            selected: _periodFilter == _OrderPeriodFilter.month,
            outlined: true,
            onTap: () =>
                setState(() => _periodFilter = _OrderPeriodFilter.month),
          ),
          SizedBox(width: SizeConfig.size6),
          _filterChip(
            label: 'All Time',
            selected: _periodFilter == _OrderPeriodFilter.all,
            outlined: true,
            onTap: () =>
                setState(() => _periodFilter = _OrderPeriodFilter.all),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final fill = outlined
        ? (selected
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : AppColors.white)
        : (selected ? AppColors.primaryColor : AppColors.white);
    final border = selected
        ? AppColors.primaryColor
        : AppColors.greyE5;
    final fg = outlined
        ? (selected ? AppColors.primaryColor : AppColors.secondaryTextColor)
        : (selected ? AppColors.white : AppColors.secondaryTextColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border, width: 0.8),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          color: fg,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  List<RiderOrdersDetailsModel> _filteredOrders() {
    final List<RiderOrdersDetailsModel> source = [];
    switch (_statusFilter) {
      case _OrderStatusFilter.all:
        source
          ..addAll(_ordersCtrl.onGoingOrders)
          ..addAll(_ordersCtrl.completedOrders)
          ..addAll(_ordersCtrl.cancelledOrders);
        break;
      case _OrderStatusFilter.upcoming:
        source.addAll(_ordersCtrl.onGoingOrders);
        break;
      case _OrderStatusFilter.completed:
        source.addAll(_ordersCtrl.completedOrders);
        break;
      case _OrderStatusFilter.cancelled:
        source.addAll(_ordersCtrl.cancelledOrders);
        break;
    }
    final cutoff = _periodCutoff();
    final filtered = cutoff == null
        ? source
        : source.where((o) {
            final ts = _parseDate(o.createdAt);
            return ts != null && !ts.isBefore(cutoff);
          }).toList();
    filtered.sort((a, b) {
      final ad = _parseDate(a.createdAt) ?? DateTime(1970);
      final bd = _parseDate(b.createdAt) ?? DateTime(1970);
      return bd.compareTo(ad);
    });
    // No hard cap here — the UI renders an incremental window
    // (`_visibleOrderCount`) and grows it via "Show more", so even a long
    // history paints cheaply.
    return filtered;
  }

  /// Skeleton placeholder shown on the very first load when there's no cached
  /// orders yet — far less jarring than a full-screen spinner.
  Widget _orderHistorySkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: SizeConfig.size10),
          child: buildLoadingShimmer(
            child: shimmerContainer(height: SizeConfig.size90, radius: 12),
          ),
        ),
      ),
    );
  }

  DateTime? _periodCutoff() {
    final now = DateTime.now();
    switch (_periodFilter) {
      case _OrderPeriodFilter.today:
        return DateTime(now.year, now.month, now.day);
      case _OrderPeriodFilter.week:
        return now.subtract(const Duration(days: 7));
      case _OrderPeriodFilter.month:
        return now.subtract(const Duration(days: 30));
      case _OrderPeriodFilter.all:
        return null;
    }
  }

  Widget _orderHistoryTile(RiderOrdersDetailsModel order) {
    final statusKey = (order.status ?? '').toLowerCase();
    final statusInfo = _statusBadge(statusKey);
    final dt = _parseDate(order.createdAt);
    final dateLabel = dt == null
        ? ''
        : DateFormat('d MMM, hh:mm a').format(dt);
    final pickup = _coordinatesLabel(order.pickupLocation?.location);
    final drop = order.dropLocation?.address ??
        _coordinatesLabel(order.dropLocation?.location);
    final fareLabel = '₹${(order.fare ?? 0).toStringAsFixed(0)}';
    final orderNo = order.orderNo ?? order.orderId ?? '';
    final orderType = (order.orderType ?? '').toUpperCase();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (orderType.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size8,
                    vertical: SizeConfig.size3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    orderType,
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(width: SizeConfig.size6),
              if (orderNo.isNotEmpty)
                Expanded(
                  child: CustomText(
                    '#$orderNo',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size3,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  statusInfo.label,
                  fontSize: SizeConfig.extraSmall,
                  color: statusInfo.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _routeRow(
            color: const Color(0xFF12A150),
            icon: Icons.trip_origin_rounded,
            label: pickup.isNotEmpty ? pickup : 'Pickup location',
          ),
          SizedBox(height: SizeConfig.size4),
          Padding(
            padding: EdgeInsets.only(left: SizeConfig.size8),
            child: Container(
              width: 1,
              height: SizeConfig.size12,
              color: AppColors.greyE5,
            ),
          ),
          SizedBox(height: SizeConfig.size4),
          _routeRow(
            color: AppColors.redLite,
            icon: Icons.location_on_rounded,
            label: drop.isNotEmpty ? drop : 'Drop location',
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: SizeConfig.size14,
                  color: AppColors.secondaryTextColor),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                dateLabel,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
              ),
              const Spacer(),
              CustomText(
                fareLabel,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: SizeConfig.size16),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            label,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _coordinatesLabel(Location? loc) {
    final coords = loc?.coordinates;
    if (coords == null || coords.length < 2) return '';
    return '${coords[1].toStringAsFixed(4)}, ${coords[0].toStringAsFixed(4)}';
  }

  _StatusBadge _statusBadge(String status) {
    switch (status) {
      case 'completed':
        return _StatusBadge('Completed', const Color(0xFF12A150));
      case 'cancelled':
        return _StatusBadge('Cancelled', AppColors.redLite);
      case 'rejected':
        return _StatusBadge('Rejected', AppColors.redLite);
      case 'pending':
        return _StatusBadge('Pending', const Color(0xFFE08600));
      case 'accepted':
      case 'confirmed':
        return _StatusBadge('Accepted', AppColors.primaryColor);
      case 'in-progress':
      case 'picked-up':
        return _StatusBadge('Ongoing', AppColors.primaryColor);
      case 'payment-pending':
        return _StatusBadge('Payment Pending', const Color(0xFFE08600));
      default:
        return _StatusBadge(
          status.isEmpty ? '—' : status,
          AppColors.secondaryTextColor,
        );
    }
  }

  Widget _emptyOrders() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size30,
        horizontal: SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: SizeConfig.size60,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            'No orders found',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            'Try a different filter or check back later.',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NON-RIDER GUARD
  // ============================================================

  Widget _buildNonRiderState() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: Center(
        child: CustomText(
          AppStrings.ridersOnlyMsg.tr,
          textAlign: TextAlign.center,
          fontSize: SizeConfig.medium,
          color: AppColors.secondaryTextColor,
        ),
      ),
    );
  }
}

// ============================================================
// PRIVATE VALUE TYPES
// ============================================================

class _TodayStats {
  final double earnings;
  final int completedCount;
  final int cancelledCount;
  final double distanceKm;

  const _TodayStats({
    required this.earnings,
    required this.completedCount,
    required this.cancelledCount,
    required this.distanceKm,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _StatusBadge {
  final String label;
  final Color color;

  const _StatusBadge(this.label, this.color);
}
