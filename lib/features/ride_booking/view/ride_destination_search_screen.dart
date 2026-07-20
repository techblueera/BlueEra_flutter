import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

  void _choose(RidePlace place) {
    _focusNode.unfocus();
    Get.back(result: place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
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

  Widget _results() {
    return Obx(() {
      // The controller's observable copy, not the TextEditingController — the
      // latter isn't reactive, so Obx couldn't see a keystroke that didn't
      // also move searchResults/isSearching.
      final query = controller.searchQuery.value;
      final showRecents = query.length < 2;
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
            onTap: () => _choose(place),
            onToggleSave: () => controller.toggleSavedPlace(place),
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
  });

  final RidePlace place;
  final IconData leading;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(leading, size: 24, color: RideStyle.inkMuted),
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
