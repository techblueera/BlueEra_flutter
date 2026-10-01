import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/notification/binding/notification_binding.dart';
import 'package:BlueEra/features/common/notification/controller/notification_hub_controller.dart';
import 'package:BlueEra/features/common/notification/notification_repo.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive/hive.dart';

ResponseModel _ok(Object? data) => ResponseModel(
      statusCode: 200,
      response: Response(
          requestOptions: RequestOptions(), statusCode: 200, data: data),
    );

Map<String, dynamic> _row(String id, String type,
        {String status = 'UNREAD', String? kind, String? message}) =>
    {
      '_id': id,
      'notification_type': type,
      'status': status,
      if (kind != null) 'type': kind,
      if (message != null) 'message': message,
      'createdAt': '2026-09-01T10:00:00Z',
    };

/// Serves [pages] by page number and records every call.
class _FakeNotificationRepo extends NotificationListRepo {
  _FakeNotificationRepo(this.pages);

  final Map<int, Map<String, dynamic>> pages;
  final List<int> fetched = [];
  final List<String> read = [];
  final List<String> deleted = [];
  int deleteAllCalls = 0;

  @override
  Future<ResponseModel> fetchNotificationRepo(
      {required String filterType, int? page, int? limit}) async {
    fetched.add(page ?? 1);
    return _ok(pages[page ?? 1] ?? {'data': []});
  }

  @override
  Future<ResponseModel> notificationReadRepo(
      {required String notificationId}) async {
    read.add(notificationId);
    return _ok(null);
  }

  @override
  Future<ResponseModel> deleteNotification({required String notifyId}) async {
    deleted.add(notifyId);
    return _ok(null);
  }

  @override
  Future<ResponseModel> deleteAllNotification() async {
    deleteAllCalls++;
    return _ok(null);
  }
}

void main() {
  // The cache hydrates from and persists to a Hive box.
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync().path));
  setUp(Get.reset);
  tearDown(Get.reset);

  NotificationHubController hub(_FakeNotificationRepo repo) =>
      NotificationHubController(repo: repo, cache: NotificationCacheService());

  test('first open syncs page one and hides chat messages but not calls',
      () async {
    final repo = _FakeNotificationRepo({
      1: {
        'data': [
          _row('a', 'orders'),
          _row('b', 'chat'),
          _row('c', 'chat', kind: 'missed_call'),
        ],
        'pagination': {'hasNextPage': true},
      },
    });
    final c = hub(repo)..onInit();
    // onInit starts the sync without awaiting it; it ends after the Hive write.
    while (c.isSyncing.value) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(repo.fetched, [1]);
    expect(c.visible.map((n) => n.sId), ['a', 'c']);
    expect(c.cache.hasMore, isTrue);
    expect(c.canLoadMore, isTrue);
  });

  test('tabs and search filter the cached list client-side', () async {
    final repo = _FakeNotificationRepo({
      1: {
        'data': [
          _row('a', 'orders', message: 'Your order is packed'),
          _row('b', 'jobs', message: 'New job near you'),
        ],
      },
    });
    final c = hub(repo);
    await c.syncFirstPage();

    c.selectedTab.value = NotificationHubController.tabIds.indexOf('Jobs');
    expect(c.visible.map((n) => n.sId), ['b']);
    expect(c.showsMore, isFalse);

    c.selectedTab.value = 0;
    c.searchQuery.value = 'PACKED';
    expect(c.visible.map((n) => n.sId), ['a']);
    expect(repo.fetched, [1]);
  });

  test('marking read skips the API for push-only rows', () async {
    final repo = _FakeNotificationRepo({
      1: {
        'data': [_row('a', 'orders')]
      },
    });
    final c = hub(repo);
    await c.syncFirstPage();

    c.markRead('a');
    c.markRead('local_123');

    expect(c.cache.items.single.status, 'READ');
    expect(repo.read, ['a']);
  });

  test('deletes clear locally and tell the server only about real rows',
      () async {
    final repo = _FakeNotificationRepo({
      1: {
        'data': [_row('a', 'orders'), _row('b', 'posts')]
      },
    });
    final c = hub(repo);
    await c.syncFirstPage();

    expect(await c.deleteOne('a'), isTrue);
    expect(await c.deleteOne('local_9'), isTrue);
    expect(await c.deleteOne(''), isFalse);
    await c.deleteAll();
    await Future<void>.delayed(Duration.zero);

    expect(c.cache.items, isEmpty);
    expect(repo.deleted, ['a']);
    expect(repo.deleteAllCalls, 1);
  });

  test('the binding scopes a fresh controller to the hub route', () {
    NotificationBinding().dependencies();
    final first = Get.find<NotificationHubController>();

    Get.delete<NotificationHubController>();
    NotificationBinding().dependencies();

    expect(Get.find<NotificationHubController>(), isNot(same(first)));
  });
}
