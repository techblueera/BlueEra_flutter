import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:flutter/material.dart';

class BusinessCategory {
  final String type;
  final String title;
  final String subTitle;
  final String icon;

  BusinessCategory({
    required this.type,
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
    type: BusinessType.Food.name,
  ),
  BusinessCategory(
    title: "Product Sales: Shop/Store/Showroom",
    subTitle: "(e.g., Clothes, Electronics, Pharmacy, Toy, Beauty product)",
    icon: AppIconAssets.product_sale,
    type: BusinessType.Product.name,
  ),
  BusinessCategory(
    title: "Service Provider: Education/Hospital/Hotel etc.",
    subTitle: "(Consulting Farm, Doctors, All Service providers)",
    icon: AppIconAssets.service_provider,
    type: BusinessType.Service.name,
  ),
  BusinessCategory(
    title: "Others: Manufacturing Unit/Industry/Factory",
    subTitle:
        "If Your Business Is related to Manufacturing / create products Or other activity",
    icon: AppIconAssets.other_type,
    type: BusinessType
        .Both.name, // (requires Flutter 3.7+, else use Icons.work)
  ),
];
