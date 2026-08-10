/// Response of `PATCH /api/inventory/stock/flip-out-of-stock`.
///
/// See docs/backend/AUTOMOTIVE_OUT_OF_STOCK_FLIP_FLUTTER_GUIDE.md.
///
/// **Flip is not the same as toggle.** `toggle-out-of-stock` SETS the value you
/// send, driving every listed id to the same state; `flip-out-of-stock` takes no
/// value and inverts each id independently. That's why this response carries a
/// per-item [FlipOutOfStockItem.isOutOfStock] — with flip, the caller cannot
/// know the new value in advance, so it must be read back rather than guessed.
class FlipOutOfStockItem {
  final String inventoryId;

  /// Value BEFORE the flip.
  final bool previous;

  /// Value AFTER the flip — the authoritative one to write into the model.
  final bool isOutOfStock;

  const FlipOutOfStockItem({
    required this.inventoryId,
    required this.previous,
    required this.isOutOfStock,
  });

  /// `== true` rather than a cast throughout: the flag was added after some
  /// inventory documents were written, so it can be absent, and absent is
  /// `false`. A hard `as bool` throws on those older rows.
  factory FlipOutOfStockItem.fromJson(Map<String, dynamic> json) {
    return FlipOutOfStockItem(
      inventoryId: (json['inventoryId'] ?? '').toString(),
      previous: json['previous'] == true,
      isOutOfStock: json['isOutOfStock'] == true,
    );
  }
}

class FlipOutOfStockResponse {
  final String message;
  final int matchedCount;
  final int modifiedCount;

  /// Ids that aren't this business's, or no longer exist. **Arrives with a 200**
  /// — it is not an error status, so it has to be checked explicitly. (Only when
  /// EVERY id is unmatched does the endpoint answer 404.)
  final List<String> notFound;

  final List<FlipOutOfStockItem> items;

  const FlipOutOfStockResponse({
    required this.message,
    required this.matchedCount,
    required this.modifiedCount,
    required this.notFound,
    required this.items,
  });

  factory FlipOutOfStockResponse.fromJson(Map<String, dynamic> json) {
    return FlipOutOfStockResponse(
      message: (json['message'] ?? '').toString(),
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      modifiedCount: (json['modifiedCount'] as num?)?.toInt() ?? 0,
      notFound: ((json['notFound'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => FlipOutOfStockItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Lookup for writing results back into a list without an O(n²) scan.
  Map<String, bool> get byId =>
      {for (final r in items) r.inventoryId: r.isOutOfStock};
}
