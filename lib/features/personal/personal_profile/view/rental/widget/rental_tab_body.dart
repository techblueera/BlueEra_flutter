import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/rental_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_card.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Self-contained "Rental Services" tab body. Drops into any tabbed
/// dashboard (self-employee, professionals, rider, cab partner,
/// social main) by being added as a tab child — each screen only
/// needs to import this widget; the rental controller / model /
/// RentalCard / picker / delete dialog all live here.
///
/// Visual structure:
///   • Header strip — type filter chips (homestay / flat-room /
///     vehicle) + circular "+" CTA satellite that opens the
///     create-rental picker.
///   • Body — three states:
///       – loading skeleton grid (4 cards pulse out of phase)
///       – featured medallion empty state with primary CTA
///       – 2-col masonry of RentalCard widgets, with a section
///         eyebrow that echoes the active filter chip.
///
/// State is driven by [RentalController]. Because we register it
/// with `getOrPut`, every surface that touches rentals — this tab
/// body wherever it's mounted, plus [RentalServiceScreen] — shares
/// the same instance, so add/edit/delete/filter mirror across
/// surfaces for free.
class RentalTabBody extends StatefulWidget {
  const RentalTabBody({super.key});

  @override
  State<RentalTabBody> createState() => _RentalTabBodyState();
}

class _RentalTabBodyState extends State<RentalTabBody> {
  final _rentalCtrl = getOrPut(() => RentalController());

