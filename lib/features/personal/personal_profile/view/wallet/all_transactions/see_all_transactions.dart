import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/api/apiService/api_response.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class SeeAllTransactionsView extends StatefulWidget {
  const SeeAllTransactionsView({super.key});

  @override
  State<SeeAllTransactionsView> createState() => _SeeAllTransactionsViewState();
}

class _SeeAllTransactionsViewState extends State<SeeAllTransactionsView> {
  final controller = getOrPut(() => WalletController());

  @override
  void initState() {
    super.initState();
    // Fresh, unfiltered page-1 load of the See-All list (separate from the home
    // preview). Filters start cleared so the screen opens on the full list.
    controller.resetTransactionFilters();
    controller.page = 1;
    controller.isMoreDataInList = true;
    controller.getWalletTransactionApi(isFromFilter: true);
  }

  /// Applies a single filter (status XOR type) and refetches. `status` and
  /// `type` are mutually exclusive — passing neither clears the filter.
  void _applyFilter({String? status, String? type}) {
    controller.selectedStatus = status;
    controller.selectedType = type;
    Navigator.of(context).pop(); // close the filter sheet
    // Show the loader immediately, then refetch with the new filter.
    controller.viewTransactionHistoryResponse.value = ApiResponse.loading();
    controller.getWalletTransactionApi();
  }

  /// Filter icon for the app bar (with a dot when a filter is active). Opens a
  /// self-contained bottom sheet instead of the shared popup, whose nested
  /// ExpansionTile-in-PopupMenuItem swallowed taps so the filter never applied.
  Widget _filterButton() {
    final bool hasFilter =
        controller.selectedStatus != null || controller.selectedType != null;
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size12),
      child: InkWell(
        onTap: _openFilterSheet,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.filter_list_rounded,
                  color: AppColors.black, size: 24),
              if (hasFilter)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final selStatus = controller.selectedStatus;
    final selType = controller.selectedType;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(
                      "Filter Transactions",
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    const Spacer(),
                    if (selStatus != null || selType != null)
                      GestureDetector(
                        onTap: () => _applyFilter(),
                        child: CustomText(
                          "Clear",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetLabel("Status"),
                _sheetOption("Pending",
                    selected: selStatus == "PENDING",
                    onTap: () => _applyFilter(status: "PENDING")),
                _sheetOption("Completed",
                    selected: selStatus == "COMPLETED",
                    onTap: () => _applyFilter(status: "COMPLETED")),
                _sheetOption("Rejected",
                    selected: selStatus == "REJECTED",
                    onTap: () => _applyFilter(status: "REJECTED")),
                const SizedBox(height: 10),
                _sheetLabel("Type"),
                _sheetOption("Credit",
                    selected: selType == "CREDIT",
                    onTap: () => _applyFilter(type: "CREDIT")),
                _sheetOption("Debit",
                    selected: selType == "DEBIT",
                    onTap: () => _applyFilter(type: "DEBIT")),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: CustomText(
        text.toUpperCase(),
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTextColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _sheetOption(String label,
      {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primaryColor : AppColors.grayText,
            ),
            SizedBox(width: SizeConfig.size12),
            CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppColors.primaryColor : AppColors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.viewTransactionHistoryResponse.value.status;
      final list =
          controller.walletTransactionResponseModalClass.value.data ?? [];
      final bool isLoading =
          status == Status.LOADING || status == Status.INITIAL;

      return Scaffold(
        // App bar (with the filter) is ALWAYS shown — the body alone reacts to
        // loading/empty/list, so the filter stays reachable at all times.
        appBar: CommonBackAppBar(
          title: "Transactions",
          isLeading: true,
          buildCustomActionWidget: () => _filterButton(),
        ),
        body: (isLoading && list.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : list.isEmpty
                ? const Center(child: CustomText("No Transaction Found"))
                : SingleChildScrollView(
                    // Drives pagination; the card below hugs its content so it
                    // doesn't stretch full-height for just a few items.
                    controller: controller.listScrollController,
                    child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    padding: EdgeInsets.all(16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length +
                          (controller.isMoreDataInList ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show bottom loader
                        if (index == list.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        var data = list[index];

                        return Column(
                          children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            data.title,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        CustomText(
                          '${data.isCredit ? '+' : '-'} \u{20B9}${data.amountInRupees ?? 0}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: data.isCredit
                              ? AppColors.green39
                              : AppColors.orange,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          data.createdAt != null
                              ? DateFormat('MMM d, hh:mm a')
                              .format(data.createdAt!.toLocal())
                              : "",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                        Row(
                          children: [
                            Icon(
                              data.isPending
                                  ? Icons.watch_later_outlined
                                  : data.isRejected
                                      ? Icons.cancel_outlined
                                      : Icons.check_circle_outline_outlined,
                              color: data.isPending
                                  ? AppColors.orange
                                  : data.isRejected
                                      ? AppColors.red
                                      : AppColors.green39,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            CustomText(
                              data.statusLabel,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: data.isPending
                                  ? AppColors.orange
                                  : data.isRejected
                                      ? AppColors.red
                                      : AppColors.green39,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
                      separatorBuilder: (context, index) => SizedBox(
                        height: 20,
                      ),
                    ),
                  ),
                  ),
      );
    });
  }
}
