import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/profile_share_preview/model/share_profile_overview_response.dart';
import 'package:BlueEra/features/common/profile_share_preview/repo/share_profile_overview_repo.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';

/// Loads what a shared link lands on: a profile overview, a food product or
/// a grocery product. Each returns null when there is nothing to show.
class SharePreviewService {
  SharePreviewService({
    ShareProfileOverviewRepo? profileRepo,
    FoodRepo? foodRepo,
    GroceryRepo? groceryRepo,
  })  : _profileRepo = profileRepo ?? ShareProfileOverviewRepo(),
        _foodRepo = foodRepo ?? FoodRepo(),
        _groceryRepo = groceryRepo ?? GroceryRepo();

  final ShareProfileOverviewRepo _profileRepo;
  final FoodRepo _foodRepo;
  final GroceryRepo _groceryRepo;

  Future<ShareProfileOverviewResponse?> profileOverview(String userId) async {
    final res = await _profileRepo.getShareProfileOverview(userId);
    final data = res.response?.data;
    return res.isSuccess && data is Map<String, dynamic>
        ? ShareProfileOverviewResponse.fromJson(data)
        : null;
  }

  Future<CategoryFoodProductData?> foodProduct(String foodId) async {
    final payload = _product(
        await _foodRepo.fetchSingleFoodProductDetailsRepo(foodID: foodId));
    return payload == null ? null : CategoryFoodProductData.fromJson(payload);
  }

  Future<GroceryProductData?> groceryProduct(String productId) async {
    final payload =
        _product(await _groceryRepo.fetchGroceryProductByIdRepo(productId));
    return payload == null ? null : GroceryProductData.fromJson(payload);
  }

  /// The product endpoints return either the bare product object or a
  /// `{ data: {...} }` envelope. Handle both so the deep-link landing doesn't
  /// break if the backend shape evolves.
  static Map<String, dynamic>? _product(ResponseModel res) {
    if (!res.isSuccess) return null;
    final raw = res.response?.data;
    if (raw is! Map<String, dynamic>) return null;
    final inner = raw['data'];
    return inner is Map<String, dynamic> ? inner : raw;
  }
}
