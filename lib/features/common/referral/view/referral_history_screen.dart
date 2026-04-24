import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_history_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({super.key});

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> {
  final controller = Get.find<ReferralController>();
  final chatViewController = Get.find<ChatViewController>();

  DateTimeRange? _dateRange;
  bool _isExporting = false;

  @override
  initState() {
    super.initState();
    controller.getWalletReferralHistoryApi(controller.selectedFilter.value);
  }

  List<WalletReferralHistoryData> get _visibleRows {
    final all = controller.referralHistoryData;
    if (_dateRange == null) return all.toList();
    final start = DateTime(
        _dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
    final endInclusive = DateTime(_dateRange!.end.year, _dateRange!.end.month,
            _dateRange!.end.day)
        .add(const Duration(days: 1));
    return all.where((item) {
      final d = DateTime.tryParse(item.createdAt ?? '');
      if (d == null) return false;
      final local = d.toLocal();
      return !local.isBefore(start) && local.isBefore(endInclusive);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.paddingXSL),
            // Active date-range banner sits ABOVE the tabs so it reads as
            // a scope filter for everything below it. Lives outside the
            // Obx branch so it is reachable even when the range filters
            // every row out.
            if (_dateRange != null)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10,
                    vertical: SizeConfig.size4),
                child: _buildDateRangeChip(),
              ),
            _buildFilterTabs(),
            SizedBox(height: SizeConfig.paddingXSL),
            Expanded(child: Obx(() {
              if (controller.walletReferralHistoryResponse.value.status ==
                  Status.INITIAL) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.walletReferralHistoryResponse.value.status ==
                  Status.ERROR) {
                return Center(
                    child: CustomText(
                  'Oops Something went wrong',
                  fontSize: SizeConfig.extraLarge,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ));
              };

              final rows = _visibleRows;
              if (rows.isEmpty) {
                return EmptyStateWidget(
                  message: _dateRange != null
                      ? 'No referrals in the selected date range.'
                      : 'No ${controller.selectedFilter.value} found.',
                );
              }

              return SingleChildScrollView(
                child: CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  margin:
                      EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: Column(
                    children: [
                      _buildHeaderInfo(rows),
                      ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10.0),
                        itemCount: rows.length,
                        primary: false,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildRefHistoryCard(rows[index]);
                        },
                      ),
                    ],
                  ),
                ),
              );
            })),
          ],
        ));
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar() {
    return CommonBackAppBar(
        title: 'History',
        buildCustomActionWidget: () => Row(
              children: [
                _buildCalendarAction(),
                const SizedBox(width: 8),
                _buildAppbarActionIcon(
                  Icons.ios_share,
                  onTap: _isExporting ? null : _exportToPdf,
                  loading: _isExporting,
                  tooltip: 'Export',
                ),
                const SizedBox(width: 16),
              ],
            ));
  }

  /// Calendar icon that doubles as filter status.
  /// - Inactive → plain outlined calendar, tap opens the date range picker.
  /// - Active  → tinted icon with a red dot badge; tap opens a menu so the
  ///   user can Change Range or Remove the filter from the same control.
  Widget _buildCalendarAction() {
    final active = _dateRange != null;
    final iconBox = _buildAppbarActionIcon(
      active
          ? Icons.event_available_outlined
          : Icons.calendar_today_outlined,
      onTap: active ? null : _pickDateRange,
      tinted: active,
      tooltip: active ? 'Date filter on' : 'Filter by date',
    );
    if (!active) return iconBox;
    return PopupMenuButton<String>(
      tooltip: 'Date filter options',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (value) {
        if (value == 'change') {
          _pickDateRange();
        } else if (value == 'remove') {
          setState(() => _dateRange = null);
          commonSnackBar(message: 'Date filter removed');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'change',
          child: Row(
            children: [
              Icon(Icons.edit_calendar_outlined,
                  size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 10),
              const Text('Change date range'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.filter_alt_off_rounded,
                  size: 18, color: AppColors.red),
              const SizedBox(width: 10),
              Text(
                'Remove filter',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          iconBox,
          // Active indicator dot.
          Positioned(
            right: 2,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppbarActionIcon(IconData icon,
      {VoidCallback? onTap,
      bool tinted = false,
      bool loading = false,
      bool danger = false,
      String? tooltip}) {
    final Color borderColor = danger
        ? AppColors.red
        : tinted
            ? AppColors.primaryColor
            : AppColors.whiteE5;
    final Color bgColor = danger
        ? AppColors.red.withValues(alpha: 0.08)
        : tinted
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.white;
    final Color fgColor = danger
        ? AppColors.red
        : tinted
            ? AppColors.primaryColor
            : AppColors.secondaryTextColor;
    final widget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryColor),
              )
            : Icon(icon, color: fgColor, size: 20),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: widget);
    }
    return widget;
  }

  // --- CALENDAR ACTION ---
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Filter by date range',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _dateRange = picked);
  }

  Widget _buildDateRangeChip() {
    if (_dateRange == null) return const SizedBox.shrink();
    final s = _dateRange!.start;
    final e = _dateRange!.end;
    final label =
        '${s.day}/${s.month}/${s.year}  —  ${e.day}/${e.month}/${e.year}';
    return Padding(
      padding:
          EdgeInsets.only(top: SizeConfig.size4, bottom: SizeConfig.size10),
      child: Row(
        children: [
          // Active-range info pill — tap to re-pick a range.
          Expanded(
            child: Material(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_outlined,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'Date filter',
                              fontSize: SizeConfig.extraSmall,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                            ),
                            CustomText(
                              label,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CustomText(
                        'Tap to change',
                        fontSize: SizeConfig.extraSmall,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dedicated "Clear Filter" button — red, labelled, impossible to miss.
          Material(
            color: AppColors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() => _dateRange = null);
                commonSnackBar(message: 'Date filter cleared');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded,
                        size: 16, color: AppColors.red),
                    const SizedBox(width: 4),
                    CustomText(
                      'Clear',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXPORT PDF ACTION ---
  Future<void> _exportToPdf() async {
    final rows = _visibleRows;
    if (rows.isEmpty) {
      commonSnackBar(message: 'Nothing to export.');
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  CustomText(
                    'Export referral history',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.save_alt, color: AppColors.primaryColor),
              title: const Text('Save to device'),
              subtitle: const Text('Store the PDF in your app files'),
              onTap: () => Navigator.of(ctx).pop('save'),
            ),
            ListTile(
              leading: Icon(Icons.ios_share, color: AppColors.primaryColor),
              title: const Text('Share PDF'),
              subtitle: const Text('Send via WhatsApp, Email, etc.'),
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    setState(() => _isExporting = true);
    try {
      final bytes = await _buildPdfBytes(rows);
      final filename =
          'referral_history_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (choice == 'save') {
        final baseDir = await getApplicationDocumentsDirectory();
        final file = File('${baseDir.path}/$filename');
        await file.writeAsBytes(bytes);
        commonSnackBar(message: 'Saved to ${file.path}');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: filename)],
          subject: 'Referral History',
        );
      }
    } catch (e) {
      commonSnackBar(message: 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<List<int>> _buildPdfBytes(
      List<WalletReferralHistoryData> rows) async {
    final pdf = pw.Document();
    final filterLabel = controller.selectedFilter.value;
    final rangeLabel = _dateRange == null
        ? 'All dates'
        : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year}'
            ' — ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text('Referral History',
              style:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Filter: $filterLabel',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Range: $rangeLabel',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: const [
              'Name',
              'Profession',
              'Status',
              'Earned',
              'Plan',
              'Date',
            ],
            data: rows
                .map((r) => [
                      r.name ?? '-',
                      r.profession ?? '-',
                      r.subscriptionStatus ?? '-',
                      '₹${r.referralIncome ?? 0}',
                      '₹${r.planCost ?? 0}',
                      _formatDateShort(r.createdAt),
                    ])
                .toList(),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  String _formatDateShort(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  // --- FILTER TABS ---
  Widget _buildFilterTabs() {
    return Obx(() {
      final selectedIdx = controller.filters.indexOf(
        controller.selectedFilter.value,
      );
      return HorizontalTabSelector<String>(
        tabs: controller.filters,
        selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
        labelBuilder: (f) => f,
        unSelectedBackgroundColor: Colors.white,
        onTabSelected: (index, label) {
          if (controller.selectedFilter.value == label) return;
          controller.selectedFilter.value = label;
          controller.getWalletReferralHistoryApi(label);
        },
      );
    });
  }

  ({Color bg, Color fg, String label}) _statusStyle(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'subscribed':
        return (
          bg: AppColors.primaryColor.withValues(alpha: 0.10),
          fg: AppColors.primaryColor,
          label: 'Subscribed',
        );
      case 'unsubscribed':
      case 'un-subscribe':
        return (
          bg: AppColors.orange27.withValues(alpha: 0.12),
          fg: AppColors.orange27,
          label: 'Un-subscribed',
        );
      case 'expired':
        return (
          bg: AppColors.red.withValues(alpha: 0.10),
          fg: AppColors.red,
          label: 'Expired',
        );
      default:
        return (
          bg: AppColors.secondaryTextColor.withValues(alpha: 0.10),
          fg: AppColors.secondaryTextColor,
          label: status ?? '—',
        );
    }
  }

  // --- MAIN CONTAINER HEADER ---
  Widget _buildHeaderInfo(List<WalletReferralHistoryData> rows) {
    final isAll = controller.selectedFilter.value == 'All';
    final subscribedCount = isAll
        ? rows
            .where((item) => item.subscriptionStatus == 'subscribed')
            .length
        : rows.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          (controller.selectedFilter.value == 'All' ||
                  controller.selectedFilter.value == 'Subscribe')
              ? "Subscribe User"
              : controller.selectedFilter.value == 'Un-Subscribe'
                  ? "Un-Subscribe User"
                  : "Expired",
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        Row(
          children: [
            Icon(Icons.people_outline,
                color: AppColors.secondaryTextColor, size: 22),
            const SizedBox(width: 4),
            CustomText(
              '$subscribedCount',
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ],
    );
  }

  // --- USER CARD ---
  Widget _buildRefHistoryCard(WalletReferralHistoryData historyData) {
    final style = _statusStyle(historyData.subscriptionStatus);
    final ago = timeAgo(historyData.createdAt);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isGuestUser()) {
            createProfileScreen();
            return;
          }
          chatViewController.checkChatConnectionAndOpenChat(
            userId: historyData.userId ?? '',
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.whiteE5, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage:
                        NetworkImage(historyData.profileImage ?? ''),
                    backgroundColor: AppColors.whiteFE,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          historyData.name ?? '',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          historyData.profession ?? '',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                        return;
                      }
                      chatViewController.checkChatConnectionAndOpenChat(
                        userId: historyData.userId ?? '',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.chat,
                        imgColor: AppColors.primaryColor,
                        height: 16,
                        width: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Left cluster (status pill + time-ago) wrapped in a
                  // single Expanded so it flexes and ellipses — leaving
                  // the income RichText pinned to the right.
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomText(
                            style.label,
                            fontSize: SizeConfig.extraSmall,
                            fontWeight: FontWeight.w600,
                            color: style.fg,
                          ),
                        ),
                        if (ago.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule,
                              size: 12,
                              color: AppColors.secondaryTextColor),
                          const SizedBox(width: 3),
                          Flexible(
                            child: CustomText(
                              ago,
                              fontSize: SizeConfig.extraSmall,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "₹${historyData.referralIncome ?? 0} ",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.small,
                          ),
                        ),
                        TextSpan(
                          text: "/ ₹${historyData.planCost ?? 0}",
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                            fontSize: SizeConfig.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
