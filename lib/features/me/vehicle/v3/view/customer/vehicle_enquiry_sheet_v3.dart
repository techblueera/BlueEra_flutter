import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `POST /bookings` — an **enquiry**, despite the contract's name.
///
/// No payment, no stock decrement, one open request per listing. On success
/// the chat service opens a card automatically, so this sheet's job ends at
/// sending; there is no second call and nothing to navigate to.
Future<void> showVehicleEnquirySheetV3({
  required BuildContext context,
  required VehicleListingV3 listing,
  required VehicleBuyerControllerV3 controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VehicleEnquirySheet(
      listing: listing,
      controller: controller,
    ),
  );
}

/// The four intents the contract accepts. Kept as a typed list so a typo
/// can't reach the wire — the server rejects anything outside this set.
const List<_EnquiryIntent> _intents = [
  _EnquiryIntent('BUY', 'Buy', Icons.shopping_bag_outlined),
  _EnquiryIntent('TEST_DRIVE', 'Test drive', Icons.drive_eta_outlined),
  _EnquiryIntent('EXCHANGE', 'Exchange', Icons.swap_horiz_rounded),
  _EnquiryIntent('INFO', 'More info', Icons.info_outline),
];

class _EnquiryIntent {
  final String value;
  final String label;
  final IconData icon;

  const _EnquiryIntent(this.value, this.label, this.icon);
}

class _VehicleEnquirySheet extends StatefulWidget {
  final VehicleListingV3 listing;
  final VehicleBuyerControllerV3 controller;

  const _VehicleEnquirySheet({
    required this.listing,
    required this.controller,
  });

  @override
  State<_VehicleEnquirySheet> createState() => _VehicleEnquirySheetState();
}

class _VehicleEnquirySheetState extends State<_VehicleEnquirySheet> {
  String _intent = _intents.first.value;
  final _offerController = TextEditingController();
  final _noteController = TextEditingController();
  bool _sending = false;

  /// Contract bound — the server rejects a longer note.
  static const int _noteMaxLength = 2000;

  @override
  void dispose() {
    _offerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await widget.controller.sendEnquiry(
      inventoryId: widget.listing.id,
      intent: _intent,
      offerPrice: num.tryParse(_offerController.text.trim()),
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size20,
          SizeConfig.size16,
          SizeConfig.size20,
          SizeConfig.size20,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  'Contact the seller',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  widget.listing.title,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  'What is this about?',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size8),
                Wrap(
                  spacing: SizeConfig.size8,
                  runSpacing: SizeConfig.size8,
                  children: _intents.map(_intentChip).toList(),
                ),
                SizedBox(height: SizeConfig.size16),
                _label('Your offer (optional)'),
                TextField(
                  controller: _offerController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration('e.g. 500000'),
                ),
                SizedBox(height: SizeConfig.size12),
                _label('Message (optional)'),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: _noteMaxLength,
                  decoration: _decoration('Anything you want to ask'),
                ),
                SizedBox(height: SizeConfig.size8),
                SizedBox(
                  height: SizeConfig.size48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      disabledBackgroundColor:
                          AppColors.primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send enquiry',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'OpenSans',
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

  Widget _intentChip(_EnquiryIntent intent) {
    final selected = _intent == intent.value;
    return InkWell(
      onTap: () => setState(() => _intent = intent.value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              intent.icon,
              size: 16,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              intent.label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size6),
        child: CustomText(
          text,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
      );
}
