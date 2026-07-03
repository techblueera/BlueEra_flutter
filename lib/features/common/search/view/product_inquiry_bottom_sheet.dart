import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Flipkart-style product enquiry bottom sheet.
///
/// Opened when a user taps a *product* result card in global search. It shows a
/// rich product snapshot (photo, name, pricing, discount, highlights, selectable
/// variants) followed by a "Sellers near me" list. Each seller can be ticked and
/// the user fires a single "Send Inquiry" to every selected seller.
///
/// Design-only for now: pricing/rating are seeded from the tapped
/// [SearchResultItem] when present, while highlights, variants and the seller
/// list are illustrative. Nothing is persisted or sent to the backend beyond a
/// confirmation snackbar.
void showProductInquiryBottomSheet(BuildContext context, SearchResultItem item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProductInquirySheet(item: item),
  );
}

// ── Dummy variant / seller models (design-only stand-ins) ─────────────────
class _Variant {
  final String label;
  const _Variant(this.label);
}

class _VariantGroup {
  final String title;
  final List<_Variant> options;
  const _VariantGroup(this.title, this.options);
}

class _NearbySeller {
  final String name;
  final String designation; // subcategory / designation line
  final String distance;
  final String? dpUrl;
  const _NearbySeller({
    required this.name,
    required this.designation,
    required this.distance,
    this.dpUrl,
  });
}

class _ProductInquirySheet extends StatefulWidget {
  final SearchResultItem item;

  const _ProductInquirySheet({required this.item});

  @override
  State<_ProductInquirySheet> createState() => _ProductInquirySheetState();
}

class _ProductInquirySheetState extends State<_ProductInquirySheet> {
  // Selected option index per variant group.
  final Map<int, int> _selectedVariant = {};

  // Which nearby sellers are ticked for the inquiry.
  final Set<int> _selectedSellers = {};

  // ── Design-only sample data ─────────────────────────────────────────────
  static const List<_VariantGroup> _variantGroups = [
    _VariantGroup('Color', [
      _Variant('Midnight Black'),
      _Variant('Ocean Blue'),
      _Variant('Silver'),
    ]),
    _VariantGroup('Storage', [
      _Variant('128 GB'),
      _Variant('256 GB'),
      _Variant('512 GB'),
    ]),
  ];

  static const List<String> _highlights = [
    '6.7" Full HD+ AMOLED 120Hz display',
    'Snapdragon 8 Gen 3 · 12 GB RAM',
    '50 MP OIS triple camera setup',
    '5000 mAh battery with 67W fast charging',
    '1 year manufacturer warranty',
  ];

