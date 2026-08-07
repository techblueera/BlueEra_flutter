import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// End-of-ride summary: fare, captain, a star rating and a way to report a
/// problem.
///
/// Replaces the toast the flow used to end on. A completed ride is the one
/// moment the customer has something to say about it — a snackbar that
/// disappears in three seconds collects none of it, and gives no receipt of
/// what was paid.
///
/// Dismissal is never blocked: submitting is best-effort (see
/// [_submit]) so a rating that fails to send still lets the customer leave.
class RideCompletedScreen extends StatefulWidget {
  const RideCompletedScreen({
    super.key,
    required this.booking,
    this.onDone,
  });

  /// The finished ride. Captured before the controller resets, so the fare and
  /// captain survive on this screen.
  final RideBooking booking;

  /// Runs after the customer dismisses — the caller unwinds the navigation
  /// stack, since this screen doesn't know what's underneath it.
  final VoidCallback? onDone;

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int _rating = 0;

  /// Selected tags, held as the API's **slugs** rather than the labels on
  /// screen — the payload is the thing that has to be right, and keeping the
  /// selection in the sent form means no lookup can go missing between tapping
  /// a chip and posting it.
  final Set<String> _tags = {};

  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  /// Quick-tap feedback. Which set is offered depends on the rating: praising
  /// a 5-star ride and explaining a 2-star one need opposite vocabularies.
  ///
  /// Label and slug travel together in one record instead of a parallel
  /// label→slug map. A map lets the two drift — reword a label and its entry
  /// silently stops matching, which the server answers with a `400` nobody sees
  /// until QA. Here a label without a slug does not compile.
  ///
  /// Slugs are the contract; labels are UI only. See
  /// docs/backend/RIDE_RATING_AND_REPORT_FLUTTER_GUIDE.md §4.
  static const List<({String label, String slug})> _positiveTags = [
    (label: 'Safe driving', slug: 'safe_driving'),
    (label: 'Polite', slug: 'polite'),
    (label: 'Clean vehicle', slug: 'clean_vehicle'),
    (label: 'On time', slug: 'on_time'),
    (label: 'Knows the route', slug: 'knows_the_route'),
  ];

  static const List<({String label, String slug})> _negativeTags = [
    (label: 'Rash driving', slug: 'rash_driving'),
    (label: 'Rude behaviour', slug: 'rude_behaviour'),
    (label: 'Took a longer route', slug: 'longer_route'),
    (label: 'Kept me waiting', slug: 'kept_waiting'),
    (label: 'Asked for extra fare', slug: 'extra_fare'),
  ];

  bool get _isNegative => _rating > 0 && _rating <= 3;

