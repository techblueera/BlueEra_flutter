import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SymbolRepo extends BaseService {
  Future<ResponseModel> fetchSymbolFeed({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
        symbolFeedApi,
        params: params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createSymbol(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        createSymbolApi,
        showProgress: true,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getAllSymbolsSingleUser(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        getAllSymbolOneUser(id),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> deleteSymbol(String sumbolId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        deleteSymbolApi(sumbolId),
        showProgress: true,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Mark a symbol as viewed
  Future<ResponseModel> markSymbolViewed(String symbolId) async {
    final response = await ApiBaseHelper().postHTTP(
        symbolViewApi(symbolId),
        showProgress: false,
        params: {},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Like a symbol
  Future<ResponseModel> likeSymbol(String symbolId) async {
    final response = await ApiBaseHelper().postHTTP(
        symbolLikeApi(symbolId),
        showProgress: false,
        params: {},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Unlike a symbol
  Future<ResponseModel> unlikeSymbol(String symbolId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        symbolLikeApi(symbolId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Get comments for a symbol
  Future<ResponseModel> getComments(String symbolId) async {
    final response = await ApiBaseHelper().getHTTP(
        symbolGetCommentsApi(symbolId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Add a comment to a symbol
  Future<ResponseModel> addComment(String symbolId, String comment) async {
    final response = await ApiBaseHelper().postHTTP(
        symbolAddCommentApi(symbolId),
        showProgress: false,
        params: {'comment': comment},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Edit own comment
  Future<ResponseModel> editComment(String commentId, String comment) async {
    final response = await ApiBaseHelper().putHTTP(
        symbolEditCommentApi(commentId),
        showProgress: false,
        params: {'comment': comment},
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Delete own comment
  Future<ResponseModel> deleteComment(String commentId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        symbolDeleteCommentApi(commentId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getSymbolLikes(String symbolId) async {
    final response = await ApiBaseHelper().getHTTP(
        symbolGetLikesApi(symbolId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getSymbolViews(String symbolId) async {
    final response = await ApiBaseHelper().getHTTP(
        symbolGetViewsApi(symbolId),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
