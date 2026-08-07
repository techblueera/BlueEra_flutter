import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
/// The complaint is framed as an **inquiry into the ride's chat thread** —
/// the same Inquiry-tab conversation the ride cards already land in — so the
/// customer's report sits next to the ride it is about instead of in a
/// separate support silo.
///
/// DESIGN ONLY. Nothing here is wired to a backend yet: [_submit] closes the
/// sheet and reports "coming soon" rather than posting anything. To finish it,
/// send the selected reason + note into the captain's Inquiry conversation
/// (the thread `openRiderInquiryChat` opens) and/or a support endpoint, then
/// replace [_submit]'s placeholder.
Future<void> showRideCustomerCareSheet({
  required String riderName,
  String? rideId,
}) async {
  await Get.bottomSheet<void>(
    _CustomerCareSheet(riderName: riderName, rideId: rideId),
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
  const _CustomerCareSheet({required this.riderName, this.rideId});

  final String riderName;
  final String? rideId;

  @override
  State<_CustomerCareSheet> createState() => _CustomerCareSheetState();
}

class _CustomerCareSheetState extends State<_CustomerCareSheet> {
  int? _selected;
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Placeholder — see the DESIGN ONLY note on [showRideCustomerCareSheet].
  void _submit() {
    Get.back();
    commonSnackBar(message: "Coming soon....");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size20,
        SizeConfig.size12,
        SizeConfig.size20,
        // Clear the keyboard as well as the home indicator — the note field
        // sits at the bottom of the sheet.
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            SizeConfig.size20,
      ),
      child: SingleChildScrollView(
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
              controller: _note,
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
                color: _selected == null
                    ? AppColors.primaryColor.withValues(alpha: 0.45)
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _selected == null ? null : _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size14),
                    child: CustomText(
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
