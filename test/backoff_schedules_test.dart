import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/chat/auth/socket/chat_socket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location heartbeat backs off from 5s, doubling, capped at 5 min', () {
    final delays = [
      for (var n = 1; n <= 9; n++) LiveLocationService.backoffFor(n).inSeconds
    ];
    expect(delays, [5, 10, 20, 40, 80, 160, 300, 300, 300]);
  });

  test('chat socket reconnects from 1s, doubling, capped at 30s', () {
    final delays = [
      for (var n = 0; n <= 7; n++) ChatSocketService.reconnectDelayFor(n).inSeconds
    ];
    expect(delays, [1, 2, 4, 8, 16, 30, 30, 30]);
  });
}