  List<({String label, String slug})> get _currentTags =>
      _isNegative ? _negativeTags : _positiveTags;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back is "skip", not "trap" — the customer is done with the ride either
      // way, so leaving must always unwind the flow.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildFareCard(),
                      const SizedBox(height: 22),
                      _buildRatingBlock(),
                      if (_rating > 0) ...[
                        const SizedBox(height: 18),
                        _buildTagWrap(),
                        const SizedBox(height: 16),
                        _buildCommentField(),
                      ],
                      const SizedBox(height: 18),
                      _buildReportRow(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: RideStyle.pickup.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 38, color: RideStyle.pickup),
        ),
        const SizedBox(height: 14),
        CustomText(
          'Ride completed',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: RideStyle.ink,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        CustomText(
          widget.booking.drop.title.isNotEmpty
              ? 'You reached ${widget.booking.drop.title}'
              : 'Hope you had a good trip',
          fontSize: 14,
          color: RideStyle.inkMuted,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  // ── Fare ───────────────────────────────────────────────────────────

  Widget _buildFareCard() {
    final booking = widget.booking;
    final isCash = booking.paymentMode.toUpperCase() == 'CASH';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RideStyle.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RideStyle.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  isCash ? 'Amount paid in cash' : 'Amount paid',
                  fontSize: 14,
                  color: RideStyle.inkMuted,
                ),
              ),
              CustomText(
                '₹${booking.fare.toStringAsFixed(0)}',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: RideStyle.ink,
              ),
            ],
          ),
          if (booking.captain?.hasName == true) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: RideStyle.hairline),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.white,
                  backgroundImage: (booking.captain?.photoUrl?.isNotEmpty ??
                          false)
                      ? NetworkImage(booking.captain!.photoUrl!)
                      : null,
                  child: (booking.captain?.photoUrl?.isEmpty ?? true)
                      ? const Icon(Icons.person,
                          size: 20, color: RideStyle.inkMuted)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    booking.captain!.name,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                    maxLines: 1,
                  ),
                ),
                if ((booking.captain?.vehicleNumber ?? '').isNotEmpty)
                  CustomText(
                    booking.captain!.vehicleNumber!,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RideStyle.inkMuted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Rating ─────────────────────────────────────────────────────────

  Widget _buildRatingBlock() {
    return Column(
      children: [
        CustomText(
          widget.booking.captain?.firstName.isNotEmpty == true
              ? 'How was your ride with ${widget.booking.captain!.firstName}?'
              : 'How was your ride?',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: RideStyle.ink,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final value = i + 1;
            final filled = value <= _rating;
            return IconButton(
              onPressed: () => setState(() {
                _rating = value;
                // The tag vocabulary swaps at the 3/4 boundary, so anything
                // picked under the old set no longer applies.
                _tags.clear();
              }),
              iconSize: 38,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
              icon: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: filled ? RideStyle.star : RideStyle.hairline,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTagWrap() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _currentTags.map((tag) {
        final selected = _tags.contains(tag.slug);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _tags.remove(tag.slug) : _tags.add(tag.slug);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? RideStyle.action.withValues(alpha: 0.10)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? RideStyle.action : RideStyle.hairline,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: CustomText(
              tag.label,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? RideStyle.action : RideStyle.ink,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      maxLength: 300,
      style: const TextStyle(fontSize: 14, color: RideStyle.ink),
      decoration: InputDecoration(
        hintText: 'Anything else? (optional)',
        hintStyle: const TextStyle(fontSize: 14, color: RideStyle.inkMuted),
        counterText: '',
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RideStyle.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RideStyle.action),
        ),
      ),
    );
  }

  // ── Report ─────────────────────────────────────────────────────────

  Widget _buildReportRow() {
    return GestureDetector(
      onTap: _openReportSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RideStyle.hairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, size: 20, color: RideStyle.danger),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                'Report an issue with this ride',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RideStyle.ink,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: RideStyle.inkMuted),
          ],
        ),
      ),
    );
  }

  void _openReportSheet() {
    // Label + slug together, same reasoning as the rating tags above.
    const reasons = <({String label, String slug})>[
      (label: 'Driver behaved badly', slug: 'driver_behaviour'),
      (label: 'I was overcharged', slug: 'overcharged'),
      (label: 'Unsafe or rash driving', slug: 'unsafe_driving'),
      (label: 'Vehicle did not match', slug: 'vehicle_mismatch'),
      (label: 'I left an item in the vehicle', slug: 'item_left'),
      (label: 'Something else', slug: 'other'),
    ];

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(RideStyle.sheetRadius)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RideStyle.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              'What went wrong?',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RideStyle.ink,
            ),
            const SizedBox(height: 12),
            for (final reason in reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: CustomText(
                  reason.label,
                  fontSize: 15,
                  color: RideStyle.ink,
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 20, color: RideStyle.inkMuted),
                onTap: () {
                  Get.back();
                  _submitReport(reason.slug);
                },
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────

  /// [reasonSlug] is the API value, not the label the customer tapped — see the
  /// reason list in [_openReportSheet].
  ///
  /// Accepted on completed OR cancelled orders and repeatable, so there is no
  /// gate here beyond having an order id. The comment field belongs to the
  /// RATING, not the report, so nothing is sent with it: the report sheet is
  /// one tap by design.
  Future<void> _submitReport(String reasonSlug) async {
    final orderId = widget.booking.rideId;
    if (orderId.isEmpty) {
      commonSnackBar(message: 'Could not send your report. Please try again.');
      return;
    }

    RideReportResult? result;
    try {
      result = await RideBookingRepo()
          .reportRide(orderId: orderId, reason: reasonSlug);
    } catch (e) {
      log('ride report failed — order=$orderId reason=$reasonSlug: $e');
    }

    if (!mounted) return;
    if (result == null || !result.success) {
      commonSnackBar(message: 'Could not send your report. Please try again.');
      return;
    }
    // The reference is the whole point of returning an id: "we've logged your
    // report" used to be a claim with nothing behind it.
    commonSnackBar(
      message: result.reportId.isEmpty
          ? 'Thanks — we\'ve logged your report and will look into it.'
          : 'Report logged (${result.reportId}). We\'ll look into it.',
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _finish();
      return;
    }
    setState(() => _submitting = true);

    // `_tags` already holds SLUGS, and only the set matching the current star
    // band is ever offered — so the server's "tags must match the star set"
    // rule cannot be violated from here. It is still worth knowing the rule
    // exists: a 5-star rating carrying `rash_driving` is a `400`.
    final orderId = widget.booking.rideId;
    RideRatingResult? result;
    try {
      if (orderId.isNotEmpty) {
        result = await RideBookingRepo().rateRide(
          orderId: orderId,
          rating: _rating,
          tags: _tags.toList(),
          comment: _commentController.text,
        );
      }
    } catch (e) {
      log('ride rating failed — order=$orderId: $e');
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    // FAIL SOFT: thank them and release the screen whatever happened. A
    // customer must never be held on a finished ride because feedback could not
    // be sent, and telling them their compliment failed to send helps nobody.
    commonSnackBar(
      message: result != null && result.hasAggregate
          // The endpoint returns the captain's fresh aggregate, so the thanks
          // can show what the rating did rather than just acknowledging it.
          ? 'Thanks! ${_captainLabel()} is now rated '
              '${result.riderAverage.toStringAsFixed(1)}★'
          : 'Thanks for the feedback!',
    );
    _finish();
  }

  /// First name of the captain for the thank-you line, or a neutral noun.
  String _captainLabel() {
    final name = widget.booking.captain?.name.trim() ?? '';
    if (name.isEmpty) return 'Your captain';
    return name.split(' ').first;
  }

  void _finish() {
    widget.onDone?.call();
  }

  // ── Bottom bar ─────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: RideStyle.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RidePrimaryButton(
            label: _rating == 0 ? 'Done' : 'Submit rating',
            isLoading: _submitting,
            onTap: _submit,
          ),
          if (_rating > 0)
            TextButton(
              onPressed: _submitting ? null : _finish,
              child: CustomText(
                'Skip',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RideStyle.inkMuted,
              ),
            ),
        ],
      ),
    );
  }
}
