/// All `symbols-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin SymbolsServiceApi {
  final String createSymbolApi = 'symbols-service/symbols';
  final String symbolFeedApi = 'symbols-service/symbols/feed';
  String getAllSymbolOneUser(String orderId) =>
      "symbols-service/symbols/user/$orderId";
  String deleteSymbolApi(String symbolId) =>
      "symbols-service/symbols/$symbolId";
  String symbolViewApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/view";
  String symbolLikeApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/like";
  String symbolAddCommentApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/comment";
  String symbolGetCommentsApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/comments";
  String symbolEditCommentApi(String commentId) =>
      "symbols-service/symbols/comment/$commentId";
  String symbolDeleteCommentApi(String commentId) =>
      "symbols-service/symbols/comment/$commentId";
  String symbolGetLikesApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/likes";
  String symbolGetViewsApi(String symbolId) =>
      "symbols-service/symbols/$symbolId/views";
}
