import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/grocery_order_msg_card.dart';

/// **C12 — the same order card must appear once.**
///
/// Two things put a duplicate in a thread, and neither is under the app's
/// control: the order service can create the same order twice (the duplicate
/// order bug in the audit), and a socket replay after a reconnect can deliver
/// a card the history fetch already provided.
///
/// The rule from `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §3 is exact:
/// *de-duplicate by `metadata.order` id, keep the newest `created_at`*.
///
/// This is a **render-time filter**, deliberately. The underlying list is the
/// conversation's own history and is written to from four places (the socket,
/// the paginated fetch, the Hive cache, the outgoing send echo); quietly
/// deleting rows out of it would make one of those four disagree with what is
/// on screen. Filtering on the way to the ListView shows one card and leaves
/// the history intact.
///
/// Everything that is not an order card passes through untouched and in its
/// original order — this is not a general-purpose dedupe.
class OrderCardDedupe {
  const OrderCardDedupe._();

  /// Message types whose cards are keyed by an order id.
  static const Set<String> _orderTypes = {
    'grocery_order',
    'selfpickup',
    'food_selfpickup',
    'homemade_food_selfpickup',
    'tiffin_selfpickup',
    'product_selfpickup',
    'medical_selfpickup',
  };

  static bool _isOrderCard(Messages m) =>
      _orderTypes.contains(m.messageType ?? '');

  /// The order id a card is keyed by, or `''` when it has none — an orphan
  /// card is never deduped against another orphan, because they may well be
  /// two different orders that both lost their id.
  static String orderKeyOf(Messages m) {
    final id = GroceryOrderMsgCard.orderIdOf(m);
    return id;
  }

  static DateTime _createdAt(Messages m) {
    final raw = m.createdAt ?? '';
    if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Returns [messages] with duplicate order cards collapsed to the newest one
  /// per order id, every other message untouched, and the original ordering
  /// preserved.
  ///
  /// The surviving card keeps the **position** of the newest occurrence, so a
  /// card does not jump up the thread when an older duplicate is dropped.
  static List<Messages> apply(List<Messages> messages) {
    if (messages.length < 2) return messages;

    // First pass: find the winner per order id. Nothing is allocated unless
    // there is actually a duplicate to resolve.
    Map<String, Messages>? winners;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (!_isOrderCard(m)) continue;
      final key = orderKeyOf(m);
      if (key.isEmpty) continue;

      winners ??= <String, Messages>{};
      final held = winners[key];
      if (held == null) {
        winners[key] = m;
      } else if (!_createdAt(m).isBefore(_createdAt(held))) {
        // `!isBefore` rather than `isAfter`: two cards written in the same
        // millisecond keep the later one in the list, which is the one the
        // most recent write produced.
        winners[key] = m;
      }
    }
    if (winners == null || winners.isEmpty) return messages;

    // Nothing to drop unless some id was seen more than once.
    var duplicates = 0;
    for (final m in messages) {
      if (!_isOrderCard(m)) continue;
      final key = orderKeyOf(m);
      if (key.isEmpty) continue;
      if (!identical(winners[key], m)) duplicates++;
    }
    if (duplicates == 0) return messages;

    final out = <Messages>[];
    for (final m in messages) {
      if (!_isOrderCard(m)) {
        out.add(m);
        continue;
      }
      final key = orderKeyOf(m);
      if (key.isEmpty || identical(winners[key], m)) out.add(m);
    }
    return out;
  }
}
