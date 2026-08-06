import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';

class StoreRepo extends BaseService {
  ///GET STORE......
  Future<ResponseModel> getStore({required int page, required String? lat, String? long}) async {
    int limit = 40;
    String? url = getStoreListing;
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      url = "$getStoreListing?page=$page&limit=$limit&lat=$lat&lng=$long&radius=$kmRadius1000";
    } else {
      url = "$getStoreListing?page=$page&limit=$limit&radius=$kmRadius1000";
    }
    final response = await ApiBaseHelper().getHTTP(
      url,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// SEARCH STORES
  Future<ResponseModel> searchStores({required String query}) async {
    String url = "$getStoreListing?radius=$kmRadius1000&query=$query";
    final response = await ApiBaseHelper().getHTTP(
      url,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// homePageProduct
  Future<ResponseModel> homePageProductRepo({
    required Map<String, dynamic> queryParams
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      homePageProduct,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }


  ///GET STORE FEED(PRODUCTS, SERVICE , STORES)......
  Future<ResponseModel> getAllStoresFeed({required int page, String? lat, String? long}) async {
    Map<String, dynamic> queryParams = {};
    if ((lat?.isNotEmpty ?? false) && (long?.isNotEmpty ?? false)) {
      queryParams = {
        'lat': lat,
        'lng': long,
      };
    }
    queryParams['radius'] = kmRadius1000;
    queryParams['page'] = page;

    final response = await ApiBaseHelper().getHTTP(
      storesFeed,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// productSearchFilterRepo
  Future<ResponseModel> productSearchFilterRepo({
   required Map<String, dynamic> queryParams
  }) async {

    final response = await ApiBaseHelper().getHTTP(
      productSearchFilter,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

  ///SEARCH SERVICE BUSINESS PROFILES (other-service/business-profile/search)
  Future<ResponseModel> searchServiceBusinessProfiles({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      otherBusinessProfileSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET SPECIFIC STORES......
  ///
  /// `GET user-service/business/search` — the near-by store list for every
  /// store screen (grocery / food / product / …). Filters are `typeOfBusiness`,
  /// `category`, `subCategory` and `radius`, paged with `page` / `limit` and
  /// centred on `lat` / `lng`.
  ///
  /// Replaces `map-service/api/stores`, which took a differently-spelled set of
  /// filters (`type`, `category_id`) — passing the old keys here silently
  /// returns an unfiltered list rather than an error, so the params are built
  /// from [ApiKeys.typeOfBusiness] / [ApiKeys.category], not [ApiKeys.type] /
  /// [ApiKeys.category_id].
  Future<ResponseModel> getSpecificStores({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Product / category counts for a batch of stores.
  ///
  /// [businesses] is one entry per store, each carrying `businessId`, `userId`,
  /// or both — the server matches on whichever it is given, which is why the
  /// caller sends both when it has them.
  ///
  /// [path] is the catalogue this asks: [groceryBusinessProductStats],
  /// [foodBusinessProductStats] or [productBusinessProductStats]. It is a
  /// parameter rather than a fixed constant because the same store list screen
  /// backs grocery, food and product, and each has its own catalogue — asking
  /// grocery for a restaurant's numbers returns a clean, wrong `0`.
  ///
  /// `showProgress: false`: this runs BEHIND an already-rendered store list. A
  /// blocking spinner over a screen the user is reading would be worse than the
  /// two counts arriving a moment late, which is the whole point of splitting
  /// this off the listing.
  Future<ResponseModel> getStoreCountsRepo({
    required String path,
    required List<Map<String, String>> businesses,
  }) async {
    return ApiBaseHelper().postHTTP(
      path,
      showProgress: false,
      params: {'businesses': businesses},
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  ///GET SPECIFIC STORES......
  Future<ResponseModel> askAiInventoryRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      aiInventoryAsk,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Product Category Tree
  Future<ResponseModel> getProductCategoryTree({required String group}) async {
    final response = await ApiBaseHelper().getHTTP(
      "$productCategoryTree?group=$group",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Product Filter
  Future<ResponseModel> productFilterRepo({
    required Map<String, dynamic> queryParams
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      productFilter,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }


}
