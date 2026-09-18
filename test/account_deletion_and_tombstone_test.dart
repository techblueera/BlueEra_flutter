import 'package:BlueEra/core/api/model/user_profile_res.dart';
import 'package:BlueEra/core/constants/deleted_user.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/user_by_phone_model.dart';
import 'package:BlueEra/features/common/account_deletion/model/deletion_blocked_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart' as feed;
import 'package:flutter_test/flutter_test.dart';

/// Covers the three fixes in docs/backend/FRONTEND_ACCOUNT_DELETION_BUGS.md.
///
/// Only the pure parsing/decision layer is exercised here — the widget-level
/// consequences (tombstone byline, dead call button, replaced composer) all
/// ride on the flags these tests pin down.
void main() {
  group('BUG 1 — the 409 body tells the two reasons apart', () {
    test('deletion_blocked parses every blocker with its own message', () {
      final parsed = DeletionBlockedResponse.fromJson({
        'success': false,
        'code': 'deletion_blocked',
        'message': "Your account can't be deleted yet.",
        'blockers': [
          {
            'type': 'wallet_balance',
            'amount': 240,
            'message': 'You have 240 in your wallet. Withdraw it first.',
          },
          {
            'type': 'active_order_buyer',
            'count': 2,
            'message': 'You have 2 order(s) still in progress.',
          },
          {
            'type': 'check_unavailable',
            'service': 'wallet',
            'message': "We couldn't check your wallet balance right now.",
          },
        ],
      });

      expect(parsed.isBlocked, isTrue);
      expect(parsed.isAlreadyPending, isFalse);
      expect(parsed.blockers, hasLength(3));
      expect(parsed.blockers.first.amount, 240);
      expect(parsed.blockers[1].count, 2);
      expect(parsed.blockers[2].service, 'wallet');
    });

    test('check_unavailable is a backend outage, not the user owing money', () {
      final parsed = DeletionBlockedResponse.fromJson({
        'code': 'deletion_blocked',
        'blockers': [
          {
            'type': 'check_unavailable',
            'message': 'Try again in a few minutes.',
          },
          {'type': 'wallet_balance', 'message': 'Withdraw your balance.'},
        ],
      });

      expect(parsed.blockers[0].isTransient, isTrue);
      expect(parsed.blockers[1].isTransient, isFalse);
    });

    test('already_pending_deletion keeps the legacy snackbar path', () {
      final parsed = DeletionBlockedResponse.fromJson({
        'success': false,
        'code': 'already_pending_deletion',
        'message': 'A deletion request is already in progress.',
      });

      expect(parsed.isAlreadyPending, isTrue);
      expect(parsed.isBlocked, isFalse);
      expect(parsed.blockers, isEmpty);
    });

    test('a 409 with no recognisable body falls back rather than throwing', () {
      expect(DeletionBlockedResponse.fromJson(null).isBlocked, isFalse);
      expect(DeletionBlockedResponse.fromJson('<html>502</html>').code, isNull);
      // A `deletion_blocked` code with no usable blockers must NOT open an
      // empty dialog — the controller checks `blockers.isNotEmpty` too.
      final empty = DeletionBlockedResponse.fromJson(
          {'code': 'deletion_blocked', 'blockers': []});
      expect(empty.blockers, isEmpty);
    });

    test('a blocker with no message is dropped, not rendered blank', () {
      final parsed = DeletionBlockedResponse.fromJson({
        'code': 'deletion_blocked',
        'blockers': [
          {'type': 'wallet_balance'},
          {'type': 'active_subscription', 'message': 'Cancel your plan first.'},
        ],
      });

      expect(parsed.blockers, hasLength(1));
      expect(parsed.blockers.single.type, 'active_subscription');
    });
  });

  group('BUG 2 — is_deleted reaches the models that render other users', () {
    test('parseIsDeleted defaults to false and accepts the wire variants', () {
      expect(parseIsDeleted(null), isFalse); // key absent on older payloads
      expect(parseIsDeleted(false), isFalse);
      expect(parseIsDeleted(true), isTrue);
      expect(parseIsDeleted(1), isTrue);
      expect(parseIsDeleted(0), isFalse);
      expect(parseIsDeleted('true'), isTrue);
      expect(parseIsDeleted('false'), isFalse);
      expect(parseIsDeleted('nonsense'), isFalse);
    });

    test('a chat-list tombstone parses and keeps its id', () {
      final sender = Sender.fromJson({
        '_id': '6a1fbcc215d42caef618aa0d',
        'name': 'Deleted User',
        'is_deleted': true,
        'account_type': 'INDIVIDUAL',
        'deleted_at': '2026-09-17T02:00:00.000Z',
        'contact_no': '',
        'profile_image': '',
        'username': '',
      });

      // The id still resolves — that is what keeps the surviving person's
      // chat history readable.
      expect(sender.id, '6a1fbcc215d42caef618aa0d');
      expect(sender.isDeleted, isTrue);
      expect(sender.profileImage, isEmpty);
    });

    test('a live chat-list sender is untouched', () {
      final sender = Sender.fromJson({
        '_id': '687baa0ca598e3558edda1d7',
        'name': 'good person',
        'contact_no': '9363029058',
      });

      expect(sender.isDeleted, isFalse);
      expect(sender.name, 'good person');
    });

    test('the flag survives a toJson/fromJson round trip (cached rows)', () {
      final sender = Sender.fromJson({'_id': 'x', 'is_deleted': true});
      expect(Sender.fromJson(sender.toJson()).isDeleted, isTrue);
    });

    test('profile, feed author and by-phone payloads all carry the flag', () {
      expect(User.fromJson({'_id': 'a', 'is_deleted': true}).isDeleted, isTrue);
      expect(User.fromJson({'_id': 'a'}).isDeleted, isFalse);

      expect(
        feed.User.fromJson({'_id': 'a', 'is_deleted': true}).isDeleted,
        isTrue,
      );
      // copyWith is how the feed header re-keys an author before routing —
      // dropping the flag there would re-open the tap it is meant to block.
      expect(
        feed.User.fromJson({'_id': 'a', 'is_deleted': true})
            .copyWith(id: 'b')
            .isDeleted,
        isTrue,
      );

      expect(
        UserByPhoneModel.fromJson({'_id': 'a', 'is_deleted': true}).isDeleted,
        isTrue,
      );
      expect(UserByPhoneModel.fromJson({'_id': 'a'}).isDeleted, isFalse);
    });

    test('displayUserName substitutes for a tombstone, passes live names', () {
      // Without GetX translations loaded, `.tr` yields the key itself — enough
      // to prove the server's English text is NOT what gets rendered.
      expect(displayUserName('Deleted User', isDeleted: true), deletedUserName);
      expect(displayUserName('Asha', isDeleted: false), 'Asha');
      // "null" and "" are the two ways this codebase spells "no name".
      expect(
        displayUserName('null', isDeleted: false, fallback: '9363029058'),
        '9363029058',
      );
      expect(
        displayUserName('', isDeleted: false, fallback: '9363029058'),
        '9363029058',
      );
      // A deleted user never falls back to a number — a tombstone's
      // contact_no is "" anyway.
      expect(
        displayUserName('', isDeleted: true, fallback: '9363029058'),
        deletedUserName,
      );
    });

    test('blockDeletedUserAction only stops deleted users', () {
      // No GlobalMessageService is registered here, so the snackbar is a
      // logged no-op — the return value is the contract callers rely on.
      expect(blockDeletedUserAction(true), isTrue);
      expect(blockDeletedUserAction(false), isFalse);
      expect(blockDeletedUserAction(null), isFalse);
    });
  });
}
