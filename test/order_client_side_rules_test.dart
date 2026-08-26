import 'dart:io';

import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three ORDER cards. The rider cards are deliberately excluded — their
/// 24-hour greying is display hygiene on a tracking card, not an order
/// business rule, and the guide says to leave it alone.
const _orderCards = [
  'lib/features/chat/view/business_chat/widgets/product_self_pickup_msg_card.dart',
  'lib/features/chat/view/business_chat/widgets/self_pickup_msg_card.dart',
  'lib/features/chat/view/business_chat/widgets/food_self_pickup_msg_card.dart',
];

const _riderCards = [
  'lib/features/chat/view/business_chat/widgets/rider_details_msg_card.dart',
  'lib/features/chat/view/business_chat/widgets/rider_live_location_msg_card.dart',
];

void main() {
  group('no client-side order rules survive', () {
    test('the three order cards contain no 24-hour expiry', () {
      for (final path in _orderCards) {
        final source = File(path).readAsStringSync();
        // Strip comments so the doc-comments explaining WHY the rule was
        // removed don't trip the assertion.
        final code = source
            .split('\n')
            .where((l) {
              final t = l.trimLeft();
              return !t.startsWith('//') && !t.startsWith('///');
            })
            .join('\n');

        expect(
          code.contains('isMessageOlderThan24Hours'),
          isFalse,
          reason: '$path still decides order age locally. The server expires '
              'on its own, shorter, configurable clocks — a local rule is what '
              'let the shop and the customer disagree for 23 hours.',
        );
        expect(code.contains("'Order Closed'"), isFalse,
            reason: '$path still renders a locally-decided terminal state.');
      }
    });

    test('the rider cards KEEP their 24-hour greying', () {
      // Display hygiene on a tracking card, not order state. Deleting it here
      // would be an unrelated regression.
      for (final path in _riderCards) {
        final source = File(path).readAsStringSync();
        expect(source.contains('isMessageOlderThan24Hours'), isTrue,
            reason: '$path lost its display-hygiene expiry.');
      }
    });

    test('the order cards render the server banner', () {
      for (final path in _orderCards) {
        final source = File(path).readAsStringSync();
        expect(source.contains('OrderLifecycleSection'), isTrue,
            reason: '$path is not wired to the server-driven section.');
        expect(source.contains('fallbackLifecycle'), isTrue);
      }
    });
  });

  group('countdown formatting', () {
    // The bands are the guide's, not ours (§8.1): hours above an hour,
    // whole minutes from 10 to 60, and seconds only in the last ten minutes —
    // where the customer is actually watching the clock.
    test('reads naturally at every scale', () {
      String f(Duration d) => OrderCountdownFormat.remaining(d);

      expect(f(const Duration(hours: 2, minutes: 14)), '2h 14m');
      expect(f(const Duration(hours: 2)), '2h 00m');
      expect(f(const Duration(minutes: 18)), '18m');
      expect(f(const Duration(minutes: 10)), '10m');
      // Under ten minutes the seconds appear and tick.
      expect(f(const Duration(minutes: 4, seconds: 31)), '4m 31s');
      expect(f(const Duration(seconds: 45)), '0m 45s');
      expect(f(Duration.zero), '0m 00s');
      // A negative remainder is clamped, never rendered as "-3m".
      expect(f(const Duration(seconds: -180)), '0m 00s');
    });

    test('past the deadline it counts UP, and never says cancelled', () {
      String f(Duration d) => OrderCountdownFormat.overdue(d);

      expect(f(const Duration(minutes: 12)), '12m');
      expect(f(const Duration(hours: 1, minutes: 4)), '1h 04m');
      expect(f(const Duration(seconds: 20)), '<1m');
    });
  });
}
