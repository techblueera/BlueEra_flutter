import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_vehicle_presentation.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen destination search.
///
/// Pops with the chosen [RidePlace] via `Get.back(result:)`, so the caller
/// decides what happens next rather than this screen knowing the flow order.
class RideDestinationSearchScreen extends StatefulWidget {
  const RideDestinationSearchScreen({super.key});

  @override
  State<RideDestinationSearchScreen> createState() =>
      _RideDestinationSearchScreenState();
}

class _RideDestinationSearchScreenState
    extends State<RideDestinationSearchScreen> {
  final RideBookingController controller = Get.find<RideBookingController>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller.clearSearch();
    // Open with the keyboard up — the user tapped a search box to get here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// `id` of the row being resolved, or null. Drives the row spinner and blocks
  /// a second tap while a lookup is in flight.
  String? _resolvingId;

  /// Resolve the tapped row's coordinates, then pop with it.
  ///
  /// Search rows arrive WITHOUT coordinates — resolving all of them just to
  /// build the list was costing a billed Place Details per row, per keystroke
  /// burst (see [RideBookingController.resolveSearchResult] and
  /// docs/GOOGLE_MAPS_COST_GUIDE.md §3.1). Recents and saved places already
  /// carry coordinates and resolve instantly.
  Future<void> _choose(RidePlace place) async {
    if (_resolvingId != null) return;
    setState(() => _resolvingId = place.id);
    final resolved = await controller.resolveSearchResult(place);
    if (!mounted) return;
    setState(() => _resolvingId = null);
    if (resolved == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    _focusNode.unfocus();
    Get.back(result: resolved);
  }

  /// Hearting a row also needs its coordinates — a saved place with none is a
  /// row the user can never travel to.
  Future<void> _toggleSave(RidePlace place) async {
    final resolved = await controller.resolveSearchResult(place);
    if (!mounted || resolved == null) return;
    controller.toggleSavedPlace(resolved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _vehicleStrip(),
            const Divider(height: 1, color: RideStyle.hairline),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: RideStyle.ink),
          ),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: RideStyle.surfaceTint,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: RideStyle.hairline),
              ),
              child: Row(
                children: [
                  const RideEndpointDot(color: RideStyle.drop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      onChanged: controller.onSearchQueryChanged,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RideStyle.ink,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Where do you want to go?',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: RideStyle.inkMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Reads searchQuery FIRST, before any early return — an Obx
                  // that bails out without touching an observable has nothing
                  // to subscribe to and throws "improper use of GetX". The
                  // field starts empty, so the old version threw on the very
                  // first build.
                  Obx(() {
                    if (controller.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () {
                        _textController.clear();
                        controller.clearSearch();
                      },
                      child: const Icon(Icons.close,
                          size: 20, color: RideStyle.inkMuted),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The vehicle this search will book, named under the search field.
  ///
  /// The flow always has one by the time this screen opens: a service tile on
  /// the home screen carries its own, and arriving through the search field
  /// settles on the bike ([RideBookingController.kDefaultVehicleType]). Until
  /// now that choice — made or defaulted — stayed invisible until the fare
  /// screen two steps later, so a customer who wanted a cab typed a destination
  /// believing they were booking one.
  ///
  /// Reads the same [RideVehicleArt] the home tiles are built from, so the row
  /// shows the artwork and name the user just tapped ("Parcel On Bike", not
  /// "Bike").
  Widget _vehicleStrip() {
    return Obx(() {
      final code = controller.preselectedVehicleCode.value ??
          RideBookingController.kDefaultVehicleType;
      final orderFor = controller.orderFor.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: RideStyle.surfaceTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: LocalAssets(
                imagePath: RideVehicleArt.assetFor(code, orderFor: orderFor),
                boxFix: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Booking for',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: RideStyle.inkMuted,
                  ),
                  CustomText(
                    // vehicleLabelFor reads the catalogue, so the name matches
                    // the backend's once it lands and the compiled-in one until
                    // then — never a raw enum.
                    '${RideVehicleArt.labelFor(
                      code,
                      orderFor: orderFor,
                      catalogueLabel: controller.vehicleLabelFor(code),
                    )} · ${RideVehicleArt.tripTypeLabel(orderFor)}',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _results() {
    return Obx(() {
      // The controller's observable copy, not the TextEditingController — the
      // latter isn't reactive, so Obx couldn't see a keystroke that didn't
      // also move searchResults/isSearching.
      final query = controller.searchQuery.value;
      // Must match the controller's own minimum, or a 2-character query shows
      // an empty "no results" list instead of the recents it used to.
      final showRecents = query.length < RideBookingController.minSearchChars;
      final places =
          showRecents ? controller.recentPlaces : controller.searchResults;

      if (controller.isSearching.value && places.isEmpty) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
      }

      if (places.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: CustomText(
              showRecents
                  ? 'Search for a destination to get started'
                  : 'No places match "$query"',
              fontSize: 14,
              color: RideStyle.inkMuted,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: places.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: RideStyle.hairline),
        ),
        itemBuilder: (context, index) {
          final place = places[index];
          return _PlaceResultTile(
            place: place,
            // Recents keep the clock glyph; live results get a pin.
            leading: showRecents ? Icons.history : Icons.location_on_outlined,
            resolving: _resolvingId == place.id,
            onTap: () => _choose(place),
            onToggleSave: () => _toggleSave(place),
          );
        },
      );
    });
  }
}

class _PlaceResultTile extends StatelessWidget {
  const _PlaceResultTile({
    required this.place,
    required this.leading,
    required this.onTap,
    required this.onToggleSave,
    this.resolving = false,
  });

  final RidePlace place;
  final IconData leading;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  /// This row's coordinates are being fetched — swaps the glyph for a spinner
  /// and disables the tap.
  final bool resolving;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: resolving ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: resolving
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(leading, size: 24, color: RideStyle.inkMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    place.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  CustomText(
                    place.subtitle,
                    fontSize: 13,
                    color: RideStyle.inkMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleSave,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  place.isSaved ? Icons.favorite : Icons.favorite_border,
                  size: 23,
                  color: place.isSaved ? RideStyle.drop : RideStyle.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
