import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';

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
/*
final List<BusinessCategory> typeOfBusinessList = [
  BusinessCategory(
    title: "Grocery, Vegetables & Dairy",
    subTitle: "Daily Essentials, Fresh Vegetables, Fruits, Milk & Dairy Products",
    icon: AppIconAssets.groceryIcon, // Ensure these assets exist
    type: BusinessType.Grocery.name,
  ),
  BusinessCategory(
    title: "Food & Restaurants",
    subTitle: "Dine-in, Cafes, Quick Service Restaurants, Sweet Shops & Bakeries",
    icon: AppIconAssets.rentalServiceIcon,
    type: BusinessType.Food.name,
  ),
  BusinessCategory(
    title: "Stores / Shops (Retail)",
    subTitle: "Clothes, Electronics, Toys, Beauty Products & General Retail Stores",
    icon: AppIconAssets.product_sale,
    type: BusinessType.Product.name,
  ),
  BusinessCategory(
    title: "Healthcare Sector",
    subTitle: "Hospitals, Clinics, Pharmacies, Diagnostic Labs & Medical Stores",
    icon: AppIconAssets.homeServiceIcon,
    type: BusinessType.Healthcare.name,
  ),
  BusinessCategory(
    title: "Education Sector",
    subTitle: "Schools, Coaching Centers, Libraries, Stationery & Training Institutes",
    icon: AppIconAssets.education,
    type: BusinessType.Siksha.name,
  ),
  BusinessCategory(
    title: "Hotel & Stay",
    subTitle: "Hotels, Resorts, Guesthouses, Hostels & Homestay Services",
    icon: AppIconAssets.homeStayIcon,
    type: BusinessType.Motel.name,
  ),
  BusinessCategory(
    title: "Service Businesses",
    subTitle: "Consultants, Salon, Laundry, Repair Services & Professional Agencies",
    icon: AppIconAssets.service_provider,
    type: BusinessType.Service.name,
  ),
  BusinessCategory(
    title: "Manufacturing Units",
    subTitle: "Factories, Industries, Production Plants & Product Creation Units",
    icon: AppIconAssets.other_type,
    type: BusinessType.Manufacturing.name,
  ),
];*/



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
