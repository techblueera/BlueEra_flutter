import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:flutter/material.dart';

class BusinessCategory {
  final String title;
  final String subTitle;
  final String icon;

  BusinessCategory({
    required this.title,
    required this.subTitle,
    required this.icon,
  });
}
final List<BusinessCategory> typeOfBusinessList = [
  BusinessCategory(
    title: "Grocerie /Food /Restaurant/Beverage",
    subTitle:
    "All Kind of Cooking/Eatable Shops/Stall/Dairy\nRestaurants, Sweet Shops, Tea Stalls, Juice Centers",
    icon: AppIconAssets.food_service,
  ),
  BusinessCategory(
    title: "Product Sales: Shop/Store/Showroom",
    subTitle:
    "(e.g., Clothes, Electronics, Pharmacy, Toy, Beauty product)",
    icon: AppIconAssets.product_sale,
  ),
  BusinessCategory(
    title: "Service Provider: Education/Hospital/Hotel etc.",
    subTitle: "(Consulting Farm, Doctors, All Service providers)",
    icon: AppIconAssets.service_provider,
  ),
  BusinessCategory(
    title: "Others: Manufacturing Unit/Industry/Factory",
    subTitle:
    "If Your Business Is related to Manufacturing / create products Or other activity",
    icon:AppIconAssets.other_type, // (requires Flutter 3.7+, else use Icons.work)
  ),
];
