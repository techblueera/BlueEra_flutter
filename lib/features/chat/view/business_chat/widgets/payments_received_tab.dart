import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/payment_qr_controller.dart';
import 'package:BlueEra/features/chat/auth/model/payment_qr_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Lists payments received against the current user's Payment QRs
/// (GET /payment-qr/transactions/received). Refreshed on pull-to-refresh and
/// whenever a `payment:received` socket event lands.
class PaymentsReceivedTab extends StatefulWidget {
  final PaymentQrController controller;

  const PaymentsReceivedTab({super.key, required this.controller});

  @override
  State<PaymentsReceivedTab> createState() => _PaymentsReceivedTabState();
}

class _PaymentsReceivedTabState extends State<PaymentsReceivedTab> {
  final ScrollController _scrollController = ScrollController();

  PaymentQrController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.loadReceivedTransactions(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _c.loadReceivedTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final txns = _c.receivedTransactions;
      final loading = _c.isLoadingReceived.value;

      if (txns.isEmpty && loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      }

      if (txns.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _c.loadReceivedTransactions(reset: true),
          child: ListView(
            children: [
              SizedBox(height: SizeConfig.screenHeight * 0.18),
              Icon(Icons.account_balance_wallet_outlined,
                  size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Center(
                child: CustomText(
                  'No payments received yet',
                  fontSize: SizeConfig.size14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _c.loadReceivedTransactions(reset: true),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: txns.length + (loading ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index >= txns.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryColor),
                  ),
                ),
              );
            }
            return _ReceivedTile(txn: txns[index]);
          },
        ),
      );
    });
  }
}

class _ReceivedTile extends StatelessWidget {
  final PaymentTransaction txn;

  const _ReceivedTile({required this.txn});

  String _formatAmount(num? value) {
    if (value == null) return '0';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenshot = txn.screenshotUrl;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Screenshot thumb
          if (screenshot != null && screenshot.isNotEmpty)
            GestureDetector(
              onTap: () => _showScreenshot(context, screenshot),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  screenshot,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: Colors.black12,
                    child: const Icon(Icons.receipt_long_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.south_west_rounded,
                  color: AppColors.primaryColor),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'UTR: ${txn.utrNo ?? '-'}',
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                CustomText(
                  _formatDate(txn.createdAt),
                  fontSize: SizeConfig.size11,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CustomText(
            '₹${_formatAmount(txn.amount)}',
            fontSize: SizeConfig.size16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
