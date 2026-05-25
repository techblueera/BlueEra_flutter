import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/testimonial_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllTestimonialsScreen extends StatefulWidget {
  final ReferralController controller;
  const AllTestimonialsScreen({super.key, required this.controller});

  @override
  State<AllTestimonialsScreen> createState() => _AllTestimonialsScreenState();
}

class _AllTestimonialsScreenState extends State<AllTestimonialsScreen> {
  static const int _pageSize = 6;
  int _page = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.testimonials.isEmpty) {
      widget.controller.fetchTestimonials();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _total => widget.controller.testimonials.length;
  int get _pageCount => (_total / _pageSize).ceil().clamp(1, 9999);

  void _go(int page) {
    final clamped = page.clamp(0, _pageCount - 1);
    if (clamped == _page) return;
    setState(() => _page = clamped);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: 'All Testimonials',
        isShadowShow: false,
      ),
      body: Obx(() {
        final status = widget.controller.testimonialsResponse.value.status;
        if (status == Status.LOADING || status == Status.INITIAL) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.controller.testimonials.isEmpty) {
          return _empty();
        }
        final start = _page * _pageSize;
        final end = (start + _pageSize) > _total ? _total : start + _pageSize;
        final pageItems =
            widget.controller.testimonials.sublist(start, end).toList();
        return Column(
          children: [
            _summaryStrip(start, end),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size12,
                  SizeConfig.size10,
                  SizeConfig.size12,
                  SizeConfig.size10,
                ),
                itemCount: pageItems.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: SizeConfig.size10),
                itemBuilder: (_, i) => TestimonialCard(
                  testimonial: pageItems[i],
                  expanded: true,
                ),
              ),
            ),
            _pager(),
          ],
        );
      }),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_quote_rounded,
                size: 56, color: AppColors.primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            CustomText(
              'No testimonials yet',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 4),
            CustomText(
              'Check back later — new stories from BlueEra Assistants land here.',
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStrip(int start, int end) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size8,
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt_rounded,
              size: 16, color: AppColors.secondaryTextColor),
          const SizedBox(width: 6),
          CustomText(
            'Showing ${start + 1}–$end of $_total',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
          const Spacer(),
          CustomText(
            'Page ${_page + 1} / $_pageCount',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _pager() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size10,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrow(
              icon: Icons.chevron_left_rounded,
              enabled: _page > 0,
              onTap: () => _go(_page - 1),
            ),
            const SizedBox(width: 8),
            ..._buildNumberButtons(),
            const SizedBox(width: 8),
            _arrow(
              icon: Icons.chevron_right_rounded,
              enabled: _page < _pageCount - 1,
              onTap: () => _go(_page + 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Up to 5 numbered buttons centered around the current page, with
  /// "…" placeholders when the range is far from either edge. Standard
  /// pagination ergonomics.
  List<Widget> _buildNumberButtons() {
    const window = 5;
    if (_pageCount <= window) {
      return [for (int i = 0; i < _pageCount; i++) _numberButton(i)];
    }
    int start = (_page - window ~/ 2).clamp(0, _pageCount - window);
    int end = start + window;
    final widgets = <Widget>[];
    if (start > 0) {
      widgets.add(_numberButton(0));
      if (start > 1) widgets.add(_ellipsis());
    }
    for (int i = start; i < end; i++) {
      widgets.add(_numberButton(i));
    }
    if (end < _pageCount) {
      if (end < _pageCount - 1) widgets.add(_ellipsis());
      widgets.add(_numberButton(_pageCount - 1));
    }
    return widgets;
  }

  Widget _numberButton(int index) {
    final selected = index == _page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _go(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: CustomText(
            '${index + 1}',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CustomText(
        '…',
        fontSize: SizeConfig.medium,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _arrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : AppColors.whiteE5.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withValues(alpha: 0.3)
                : AppColors.whiteE5,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.primaryColor
              : AppColors.secondaryTextColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
