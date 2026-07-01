import 'dart:convert';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// Decides whether a `session_displaced` / `force_logout` push should actually
/// log THIS device out.
///
/// The trap it avoids: single-session displacement fires whenever a NEW login
/// displaces a prior session of the same device type. When the user simply
/// logs in again on the SAME physical device (a stale prior session still
/// exists in the DB), the server displaces that old session and pushes a
/// `session_displaced` to its device token — which is this very device. Blindly
/// honoring that push logs the user out immediately after a successful login,
/// with no second device involved.
///
/// Discriminator: only log out if the displaced session is OUR CURRENT session.
///   - Self re-login echo → push carries the OLD session id, our token holds the
///     NEW session id → no match → ignore.
///   - Genuine cross-device login → push carries OUR session id → match → logout.
///
/// Everything is derived from our own JWT (`sessionId` + `iat`), so there is no
/// login-code change and no extra stored state. The `iat` freshness check is a
/// backstop: it suppresses the echo even against an older backend that does not
/// yet send `session_ids`, and covers the narrow race where the push arrives
/// before the fresh token has been persisted.
class SessionGuard {
  /// Ignore displacements that target a token issued within this window — a
  /// just-issued token means we only now logged in on this device, so the
  /// displacement is our own login's echo, not a foreign device.
  static const Duration _freshLoginWindow = Duration(seconds: 120);

  /// Async because it reads the persisted auth token. Safe to call from the
  /// background isolate (only touches secure storage, no UI).
  static Future<bool> shouldForceLogout(Map<String, dynamic> data) async {
    String? token;
    try {
      token = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.authToken);
    } catch (_) {
      token = null;
    }
    final claims = _decodeJwt(token);
    final currentSessionId = claims == null
        ? null
        : (claims['sessionId'] ?? claims['session_id'])?.toString();

    // Not logged in (no token / no session id) → nothing to force out.
    if (currentSessionId == null || currentSessionId.isEmpty) return false;

    final displaced = _displacedSessionIds(data);
    final freshlyIssued = _issuedWithinWindow(claims);

    if (displaced.isNotEmpty) {
      // Authoritative: honor only if OUR session is the one being displaced.
      if (!displaced.contains(currentSessionId)) return false;
      // Matched, but a just-issued token means this is the self-login race
      // (token not yet swapped when the push was built) — ignore it.
      return !freshlyIssued;
    }

    // Backward-compat: older backend sent no session_ids. We cannot match
    // exactly, so fall back to the freshness backstop: suppress only the
    // self-login echo; honor everything else so lazy 401 is not the only guard.
    return !freshlyIssued;
  }

  static List<String> _displacedSessionIds(Map<String, dynamic> data) {
    dynamic raw = data['session_ids'];

    // The full producer payload rides along as data['payload'] (JSON string).
    if (raw == null) {
      final payloadRaw = data['payload'];
      Map<String, dynamic> payload = {};
      try {
        if (payloadRaw is String && payloadRaw.isNotEmpty) {
          payload = Map<String, dynamic>.from(jsonDecode(payloadRaw));
        } else if (payloadRaw is Map) {
          payload = Map<String, dynamic>.from(payloadRaw);
        }
      } catch (_) {
        payload = {};
      }
      raw = payload['session_ids'];
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return [raw];
      }
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static bool _issuedWithinWindow(Map<String, dynamic>? claims) {
    final iat = claims == null ? null : claims['iat'];
    if (iat is! num) return false;
    final issuedAtMs = (iat * 1000).round();
    final ageMs = DateTime.now().millisecondsSinceEpoch - issuedAtMs;
    return ageMs >= 0 && ageMs < _freshLoginWindow.inMilliseconds;
  }

  static Map<String, dynamic>? _decodeJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic>
          ? map
          : Map<String, dynamic>.from(map as Map);
    } catch (_) {
      return null;
    }
  }
}
