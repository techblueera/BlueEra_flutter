import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class YourCartScreen extends StatelessWidget {
  const YourCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          'Your Cart',
          fontSize: SizeConfig.extraLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryTextColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(width: 4),
                  CustomText(
                    'Address',
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _CartCard(
              title: 'Self Pick-Up',
              subtitle: '5 Shops - 50 Items',
              bgColor: const Color(0xFFFFF8E1),
              iconWidget: Image.asset(
                'assets/icons/self_pickup_icon.png',
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0B3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFFE6A800), size: 24),
                ),
              ),
              payPrice: '₹1,499',
              payOriginalPrice: '₹98,000',
              savePrice: '₹1,499',
              discountPercent: '50% Off',
            ),
            const SizedBox(height: 12),
            _CartCard(
              title: 'Book Rider',
              subtitle: '100 Items',
              bgColor: const Color(0xFFE3F2FD),
              iconWidget: Image.asset(
                'assets/icons/book_rider_icon.png',
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delivery_dining,
                      color: Color(0xFF1565C0), size: 24),
                ),
              ),
              payPrice: '₹1,499',
              payOriginalPrice: '₹98,000',
              savePrice: '₹1,499',
              discountPercent: '50% Off',
            ),
            const SizedBox(height: 12),
            _CartCard(
              title: 'Order Via Partner',
              subtitle: '100 Items',
              bgColor: const Color(0xFFFFF3E0),
              iconWidget: Image.asset(
                'assets/icons/order_partner_icon.png',
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping_outlined,
                      color: Color(0xFFE65100), size: 24),
                ),
              ),
              payPrice: '₹1,499',
              payOriginalPrice: '₹98,000',
              savePrice: '₹1,499',
              discountPercent: '50% Off',
            ),
          ],
        ),
      ),
    );
  }
}

class _CartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bgColor;
  final Widget iconWidget;
  final String payPrice;
  final String payOriginalPrice;
  final String savePrice;
  final String discountPercent;

  const _CartCard({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.iconWidget,
    required this.payPrice,
    required this.payOriginalPrice,
    required this.savePrice,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          /// Top row: icon + title + View button
          Row(
            children: [
              iconWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              _viewButton(),
            ],
          ),
          const SizedBox(height: 14),

          /// Pay and Save buttons row
          Row(
            children: [
              /// Pay section
              Expanded(
                child: Column(
                  children: [
                    _actionButton('Pay'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          payPrice,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                          payOriginalPrice,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              /// Save section
              Expanded(
                child: Column(
                  children: [
                    _actionButton('Save'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          savePrice,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(width: 6),
                        _discountBadge(discountPercent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green1A, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        'View',
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.green1A,
      ),
    );
  }

  Widget _actionButton(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primaryColor, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: CustomText(
        label,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _discountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: AppColors.green1A),
          const SizedBox(width: 3),
          CustomText(
            text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.green1A,
          ),
        ],
      ),
    );
  }
}
