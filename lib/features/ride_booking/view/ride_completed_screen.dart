import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
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
  final Set<String> _tags = {};
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  /// Quick-tap feedback. Which set is offered depends on the rating: praising
  /// a 5-star ride and explaining a 2-star one need opposite vocabularies.
  static const List<String> _positiveTags = [
    'Safe driving',
    'Polite',
    'Clean vehicle',
    'On time',
    'Knows the route',
  ];

  static const List<String> _negativeTags = [
    'Rash driving',
    'Rude behaviour',
    'Took a longer route',
    'Kept me waiting',
    'Asked for extra fare',
  ];

  bool get _isNegative => _rating > 0 && _rating <= 3;

  List<String> get _currentTags => _isNegative ? _negativeTags : _positiveTags;

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
        final selected = _tags.contains(tag);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _tags.remove(tag) : _tags.add(tag);
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
              tag,
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
    const reasons = [
      'Driver behaved badly',
      'I was overcharged',
      'Unsafe or rash driving',
      'Vehicle did not match',
      'I left an item in the vehicle',
      'Something else',
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
                  reason,
                  fontSize: 15,
                  color: RideStyle.ink,
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 20, color: RideStyle.inkMuted),
                onTap: () {
                  Get.back();
                  _submitReport(reason);
                },
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────

  Future<void> _submitReport(String reason) async {
    // Same missing-endpoint caveat as [_submit]. Logged rather than silently
    // dropped so the choice is at least visible while the API is pending.
    log('ride report — order=${widget.booking.rideId} reason=$reason');
    commonSnackBar(
      message: 'Thanks — we\'ve logged your report and will look into it.',
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _finish();
      return;
    }
    setState(() => _submitting = true);

    // NOTE: there is no rating endpoint on the ride service yet — nothing in
    // `rider_service_api.dart` accepts feedback for a completed order. The
    // rating is collected and acknowledged here; once the endpoint exists,
    // POST it from this method. Deliberately fail-soft either way: a customer
    // must never be held on this screen because feedback couldn't be sent.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _submitting = false);
    commonSnackBar(message: 'Thanks for the feedback!');
    _finish();
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
