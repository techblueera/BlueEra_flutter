import 'package:BlueEra/features/chat/auth/model/call_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts urls as a single string or a list', () {
    final single = IceServer.fromJson({'urls': 'stun:stun.example.org:3478'});
    final list = IceServer.fromJson({
      'urls': ['stun:a.example.org:3478', 'stun:b.example.org:3478'],
    });

    expect(single.urls, ['stun:stun.example.org:3478']);
    expect(list.urls, ['stun:a.example.org:3478', 'stun:b.example.org:3478']);
  });

  test('a TURN url without a transport is offered over UDP and TCP', () {
    final server = IceServer.fromJson({
      'urls': 'turn:65.0.158.70:3478',
      'username': 'u',
      'credential': 'p',
    });

    expect(server.urls, [
      'turn:65.0.158.70:3478?transport=udp',
      'turn:65.0.158.70:3478?transport=tcp',
    ]);
    expect(server.toMap(), {
      'urls': [
        'turn:65.0.158.70:3478?transport=udp',
        'turn:65.0.158.70:3478?transport=tcp',
      ],
      'username': 'u',
      'credential': 'p',
    });
  });

  test('explicit transports are kept as the backend sent them', () {
    final server = IceServer.fromJson({
      'urls': [
        'turn:65.0.158.70:3478?transport=udp',
        'turn:65.0.158.70:3478?transport=tcp',
      ],
    });

    expect(server.urls, [
      'turn:65.0.158.70:3478?transport=udp',
      'turn:65.0.158.70:3478?transport=tcp',
    ]);
  });

  test('no usable servers falls back to STUN instead of none at all', () {
    expect(IceServerConfig(iceServers: []).toWebRTCConfig(),
        IceServerConfig.stunOnly);
    expect(
        IceServerConfig.fromJson({
          'iceServers': [
            {'urls': ''},
          ],
        }).toWebRTCConfig(),
        IceServerConfig.stunOnly);
  });

  test('reads the backend list', () {
    final config = IceServerConfig.fromJson({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'turn:65.0.158.70:3478', 'username': 'u', 'credential': 'p'},
      ],
    });

    final servers = config.toWebRTCConfig()['iceServers'] as List;
    expect(servers, hasLength(2));
    expect((servers[1] as Map)['urls'], hasLength(2));
  });
}
