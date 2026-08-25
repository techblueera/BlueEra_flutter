import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The customer's pickup code, full screen.
///
/// It is read aloud or held up across a counter, so: full width, large mono
/// type, maximum contrast, and the **screen stays awake** while it is open
/// (guide §3.4). Nothing here is computed — the code comes from
/// `GET /api/orders/:id/pickup-code`.
class PickupCodeScreen extends StatefulWidget {
  final String pickupCode;
  final String? shopName;
  final String? shopAddress;
  final String? orderSummary;

  /// Optional directions tap — wired by the caller when it has coordinates.
  final VoidCallback? onDirections;

  const PickupCodeScreen({
    super.key,
    required this.pickupCode,
    this.shopName,
    this.shopAddress,
    this.orderSummary,
    this.onDirections,
  });

  @override
  State<PickupCodeScreen> createState() => _PickupCodeScreenState();
}

class _PickupCodeScreenState extends State<PickupCodeScreen> {
  @override
  void initState() {
    super.initState();
    // Best-effort: a device that refuses the wakelock still shows the code.
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  /// `A1B2C3` → `A1B 2C3`, so it can be read out in two chunks without the
  /// listener losing their place.
  String get _spaced {
    final code = widget.pickupCode.trim().toUpperCase();
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.mainTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomText(
          'Pickup code',
          fontSize: SizeConfig.size16,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              CustomText(
                'Show this at the shop',
                fontSize: SizeConfig.size15,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.pickupCode.toUpperCase()));
                  commonSnackBar(message: 'Pickup code copied');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _spaced,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: SizeConfig.size48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CustomText(
                'The shop enters this code to hand your order over.',
                fontSize: SizeConfig.size12,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if ((widget.shopName ?? '').isNotEmpty ||
                  (widget.shopAddress ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          color: AppColors.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((widget.shopName ?? '').isNotEmpty)
                              CustomText(
                                widget.shopName!,
                                fontSize: SizeConfig.size14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor,
                              ),
                            if ((widget.shopAddress ?? '').isNotEmpty)
                              CustomText(
                                widget.shopAddress!,
                                fontSize: SizeConfig.size12,
                                color: AppColors.secondaryTextColor,
                              ),
                          ],
                        ),
                      ),
                      if (widget.onDirections != null)
                        TextButton.icon(
                          onPressed: widget.onDirections,
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: CustomText(
                            'Directions',
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              if ((widget.orderSummary ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CustomText(
                    widget.orderSummary!,
                    fontSize: SizeConfig.size12,
                    color: AppColors.grayText,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
