import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';

/// Static category data for the redesigned Discover landing page.
///
/// The illustrated icons already ship in the asset bundle (see
/// [AppImageAssets] / [OnboardingBusinessAssets]). `slugId`s reuse the
/// existing service slugs so taps can route into the current grocery / food
/// flows unchanged.

final List<CollapsibleGridModel> discoverGroceryCategories = [
  CollapsibleGridModel(
    name: 'Kirana Store',
    slugId: 'KIRANA_STORE',
    icon: AppImageAssets.kiranaStore,
  ),
  CollapsibleGridModel(
    name: 'General Store',
    slugId: 'GENERAL_STORE',
    icon: AppImageAssets.generalStore,
  ),
  CollapsibleGridModel(
    name: 'Vegetable & Fruits',
    slugId: 'VEG_FRUITS',
    icon: AppImageAssets.vegFruitStore,
  ),
  CollapsibleGridModel(
    name: 'Dairy & Bakery',
    slugId: 'DAIRY_BAKERY',
    icon: AppImageAssets.dairyBakeryStore,
  ),
  CollapsibleGridModel(
    name: 'Home Essentials',
    slugId: 'HOME_ESSENTIALS',
    icon: AppImageAssets.homeEssentialsStore,
  ),
];

final List<CollapsibleGridModel> discoverFoodCategories = [
  CollapsibleGridModel(
    name: 'Multicuisine Restaurant',
    slugId: 'MULTICUISINE',
    icon: OnboardingBusinessAssets.multicuisineRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Pure - Veg Restaurant',
    slugId: 'PURE_VEG',
    icon: OnboardingBusinessAssets.pureVegRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Non-Veg Restaurant',
    slugId: 'NON_VEG',
    icon: OnboardingBusinessAssets.nonVegRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Economy Dhaba',
    slugId: 'ECONOMY_DHABA',
    icon: OnboardingBusinessAssets.economyDhaba,
  ),
  CollapsibleGridModel(
    name: 'Garden/ Buffet Restaurant',
    slugId: 'GARDEN_BUFFET',
    icon: OnboardingBusinessAssets.gardenBuffetRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Cloud Kitchen',
    slugId: 'CLOUD_KITCHEN',
    icon: OnboardingBusinessAssets.cloudKitchenMess,
  ),
  CollapsibleGridModel(
    name: 'Breakfast / Fast-food',
    slugId: 'BREAKFAST_FASTFOOD',
    icon: OnboardingBusinessAssets.breakfastFastFood,
  ),
  CollapsibleGridModel(
    name: 'Sweet & Namkeen',
    slugId: 'SWEET_NAMKEEN',
    icon: OnboardingBusinessAssets.sweetNamkeenShop,
  ),
  CollapsibleGridModel(
    name: 'Ice Cream Corner',
    slugId: 'ICE_CREAM',
    icon: OnboardingBusinessAssets.iceCreamCorner,
  ),
  CollapsibleGridModel(
    name: 'Coffee & Braverages',
    slugId: 'COFFEE_BEVERAGES',
    icon: OnboardingBusinessAssets.coffeeBeveragesShop,
  ),
];

/// Top quick-access tabs shown under the location bar.
const List<Map<String, String>> discoverQuickAccessTabs = [
  {'title': 'Quick\nAccess', 'icon': AppImageAssets.overviewDiscover},
  {'title': 'Grocery &\nFood', 'icon': AppImageAssets.groceryItemsDiscover},
  {'title': 'Travel &\nBooking', 'icon': AppImageAssets.bookingDiscover},
  {'title': 'Shopping\n& Sell', 'icon': AppImageAssets.shoppingDiscover},
  {'title': 'Services &\nProfessional', 'icon': AppImageAssets.servicesDiscover},
  {'title': 'Jobs &\nOther', 'icon': AppImageAssets.professionalDiscover},
];
