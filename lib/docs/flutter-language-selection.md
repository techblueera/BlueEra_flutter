# Flutter Frontend — Chat Language Selection

This README explains how to implement the **AI chat language selection** feature in a **Flutter** app.

A user picks a language (Hindi, Tamil, English, Bengali, Spanish, …). After that, the AI replies
**only in that language using its native script**, and the choice is **remembered for the whole
conversation** (saved server-side) until the user changes it.

> No new endpoint or extra request field is required. Language selection rides on the normal chat
> message — you only change the message **text** and read one new field (`language`) in the response.

---

## 1. Contract recap

| Direction | What you do |
|-----------|-------------|
| Select a language | Send a normal chat message whose text is a directive, e.g. `language=Tamil` |
| Stay locked | Just send normal messages — backend keeps the lock per `conversationId` |
| Change language | Send a new directive, e.g. `language=English` |
| Know current lock | Read `language` from the response (`null` until the user picks one) |

**REST:** `POST /api/ai-chat` with header `Authorization: Bearer <token>`
**Socket.IO:** emit `send_message`, listen on `receive_message` / `ai_status`

Recognised input forms: `language=Hindi`, `lang: tamil`, `reply in english`, or a bare `Tamil`.
**Recommended:** drive it from a dropdown and always send the `language=<Name>` directive form.

---

## 2. Dependencies

```yaml
# pubspec.yaml
dependencies:
  http: ^1.2.0              # REST
  socket_io_client: ^2.0.3  # Realtime (optional)
```

```bash
flutter pub add http socket_io_client
```

For native scripts (தமிழ், हिन्दी, العربية, 中文 …) bundle a font that covers them, e.g.
`google_fonts` with Noto, or add Noto Sans to `pubspec.yaml` and set it as the chat text style.

---

## 3. Supported languages (constant)

```dart
// lib/chat/languages.dart
class ChatLanguage {
  final String label;   // value sent to backend, e.g. "Tamil"
  final String native;  // display label, e.g. "தமிழ்"
  const ChatLanguage(this.label, this.native);
}

const kChatLanguages = <ChatLanguage>[
  ChatLanguage('English', 'English'),
  ChatLanguage('Hinglish', 'Hinglish'),
  ChatLanguage('Hindi', 'हिन्दी'),
  ChatLanguage('Tamil', 'தமிழ்'),
  ChatLanguage('Telugu', 'తెలుగు'),
  ChatLanguage('Kannada', 'ಕನ್ನಡ'),
  ChatLanguage('Malayalam', 'മലയാളം'),
  ChatLanguage('Bengali', 'বাংলা'),
  ChatLanguage('Marathi', 'मराठी'),
  ChatLanguage('Gujarati', 'ગુજરાતી'),
  ChatLanguage('Punjabi', 'ਪੰਜਾਬੀ'),
  ChatLanguage('Urdu', 'اردو'),
  ChatLanguage('Spanish', 'Español'),
  ChatLanguage('French', 'Français'),
  ChatLanguage('Arabic', 'العربية'),
  ChatLanguage('Chinese', '中文'),
];

/// Build the directive the backend understands.
String languageDirective(String label) => 'language=$label';
```

---

## 4. Models

```dart
// lib/chat/chat_models.dart
class ChatResponse {
  final String reply;
  final String conversationId;
  final String? language; // active lock, null until user selects one

  ChatResponse({required this.reply, required this.conversationId, this.language});

  factory ChatResponse.fromJson(Map<String, dynamic> j) => ChatResponse(
        reply: j['reply'] as String? ?? '',
        conversationId: j['conversationId'] as String? ?? '',
        language: j['language'] as String?,
      );
}
```

---

## 5. REST service

```dart
// lib/chat/chat_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_models.dart';

class ChatApi {
  final String baseUrl; // e.g. https://api.yourhost.com
  final String token;
  ChatApi({required this.baseUrl, required this.token});

  /// Send any chat message. To select a language, pass `language=<Name>` as [message].
  Future<ChatResponse> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
      }),
    );

    if (res.statusCode == 200) {
      return ChatResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Chat failed (${res.statusCode}): ${res.body}');
  }

  /// Convenience: explicitly switch the conversation language.
  Future<ChatResponse> selectLanguage({
    required String label,
    String? conversationId,
  }) =>
      sendMessage(message: languageDirective(label), conversationId: conversationId);
}
```

`languageDirective` comes from `languages.dart` — import it where needed.

---

## 6. State controller (ChangeNotifier)

