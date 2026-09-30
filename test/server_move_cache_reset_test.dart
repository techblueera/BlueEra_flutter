import 'package:BlueEra/core/services/server_move_cache_reset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empties the cache on the first run only', () async {
    var cleared = 0;
    Future<void> emptyCache() async => cleared++;

    await ServerMoveCacheReset.runOnce(emptyCache: emptyCache);
    await ServerMoveCacheReset.runOnce(emptyCache: emptyCache);

    expect(cleared, 1);
  });

  test('a failed clear is retried on the next launch and never throws',
      () async {
    var calls = 0;
    Future<void> emptyCache() async {
      calls++;
      if (calls == 1) throw Exception('disk busy');
    }

    await ServerMoveCacheReset.runOnce(emptyCache: emptyCache);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ServerMoveCacheReset.doneKey), isNull);

    await ServerMoveCacheReset.runOnce(emptyCache: emptyCache);
    expect(calls, 2);
    expect(prefs.getBool(ServerMoveCacheReset.doneKey), isTrue);
  });
}
