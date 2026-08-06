/// Product / category counts for one store, from the bulk counts endpoint.
///
/// These used to ride along on the store listing (`map-service/api/stores`),
/// which meant that endpoint had to fan out over gRPC to the inventory services
/// before it could answer at all — the stores could not be shown until every
/// count had been collected. The counts now come from their own call, so the
/// listing returns as soon as it has stores and the numbers arrive after.
///
/// Nothing here is required to render a store card: a card with no counts yet
/// shows its other content and fills the two figures in when they land.
class StoreCountsModel {
  const StoreCountsModel({
    this.businessId,
    this.userId,
    this.matchedIds = const [],
    this.productCount = 0,
    this.categoryCount = 0,
  });

  /// The business `_id` this row answers for, echoed back from the request.
  final String? businessId;

  /// The owning user's id. Null on a row the server could not resolve a user
  /// for — the request may carry either id, or both.
  final String? userId;

  /// Which of the ids sent actually matched inventory. Empty means the store
  /// has none — which is a real answer (0 products), not a failure.
  final List<String> matchedIds;

  final int productCount;
  final int categoryCount;

  /// Keys this row can be looked up by, so a caller holding either id finds it.
  ///
  /// The store list carries `id` (the business `_id`) and `userId` and the two
  /// are NOT interchangeable — different screens have different ones to hand,
  /// which is why the request sends both and this indexes on both.
  Iterable<String> get lookupKeys => [
        if (businessId?.isNotEmpty == true) businessId!,
        if (userId?.isNotEmpty == true) userId!,
      ];

  factory StoreCountsModel.fromJson(Map<dynamic, dynamic> json) {
    return StoreCountsModel(
      businessId: json['businessId']?.toString(),
      userId: json['userId']?.toString(),
      matchedIds: json['matchedIds'] is List
          ? (json['matchedIds'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      // Tolerates `42`, `42.0` and `"42"` — the serializer on the other side is
      // not pinned, and a count that silently parsed to null would render as a
      // blank where a 0 belongs.
      productCount: _toInt(json['productCount']),
      categoryCount: _toInt(json['categoryCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'userId': userId,
        'matchedIds': matchedIds,
        'productCount': productCount,
        'categoryCount': categoryCount,
      };

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