```dart
// lib/chat/chat_controller.dart
import 'package:flutter/foundation.dart';
import 'chat_api.dart';

class ChatMessage {
  final String role; // 'user' | 'model'
  final String content;
  ChatMessage(this.role, this.content);
}

class ChatController extends ChangeNotifier {
  final ChatApi api;
  ChatController(this.api);

  final List<ChatMessage> messages = [];
  String? conversationId;
  String? activeLanguage; // drives the language badge
  bool sending = false;

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage('user', text));
    sending = true;
    notifyListeners();

    try {
      final res = await api.sendMessage(message: text, conversationId: conversationId);
      conversationId = res.conversationId;
      activeLanguage = res.language ?? activeLanguage;
      messages.add(ChatMessage('model', res.reply));
    } catch (e) {
      messages.add(ChatMessage('model', '⚠️ ${e.toString()}'));
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Called when the user picks a language from the dropdown.
  Future<void> changeLanguage(String label) async {
    activeLanguage = label; // optimistic; confirmed by response.language
    notifyListeners();
    await send(languageDirective(label));
  }
}
```

---

## 7. UI — language dropdown + badge

```dart
// lib/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'languages.dart';
import 'chat_controller.dart';

class ChatScreen extends StatelessWidget {
  final ChatController c;
  const ChatScreen(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('AI Chat'),
          actions: [
            // Active language badge
            if (c.activeLanguage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Chip(
                    avatar: const Icon(Icons.language, size: 18),
                    label: Text(c.activeLanguage!),
                  ),
                ),
              ),
            // Language selector
            PopupMenuButton<String>(
              icon: const Icon(Icons.translate),
              onSelected: c.changeLanguage,
              itemBuilder: (_) => kChatLanguages
                  .map((l) => PopupMenuItem(
                        value: l.label,
                        child: Text('${l.label}  (${l.native})'),
                      ))
                  .toList(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: c.messages.length,
                itemBuilder: (_, i) {
                  final m = c.messages[i];
                  final isUser = m.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Use a font that renders native scripts (e.g. Noto Sans).
                      child: Text(m.content),
                    ),
                  );
                },
              ),
            ),
            if (c.sending) const LinearProgressIndicator(),
            _Composer(onSend: c.send),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  final Future<void> Function(String) onSend;
  const _Composer({required this.onSend});
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _submit,
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: () => _submit(_ctrl.text)),
          ],
        ),
      ),
    );
  }

  void _submit(String text) {
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
  }
}
```

Wire it up:

```dart
final controller = ChatController(
  ChatApi(baseUrl: 'https://api.yourhost.com', token: authToken),
);
runApp(MaterialApp(home: ChatScreen(controller)));
```

---

## 8. Socket.IO (realtime, optional)

```dart
// lib/chat/chat_socket.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  late IO.Socket socket;
  final String baseUrl;
  final String token;

  ChatSocket({required this.baseUrl, required this.token});

  void connect({
    required void Function(String reply, String conversationId, String? language) onReply,
    required void Function(bool thinking) onStatus,
  }) {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token}) // adjust to your auth handshake
          .build(),
    );

    socket.on('receive_message', (data) {
      onReply(
        data['reply'] as String? ?? '',
        data['conversationId'] as String? ?? '',
        data['language'] as String?, // active language lock
      );
    });

    socket.on('ai_status', (data) => onStatus(data['status'] == 'thinking'));
    socket.connect();
  }

  /// To select a language, pass `language=<Name>` as [message].
  void sendMessage({required String message, String? conversationId, String tag = 'general'}) {
    socket.emit('send_message', {
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
      'tag': tag,
    });
  }

  void dispose() => socket.dispose();
}
```

Usage:

```dart
final chatSocket = ChatSocket(baseUrl: 'https://api.yourhost.com', token: authToken);
chatSocket.connect(
  onReply: (reply, convId, language) {
    setState(() {
      conversationId = convId;
      if (language != null) activeLanguage = language;
      messages.add(ChatMessage('model', reply));
    });
  },
  onStatus: (thinking) => setState(() => typing = thinking),
);

// User picks Hindi from the dropdown:
chatSocket.sendMessage(message: 'language=Hindi', conversationId: conversationId);
```

---

## 9. UX checklist

- [ ] Show a language selector (dropdown / chips) in the chat header.
- [ ] On selection, send `language=<Name>` for the current `conversationId`.
- [ ] Read `language` from each response and render a persistent badge (e.g. `🌐 Hindi`).
- [ ] Keep the badge until `language` changes — the lock is stored server-side, so even after an
      app restart the next reply still arrives in the saved language.
- [ ] Use a font (e.g. Noto Sans) that renders Indic / Arabic / CJK scripts.
- [ ] (Optional) "Auto" option → send `language=Hinglish` to fall back to the default style.

---

## 10. Quick reference

```dart
// Select / switch language
api.selectLanguage(label: 'Tamil', conversationId: convId);
// or over socket:
socket.sendMessage(message: 'language=Tamil', conversationId: convId);

// Response fields:  reply (String), conversationId (String), language (String?)
```

The backend persists the choice at `user.profile.preferredLanguage`; it survives reloads and
reconnects until the user explicitly selects a different language.