  static const List<_NearbySeller> _sellers = [
    _NearbySeller(
      name: 'Sharma Electronics',
      designation: 'Mobile & Accessories · Retailer',
      distance: '1.2 km',
    ),
    _NearbySeller(
      name: 'Gadget World',
      designation: 'Consumer Electronics · Dealer',
      distance: '2.8 km',
    ),
    _NearbySeller(
      name: 'Apna Mobile Store',
      designation: 'Smartphones · Authorised Reseller',
      distance: '4.5 km',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Preselect the first option of every variant group, like a PDP would.
    for (var i = 0; i < _variantGroups.length; i++) {
      _selectedVariant[i] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabHandle(),
          _sheetHeader(),
          const Divider(height: 1, color: AppColors.greyE5),
          Flexible(
            child: ListView(
              padding: EdgeInsets.only(bottom: SizeConfig.size16),
              children: [
                _productHero(green),
                _sectionDivider(),
                _variantsSection(),
                _sectionDivider(),
                _highlightsSection(),
                _sectionDivider(),
                _sellersSection(),
              ],
            ),
          ),
          _sendInquiryBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _grabHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.greyE5,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, 10, SizeConfig.size8, 10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              'Product Details',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 22, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Product hero: photo, name, rating, pricing, discount ─────────────────
  Widget _productHero(Color green) {
    final item = widget.item;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size16, SizeConfig.size16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroImage(item.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.title.isNotEmpty ? item.title : 'Product name',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null && item.subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    'in ${item.subtitle!.trim()}',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _ratingBadge(green),
                const SizedBox(height: 10),
                _priceRow(green),
                const SizedBox(height: 4),
                _bankOfferRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImage(String? url) {
    final placeholder = Container(
      width: 110,
      height: 140,
      color: AppColors.whiteF9,
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined,
          color: AppColors.secondaryTextColor, size: 34),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                width: 110,
                height: 140,
                fit: BoxFit.contain,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              )
            : placeholder,
      ),
    );
  }

  Widget _ratingBadge(Color green) {
    final item = widget.item;
    final rating = item.rating ?? 4.4;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(rating.toStringAsFixed(1),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white),
              const SizedBox(width: 2),
              const Icon(Icons.star, size: 12, color: AppColors.white),
            ],
          ),
        ),
        const SizedBox(width: 6),
        CustomText('(${item.ratingCount ?? 2318})',
            fontSize: SizeConfig.small, color: AppColors.secondaryTextColor),
        const SizedBox(width: 8),
        Icon(Icons.verified, size: 16, color: AppColors.blue5CAF),
        const SizedBox(width: 2),
        CustomText('Assured',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.blue5CAF),
      ],
    );
  }

  Widget _priceRow(Color green) {
    final item = widget.item;
    final price = item.price != null
        ? '₹${SearchResponse.formatPrice(item.price)}'
        : '₹19,999';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (item.hasDiscount) ...[
          Icon(Icons.arrow_downward, size: 14, color: green),
          CustomText('${item.discountPercent}%',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: green),
          const SizedBox(width: 6),
          CustomText('₹${SearchResponse.formatPrice(item.mrp)}',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              decoration: TextDecoration.lineThrough),
          const SizedBox(width: 6),
        ] else if (item.price == null) ...[
          Icon(Icons.arrow_downward, size: 14, color: green),
          CustomText('37%',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: green),
          const SizedBox(width: 6),
          CustomText('₹31,999',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              decoration: TextDecoration.lineThrough),
          const SizedBox(width: 6),
        ],
        CustomText(price,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      ],
    );
  }

  Widget _bankOfferRow() {
    final item = widget.item;
    final offer = item.offerPrice != null
        ? '₹${SearchResponse.formatPrice(item.offerPrice)} with Bank offer'
        : '₹18,499 with Bank offer';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.blue5CAF,
            borderRadius: BorderRadius.circular(3),
          ),
          child: CustomText('WOW!',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w800,
              color: AppColors.white),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: CustomText(offer,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.blue5CAF,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── Variants ─────────────────────────────────────────────────────────────
  Widget _variantsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var g = 0; g < _variantGroups.length; g++) ...[
            if (g > 0) const SizedBox(height: 14),
            _variantGroupTitle(_variantGroups[g].title, g),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var o = 0; o < _variantGroups[g].options.length; o++)
                  _variantChip(g, o, _variantGroups[g].options[o].label),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _variantGroupTitle(String title, int groupIndex) {
    final selected = _variantGroups[groupIndex].options[_selectedVariant[groupIndex]!];
    return Row(
      children: [
        CustomText('$title: ',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
        Flexible(
          child: CustomText(selected.label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _variantChip(int group, int option, String label) {
    final isSelected = _selectedVariant[group] == option;
    return GestureDetector(
      onTap: () => setState(() => _selectedVariant[group] = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue5CAF.withValues(alpha: 0.08)
              : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.blue5CAF : AppColors.greyE5,
            width: isSelected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.blue5CAF : AppColors.mainTextColor,
        ),
      ),
    );
  }

  // ── Highlights ───────────────────────────────────────────────────────────
  Widget _highlightsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('Highlights',
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          const SizedBox(height: 10),
          for (final h in _highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomText(
                      h,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Sellers near me ──────────────────────────────────────────────────────
  Widget _sellersSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size12, SizeConfig.size16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 20, color: AppColors.mainTextColor),
              const SizedBox(width: 6),
              CustomText('Sellers near me',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor),
            ],
          ),
          const SizedBox(height: 4),
          CustomText('Select sellers to send your inquiry',
              fontSize: SizeConfig.small, color: AppColors.secondaryTextColor),
          const SizedBox(height: 12),
          for (var i = 0; i < _sellers.length; i++) _sellerCard(i, _sellers[i]),
        ],
      ),
    );
  }

  Widget _sellerCard(int index, _NearbySeller seller) {
    final isSelected = _selectedSellers.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedSellers.remove(index);
        } else {
          _selectedSellers.add(index);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue5CAF.withValues(alpha: 0.05)
              : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.blue5CAF : AppColors.greyE5,
            width: isSelected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _sellerDp(seller.dpUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(seller.name,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  CustomText(seller.designation,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.blue5CAF),
                      const SizedBox(width: 2),
                      CustomText('${seller.distance} away',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue5CAF),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _checkbox(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _sellerDp(String? url) {
    final placeholder = Container(
      width: 48,
      height: 48,
      color: AppColors.greyE5,
      alignment: Alignment.center,
      child: const Icon(Icons.store_mall_directory_outlined,
          size: 24, color: AppColors.secondaryTextColor),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }

  Widget _checkbox(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue5CAF : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.blue5CAF : AppColors.greyE5,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check, size: 15, color: AppColors.white)
          : const SizedBox.shrink(),
    );
  }

  // ── Send inquiry bar ─────────────────────────────────────────────────────
  Widget _sendInquiryBar() {
    final count = _selectedSellers.length;
    final enabled = count > 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.greyE5)),
        ),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? _onSendInquiry : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue5CAF,
              disabledBackgroundColor: AppColors.greyE5,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: CustomText(
              enabled ? 'Send Inquiry ($count)' : 'Send Inquiry',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: enabled ? AppColors.white : AppColors.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  void _onSendInquiry() {
    final names =
        _selectedSellers.map((i) => _sellers[i].name).toList(growable: false);
    Navigator.of(context).maybePop();
    commonSnackBar(
      message: 'Inquiry sent to ${names.length} seller'
          '${names.length == 1 ? '' : 's'}: ${names.join(', ')}',
    );
  }

  // ── Shared bits ──────────────────────────────────────────────────────────
  Widget _sectionDivider() =>
      Container(height: 8, color: AppColors.whiteF4);
}
