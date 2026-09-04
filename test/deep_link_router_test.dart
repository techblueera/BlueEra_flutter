import 'package:BlueEra/core/services/deep_link_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the three pure decisions that stand between a scanned vehicle-safety
/// sticker and the owner's chat. Everything else in [DeepLinkRouter] navigates,
/// so it is covered on-device; these are the branches that silently send a link
/// to the wrong place when they get it wrong.
void main() {
  group('isBrowserBounce', () {
    test('the sticker URL itself goes to the browser, never to a screen', () {
      expect(
        DeepLinkRouter.isBrowserBounce(
            Uri.parse('https://emergency.beapp.in/v/MFYRG8CT')),
        isTrue,
      );
    });

    test('an emergency profile QR on the same host is app navigation', () {
      expect(
        DeepLinkRouter.isBrowserBounce(
            Uri.parse('https://emergency.beapp.in/6a0a9367b3b8327f72a28ce6')),
        isFalse,
      );
    });

    test('a /v/ path on any other host is not the sticker', () {
      expect(
        DeepLinkRouter.isBrowserBounce(Uri.parse('https://beapp.in/v/MFYRG8CT')),
        isFalse,
      );
    });
  });

  group('requiresRealAccount', () {
    test('the parking-report chat link needs a real account', () {
      expect(
        DeepLinkRouter.requiresRealAccount(Uri.parse(
            'https://beapp.in/app/chat/new?userId=6a0a9367b3b8327f72a28ce6'
            '&chatType=personal&source=vehicle_qr&vehicleNumber=UP16FL4618')),
        isTrue,
      );
    });

    test('an existing conversation needs one too', () {
      expect(
        DeepLinkRouter.requiresRealAccount(
            Uri.parse('https://beapp.in/app/chat/6a0a9367b3b8327f72a28ce6')),
        isTrue,
      );
    });

    test('a post or store link opens fine for a guest', () {
      expect(
        DeepLinkRouter.requiresRealAccount(
            Uri.parse('https://beapp.in/app/post/6a0a9367b3b8327f72a28ce6')),
        isFalse,
      );
      expect(
        DeepLinkRouter.requiresRealAccount(Uri.parse(
            'https://beapp.in/app/business/grocery/6a0a9367b3b8327f72a28ce6')),
        isFalse,
      );
    });
  });

  group('isValidMongoId', () {
    test('accepts a 24-hex owner id', () {
      expect(
          DeepLinkRouter.isValidMongoId('6a0a9367b3b8327f72a28ce6'), isTrue);
    });

    test('rejects the `new` sentinel — the chat branch handles it separately',
        () {
      expect(DeepLinkRouter.isValidMongoId('new'), isFalse);
    });

    test('rejects wrong length and non-hex', () {
      expect(DeepLinkRouter.isValidMongoId('6a0a9367b3b8327f72a28ce'), isFalse);
      expect(
          DeepLinkRouter.isValidMongoId('zzzz9367b3b8327f72a28ce6'), isFalse);
    });
  });
}