  @override
  void initState() {
    super.initState();
    // Hydrate up-front so the body has data ready when the tab
    // first renders. forceRefresh: true matches what
    // RentalServiceScreen does on its own initState.
    _rentalCtrl.callApi(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: _buildRentalHeaderStrip(),
        ),
        SizedBox(height: SizeConfig.size16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: _rentalServicesList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HEADER STRIP
  // ─────────────────────────────────────────────

  // Single composed control — type-filter chips on the left
  // (horizontal scroll so labels never get cropped on narrow
  // screens), animated active state, and a circular "+" satellite
  // on the right that opens the create-rental picker. Wrapped in a
  // soft-bordered white container so the strip reads as one
  // element rather than two stacked widgets.
  Widget _buildRentalHeaderStrip() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final selected = _rentalCtrl.selectedRentalTabs.value;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _typeChip(
                      icon: Icons.house_outlined,
                      label: AppStrings.homeStay,
                      selected: selected == RentalServiceType.homeStay,
                      onTap: () =>
                          _selectRentalType(RentalServiceType.homeStay),
                    ),
                    const SizedBox(width: 6),
                    _typeChip(
                      icon: Icons.apartment_outlined,
                      label: AppStrings.flatRoom,
                      selected: selected == RentalServiceType.flatRoom,
                      onTap: () =>
                          _selectRentalType(RentalServiceType.flatRoom),
                    ),
                    const SizedBox(width: 6),
                    _typeChip(
                      icon: Icons.directions_car_outlined,
                      label: AppStrings.vehicle,
                      selected: selected == RentalServiceType.vehicle,
                      onTap: () =>
                          _selectRentalType(RentalServiceType.vehicle),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // "+" CTA — circular gradient satellite. Tooltip surfaces
          // the action's intent for screen readers + long-press
          // since the icon is unlabeled.
          Tooltip(
            message: 'Add Rental Service',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showAddRentalSheet,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.82),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pill chip used in the rental-type filter strip. Active state
  // fills with primary + soft primary shadow; inactive state wears
  // a lighter primary tint so the row reads as a unified segmented
  // control rather than three independent buttons.
  Widget _typeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor
                          .withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color:
                    selected ? Colors.white : AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              CustomText(
                label,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color:
                    selected ? Colors.white : AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Equality-guards before mutating selectedRentalTabs and
  // refreshing — so a tap on the already-active chip doesn't fire
  // a redundant API call.
  void _selectRentalType(RentalServiceType type) {
    if (_rentalCtrl.selectedRentalTabs.value == type) return;
    _rentalCtrl.selectedRentalTabs.value = type;
    _rentalCtrl.callApi();
  }

  // ─────────────────────────────────────────────
  // ADD-RENTAL PICKER
  // ─────────────────────────────────────────────

  // Bottom-sheet picker — three rows for the three
  // RentalServiceType variants, each routes to its create screen.
  // Awaits the route so we can refresh the controller's lists on
  // return; if the user backs out without saving the API call is
  // harmless idempotency.
  Future<void> _showAddRentalSheet() async {
    Future<void> openCreate(String routeName) async {
      Navigator.of(context).pop(); // dismiss the sheet
      await Get.toNamed(routeName);
      _rentalCtrl.callApi(forceRefresh: true);
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        Widget option({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CustomText(label,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.greyCA),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16),
                  child: CustomText(
                    'Add Rental Service',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size8),
                option(
                  icon: Icons.house_outlined,
                  label: AppStrings.homeStay,
                  onTap: () => openCreate(
                      RouteHelper.getHomeStayRentalServiceRoute()),
                ),
                option(
                  icon: Icons.apartment_outlined,
                  label: AppStrings.flatRoom,
                  onTap: () => openCreate(RouteHelper
                      .getAddFlatRoomRentalServiceScreenRoute()),
                ),
                option(
                  icon: Icons.directions_car_outlined,
                  label: AppStrings.vehicle,
                  onTap: () => openCreate(
                      RouteHelper.getVehicleRentalServiceRoute()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // BODY DISPATCHER
  // ─────────────────────────────────────────────

  // Body — dispatches to one of three states based on the selected
  // type's loading/data signal. shrinkWrap +
  // NeverScrollableScrollPhysics inside the grid because the host
  // dashboard's outer scrollable already owns the scroll axis.
  Widget _rentalServicesList() {
    return Obx(() {
      final selectedType = _rentalCtrl.selectedRentalTabs.value;
      final List<RentalServiceData> rentals;
      final IconData typeIcon;
      switch (selectedType) {
        case RentalServiceType.homeStay:
          rentals = _rentalCtrl.homeStayServices;
          typeIcon = Icons.house_outlined;
          break;
        case RentalServiceType.flatRoom:
          rentals = _rentalCtrl.flatRoomServices;
          typeIcon = Icons.apartment_outlined;
          break;
        case RentalServiceType.vehicle:
          rentals = _rentalCtrl.vehicleServices;
          typeIcon = Icons.directions_car_outlined;
          break;
      }

      if (_rentalCtrl.isLoading.value) {
        return _buildRentalSkeletonGrid();
      }

      if (rentals.isEmpty) {
        return _buildRentalEmptyState(selectedType.label, typeIcon);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section eyebrow — primary accent bar + selected type's
          // label + count chip. Echoes the active filter chip up in
          // the header strip so the connection between "what I'm
          // filtering by" and "what's listed" is visually implicit.
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                CustomText(
                  selectedType.label,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomText(
                    '${rentals.length}',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (innerCtx, constraints) {
              const crossSpacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - crossSpacing) / 2;
              return MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: 10,
                itemCount: rentals.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  // Stagger each tile's fade + lift on first build.
                  // ValueKey(sId) makes the entry animation only
                  // fire the first time *this rental* shows up;
                  // unrelated parent rebuilds preserve State and
                  // skip the replay. Type-filter switches change
                  // keys → new tiles animate in fresh, surviving
                  // tiles stay put.
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('rental-${rental.sId ?? index}'),
                    duration: Duration(
                        milliseconds: 280 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (_, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 12),
                        child: child,
                      ),
                    ),
                    child: RentalCard(
                      rentalServiceData: rental,
                      width: itemWidth,
                      deleteServiceApi: () async {
                        await showCommonDialog(
                          context: innerCtx,
                          text: AppStrings.areYouSureDelete,
                          confirmText: AppStrings.delete,
                          cancelText: AppStrings.cancel,
                          confirmCallback: () {
                            _rentalCtrl.deleteService(
                              serviceId: rental.sId ?? '',
                            );
                          },
                          cancelCallback: () {
                            Get.back();
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
    });
  }

  // ─────────────────────────────────────────────
  // LOADING / EMPTY
  // ─────────────────────────────────────────────

  // Loading state — 4 skeleton cards in the same 2-col masonry the
  // live grid uses, so the page geometry doesn't shift when data
  // arrives. Cards stagger their pulse start so the grid breathes
  // as a wave rather than four cards thudding in sync.
  Widget _buildRentalSkeletonGrid() {
    return LayoutBuilder(
      builder: (innerCtx, constraints) {
        const crossSpacing = 10.0;
        final itemWidth = (constraints.maxWidth - crossSpacing) / 2;
        return MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: 10,
          itemCount: 4,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) => _RentalSkeletonCard(
            width: itemWidth,
            // Cycle through 0/120/240/360-ms head-starts so the
            // four cards pulse out of phase — reads as a wave.
            delay: Duration(milliseconds: 120 * index),
          ),
        );
      },
    );
  }

  // Empty state — featured medallion + headline/subhead + primary
  // CTA, all wrapped in a soft-bordered card so it visually
  // mirrors the header strip's chrome. The medallion icon swaps
  // per type (house / apartment / car) so the empty state speaks
  // to which bucket is empty.
  Widget _buildRentalEmptyState(String typeLabel, IconData typeIcon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size32,
        horizontal: SizeConfig.size20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medallion: gradient disk + radial glow halo behind.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withValues(alpha: 0.22),
                      AppColors.primaryColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.85],
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.78),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(typeIcon, color: Colors.white, size: 36),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            '$typeLabel ${AppStrings.servicesAreEmpty.tr}',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.createYourService.tr,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size20),
          // Primary CTA — gradient pill with primary-tinted shadow.
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showAddRentalSheet,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size20,
                  vertical: SizeConfig.size12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.82),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    CustomText(
                      'Add Rental',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder card used by the rental loading state. Pulses a
// primary tint between low/high alphas via a single repeating
// AnimationController so 4 of these in a grid create a soft wave
// when each receives a different start delay.
class _RentalSkeletonCard extends StatefulWidget {
  final double width;
  final Duration delay;

  const _RentalSkeletonCard({
    required this.width,
    this.delay = Duration.zero,
  });

  @override
  State<_RentalSkeletonCard> createState() => _RentalSkeletonCardState();
}

class _RentalSkeletonCardState extends State<_RentalSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    // Stagger the start of the loop per card so the four cards in
    // the loading grid pulse out of phase. Guard `mounted` because
    // the card may have already been disposed if loading finishes
    // before the delay elapses.
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final low = AppColors.primaryColor.withValues(alpha: 0.06);
        final high = AppColors.primaryColor.withValues(alpha: 0.16);
        final blockColor = Color.lerp(low, high, t)!;
        return Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image-area placeholder — sized to the same ~0.85
              // aspect typical of rental cards' hero photo so the
              // skeleton silhouette matches what pops in.
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: Container(
                  height: widget.width * 0.85,
                  color: blockColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: widget.width * 0.7,
                      height: 10,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: widget.width * 0.45,
                      height: 8,
                      decoration: BoxDecoration(
                        color: blockColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 32,
                      height: 18,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
