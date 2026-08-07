import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Customer Care sheet for a ride that is already under way.
///
/// Takes over the slot the ride-start OTP pill occupies on the ongoing-ride
/// cards: once the customer has read the code out, the OTP is spent and the
/// only thing they still need from that row is a way to raise a problem with
/// the captain.
///
/// The complaint opens a **real, two-way support thread with the ride/order
/// team**, one per order: `POST chat-service/support/order-support` posts the
/// reason as the thread's first message and returns a conversation the customer
/// is dropped straight into. A second complaint about the same ride appends to
/// that thread; a different ride opens its own.
///
/// Not the captain's chat, deliberately — the whole point of the sheet is that
/// something went wrong with the captain, and a complaint about someone should
/// not be delivered to them. See
/// docs/backend/ORDER_CUSTOMER_SUPPORT_FLUTTER_GUIDE.md.
///
/// [rideId] is the ORDER id the thread is keyed on. Without it there is nothing
/// to open, so the submit button reports that rather than posting a complaint
/// into a thread the team can't route.
Future<void> showRideCustomerCareSheet({
  required String riderName,
  String? rideId,
  String? vehicleType,
  Map<String, dynamic>? ride,
}) async {
  await Get.bottomSheet<void>(
    _CustomerCareSheet(
      riderName: riderName,
      rideId: rideId,
      vehicleType: vehicleType,
      ride: ride,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// The complaints a customer can raise about a ride in progress.
///
/// Deliberately short: a long list makes people pick "Other" and type, which
/// is the one answer support can't route automatically.
const List<({IconData icon, String label})> _kComplaintReasons = [
  (icon: Icons.speed_rounded, label: 'Rash or unsafe driving'),
  (icon: Icons.sentiment_very_dissatisfied_rounded, label: 'Rude behaviour'),
  (icon: Icons.currency_rupee_rounded, label: 'Asked for extra fare'),
  (icon: Icons.alt_route_rounded, label: 'Took a wrong route'),
  (icon: Icons.no_crash_rounded, label: 'Vehicle condition'),
  (icon: Icons.more_horiz_rounded, label: 'Something else'),
];

class _CustomerCareSheet extends StatefulWidget {
  const _CustomerCareSheet({
    required this.riderName,
    this.rideId,
    this.vehicleType,
    this.ride,
  });

  final String riderName;
  final String? rideId;

  /// Passed through so the team can filter the queue by vehicle class.
  final String? vehicleType;

  /// `{from, to, fare}` snapshot, so the agent opening the thread can see the
  /// trip without looking it up.
  final Map<String, dynamic>? ride;

  @override
  State<_CustomerCareSheet> createState() => _CustomerCareSheetState();
}

class _CustomerCareSheetState extends State<_CustomerCareSheet> {
  int? _selected;
  final TextEditingController _note = TextEditingController();

  /// Focus + a key on the note field, so it can be scrolled into view once the
  /// keyboard has taken its half of the screen.
  ///
  /// Lifting the sheet is only half the fix: the sheet is capped at 90% of the
  /// screen, so with the keyboard up the visible part is short and the note —
  /// which lives near the bottom of a long form — can still end up below the
  /// fold. Raising the sheet gets it out from UNDER the keyboard; this scrolls
  /// it into what is left.
  final FocusNode _noteFocus = FocusNode();
  final GlobalKey _noteKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();

  /// Guards the submit while the call is out. The sheet stays open until the
  /// thread actually exists, so a failure can be retried with the reason and
  /// note still filled in — closing first and failing silently would make the
  /// customer re-pick everything.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteFocus.addListener(_onNoteFocusChanged);
  }

  /// Bring the note into view when it takes focus.
  ///
  /// Deferred past the keyboard's own slide-in (~200 ms): scrolling while the
  /// viewport is still shrinking computes against a height that is about to
  /// change, and the field lands short. Aligned to 0.5 so it settles in the
  /// middle of what is visible rather than flush against the keyboard.
  void _onNoteFocusChanged() {
    if (!_noteFocus.hasFocus) return;
    Future.delayed(const Duration(milliseconds: 260), () {
      final ctx = _noteKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    });
  }

  @override
  void dispose() {
    _noteFocus.removeListener(_onNoteFocusChanged);
    _noteFocus.dispose();
    _scrollCtrl.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Open (or continue) the per-order support thread and drop the customer into
  /// it. See docs/backend/ORDER_CUSTOMER_SUPPORT_FLUTTER_GUIDE.md.
  Future<void> _submit() async {
    if (_submitting || _selected == null) return;

    final orderId = widget.rideId?.trim() ?? '';
    if (orderId.isEmpty) {
      // The thread is keyed per order; the backend 400s without it. Say so
      // rather than firing a call that cannot succeed.
      commonSnackBar(message: 'Ride details are missing. Please try again.');
      return;
    }

    setState(() => _submitting = true);
    try {
      // ChatViewRepo, not the ride repo: `order-support` is a CHAT-service
      // route (`chat-service/support/order-support`). See the guide's base-URL
      // warning — the same path under rider-service is a 404.
      final response = await ChatViewRepo().openOrderSupportApi(
        orderId: orderId,
        reason: _kComplaintReasons[_selected!].label,
        note: _note.text,
        vehicleType: widget.vehicleType,
        ride: widget.ride,
      );

      final body = response.response?.data;
      final map = body is Map ? Map<String, dynamic>.from(body) : null;
      final conversationId = (map?['conversation_id'] ?? '').toString();

      if (!response.isSuccess || conversationId.isEmpty) {
        // Covers the documented 500 while `RIDE_TRACK_TEAM_USER_ID` is still
        // unset on the chat service: the thread genuinely does not exist, so
        // there is nothing to navigate to.
        commonSnackBar(
          message: 'Could not open support chat. Please try again.',
        );
        return;
      }

      final displayName = (map?['display_name'] as String?)?.trim();

      if (!mounted) return;
      // Close the sheet only now — the thread exists, so there is somewhere to
      // land. Then open it over whatever the sheet was covering.
      Get.back();
      Get.to(
        () => PersonalChatScreen(
          type: AppConstants.personal_Chat_Type,
          // The conversation already exists (the reason is its first message),
          // so this is never an "initial message" screen.
          isInitialMessage: false,
          // The response carries no user id for the team account, and none is
          // needed: with a real conversation id every send and the socket join
          // key off that. Blank rather than invented.
          userId: '',
          conversationId: conversationId,
          // The team account's REAL name is "BlueEra Ride Order Track" — the
          // backend's `display_name` is the friendly label meant to replace it
          // at the top of the chat (guide §4).
          name: (displayName?.isNotEmpty ?? false)
              ? displayName!
              : 'Order Customer Support',
        ),
      );
    } catch (_) {
      if (mounted) {
        commonSnackBar(
          message: 'Could not open support chat. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final keyboardOpen = keyboard > 0;

    // LIFT THE SHEET, don't pad its contents.
    //
    // This used to add `viewInsets.bottom` to the scroll view's own bottom
    // padding. That does not move the sheet at all — it makes its content
    // taller by the height of the keyboard, so the sheet grows off the bottom
    // of the screen and the whole form appears to shift while the note field
    // stays exactly where it was, under the keyboard.
    //
    // Padding the OUTSIDE is what actually raises the sheet to sit on top of
    // the keyboard. Animated because the keyboard slides in over ~200 ms and an
    // instant jump reads as a glitch.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        // Capped so a tall sheet plus a keyboard can never exceed the screen —
        // without this the content overflows instead of scrolling.
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size20,
            SizeConfig.size12,
            SizeConfig.size20,
            // The home indicator only needs clearing when the keyboard is NOT
            // covering it; adding both leaves a dead band above the keys.
            (keyboardOpen ? 0 : media.padding.bottom) + SizeConfig.size20,
          ),
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E9EF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      color: AppColors.primaryColor, size: 21),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'Customer Care',
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        'Report a problem with ${widget.riderName}',
                        fontSize: SizeConfig.small11,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                // Explicit way out. The drag handle implies one, but a sheet
                // this tall is often opened with the keyboard up and a swipe
                // down dismisses the keyboard first — leaving the customer
                // swiping twice to close a form they only meant to glance at.
                // Disabled mid-submit so the sheet can't be closed out from
                // under a call that is about to navigate.
                InkWell(
                  onTap: _submitting ? null : Get.back,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: _submitting
                          ? AppColors.grayText
                          : AppColors.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size16),
            // Where the report goes. Said up front, because "customer care"
            // usually means a ticket the customer never sees again — this one
            // lands in a thread they can open and follow.
            Container(
              padding: EdgeInsets.all(SizeConfig.size10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined,
                      size: 16, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      'Sent as an inquiry into this ride\'s chat',
                      fontSize: SizeConfig.small11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              'What went wrong?',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            for (int i = 0; i < _kComplaintReasons.length; i++) ...[
              if (i > 0) SizedBox(height: SizeConfig.size8),
              _reasonTile(i),
            ],
            SizedBox(height: SizeConfig.size16),
            TextField(
              key: _noteKey,
              controller: _note,
              focusNode: _noteFocus,
              textInputAction: TextInputAction.done,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(fontSize: SizeConfig.medium),
              decoration: InputDecoration(
                hintText: 'Add details (optional)',
                hintStyle: TextStyle(
                  fontSize: SizeConfig.small11,
                  color: AppColors.secondaryTextColor,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F7FB),
                contentPadding: EdgeInsets.all(SizeConfig.size12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            // Disabled until a reason is picked: a report with no category is
            // the one thing support can do nothing with.
            SizedBox(
              width: double.infinity,
              child: Material(
                color: (_selected == null || _submitting)
                    ? AppColors.primaryColor.withValues(alpha: 0.45)
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: (_selected == null || _submitting) ? null : _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
                    child: _submitting
                        // Opening the thread is a round-trip, and the sheet
                        // deliberately stays put until it lands — so it has to
                        // show that something is happening.
                        ? Center(
                            child: SizedBox(
                              height: SizeConfig.size18,
                              width: SizeConfig.size18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.white),
                              ),
                            ),
                          )
                        : CustomText(
                            'Send to chat',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reasonTile(int index) {
    final reason = _kComplaintReasons[index];
    final bool active = _selected == index;
    return Material(
      color: active
          ? AppColors.primaryColor.withValues(alpha: 0.08)
          : const Color(0xFFF4F7FB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selected = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12, vertical: SizeConfig.size10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primaryColor : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(
                reason.icon,
                size: 18,
                color:
                    active ? AppColors.primaryColor : AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  reason.label,
                  fontSize: SizeConfig.medium,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                active
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color:
                    active ? AppColors.primaryColor : AppColors.grayText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
