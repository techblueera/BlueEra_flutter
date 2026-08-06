# BlueEra Help Widget — Flutter Integration Guide (Home / Discovery)

> **Self-contained.** Hand this to any Flutter developer and the floating "Help" chat widget on
> the Home/Discovery screen — glowing bubble → expand → tailored questions → send → open real chat
> — can be built with **no follow-up questions**. Bilingual (English + Hindi) built in.

---

## 0. What we're building

A small **floating circle at the bottom-right of the Home/Discovery screen only**:
- A **blue glowing circle** with a **white chat icon**.
- A short **hint text** that pulses/highlights intermittently (e.g. *"Koi dikkat? Help chahiye"*) so the
  user knows they can get help.
- **On tap → the circle expands** into a small panel showing **ready-made questions** (tailored to the
  user's account type/category) + a **Send** button.
- User taps a question (or types their own) → **Send** → the app **navigates to the real chat screen**
  and the conversation continues there with full chat functionality.

```
Home screen (bottom-right):            Tapped (expanded):
                                       ┌───────────────────────────┐
                                       │  How can we help you? ✕   │
                                       │  ◦ Add products to my …    │
        ╭────╮  "Help?"                │  ◦ Manage my orders        │
        │ 💬 │  (pulsing hint)   ──►    │  ◦ Verification pending    │
        ╰────╯                         │  ◦ Payment query           │
     (blue glow circle)                │  ◦ Other inquiry           │
                                       │  [ type your question…  ]  │
                                       │              [  Send  ] →   │
                                       └───────────────────────────┘
                                          └─ Send → navigate to real ChatScreen(conversationId)
```

---

## 1. Backend APIs (already live in chat-service)

Base: `https://be.beapp.in/api/chat-service` · header `Authorization: Bearer <user JWT>`.

### 1.1 GET `/support/questions`
Returns questions tailored to the logged-in user's account type + business category / profession
(resolved server-side), bilingual, with a final "Other inquiry".
```json
{
  "success": true,
  "account_type": "BUSINESS",
  "category": "Pharmacy",          // exact category (or profession for individuals) — may be null
  "profession": null,
  "questions": [
    { "id": "h1", "en": "How do I list my Pharmacy services / doctors?", "hi": "Main apni Pharmacy services / doctors kaise list karun?" },
    { "id": "h2", "en": "How do I manage appointments / bookings?", "hi": "Main appointments / bookings kaise manage karun?" },
    { "id": "h3", "en": "My medical verification / license is pending.", "hi": "Meri medical verification / license pending hai." },
    { "id": "h4", "en": "How do I update my Pharmacy profile & timings?", "hi": "Main apni Pharmacy profile aur timings kaise update karun?" },
    { "id": "other", "en": "Other inquiry", "hi": "Anya sawaal" }
  ],
  "existing_conversation_id": null   // if set → user already has a support chat; open it directly
}
```
Show `en` or `hi` based on the app locale. Always render **all 5** items; the last (`other`) opens a
free-text field.

### 1.2 POST `/support/inquiry`
Body `{ "question": "<selected or typed text>", "questionId": "<id | optional>" }`.
Starts (or reuses) the support chat with the BlueEra team; the question becomes the **first message**.
```json
{ "success": true, "conversation_id": "6b2f…", "message_id": "6b30…" }
```
After this, use the **normal chat** APIs/screen with `conversation_id`.

### 1.3 The real chat (after send)
The support chat is an ordinary 1:1 conversation, so **reuse your existing chat screen**:
- Messages: your existing get-messages endpoint / socket.
- Send text/media: your existing `POST /chat/send-message` (multipart or pre-uploaded S3 URLs) + socket.
- Live updates: the existing Socket.IO connection (`newMessageReceived`, typing, etc.).

> The team replies from the admin panel; those replies arrive on the same socket, exactly like any
> other chat.

---

## 2. UX behaviour (state machine)

```
COLLAPSED  ── every ~6–8s ──►  pulse the hint text ("Help chahiye?")
COLLAPSED  ── onTap ──►  (a) if existing_conversation_id → push ChatScreen(existing_conversation_id)
                         (b) else → fetch GET /support/questions → EXPANDED
EXPANDED   ── pick a question ──►  fills the composer (editable) OR sends immediately (your choice)
EXPANDED   ── "Other inquiry" ──►  focus the free-text field
EXPANDED   ── Send ──►  POST /support/inquiry → push ChatScreen(conversation_id) → COLLAPSED
EXPANDED   ── ✕ / tap outside ──►  COLLAPSED
```

- **Show only on Home/Discovery.** Place the widget in that screen's `Stack`, not app-wide.
- **Pre-fetch** `GET /support/questions` when Home loads so the panel opens instantly (and you know
  `existing_conversation_id` up front).

---

## 3. Flutter reference implementation

### 3.1 Service (API calls)
```dart
class HelpService {
  final String base = "https://be.beapp.in/api/chat-service";
  final String jwt;             // the logged-in user's token
  HelpService(this.jwt);
  Map<String, String> get _h => {
    "Authorization": "Bearer $jwt",
    "Content-Type": "application/json",
  };

  Future<Map<String, dynamic>> getQuestions() async {
    final r = await http.get(Uri.parse("$base/support/questions"), headers: _h);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Returns the conversationId to open.
  Future<String?> startInquiry(String question, {String? questionId}) async {
    final r = await http.post(
      Uri.parse("$base/support/inquiry"),
      headers: _h,
      body: jsonEncode({"question": question, if (questionId != null) "questionId": questionId}),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return data["success"] == true ? data["conversation_id"] as String? : null;
  }
}
```

### 3.2 The floating widget (drop into the Home screen's Stack)
```dart
class HelpBubble extends StatefulWidget {
  final HelpService service;
  final String locale;                       // "hi" or "en"
  final void Function(String conversationId) openChat;   // your navigation
  const HelpBubble({required this.service, required this.locale, required this.openChat, super.key});
  @override State<HelpBubble> createState() => _HelpBubbleState();
}

class _HelpBubbleState extends State<HelpBubble> {
  bool expanded = false;
  bool showHint = true;
  List questions = [];
  String? existingConvId;
  final textCtrl = TextEditingController();
  Timer? hintTimer;

  @override void initState() {
    super.initState();
    _prefetch();
    // Pulse the hint every ~7s.
    hintTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && !expanded) setState(() => showHint = !showHint);
    });
  }
  @override void dispose() { hintTimer?.cancel(); textCtrl.dispose(); super.dispose(); }

  Future<void> _prefetch() async {
    try {
      final r = await widget.service.getQuestions();
      setState(() {
        questions = (r["questions"] as List?) ?? [];
        existingConvId = r["existing_conversation_id"] as String?;
      });
    } catch (_) {}
  }

  String _t(Map q) => (widget.locale == "hi" ? q["hi"] : q["en"]) ?? q["en"] ?? "";

  Future<void> _onTapBubble() async {
    if (existingConvId != null) { widget.openChat(existingConvId!); return; }
    if (questions.isEmpty) await _prefetch();
    setState(() => expanded = true);
  }

  Future<void> _send(String question, {String? id}) async {
    final convId = await widget.service.startInquiry(question, questionId: id);
    if (convId != null) {
      setState(() => expanded = false);
      widget.openChat(convId);                 // navigate to the real chat screen
    }
  }

  @override Widget build(BuildContext context) {
    return Positioned(
      right: 16, bottom: 24,
      child: expanded ? _panel() : _collapsed(),
    );
  }

  Widget _collapsed() => GestureDetector(
    onTap: _onTapBubble,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (showHint) Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)]),
        child: Text(widget.locale == "hi" ? "Help chahiye?" : "Need help?"),
      ),
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2563EB),
          boxShadow: [BoxShadow(blurRadius: 16, spreadRadius: 2, color: const Color(0xFF2563EB).withOpacity(0.6))]),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    ]),
  );

  Widget _panel() => Container(
    width: 300,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)]),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(widget.locale == "hi" ? "Hum aapki kaise madad karein?" : "How can we help?",
          style: const TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(onTap: () => setState(() => expanded = false), child: const Icon(Icons.close, size: 18)),
      ]),
      const SizedBox(height: 8),
      ...questions.map((q) => InkWell(
        onTap: () {
          if (q["id"] == "other") { FocusScope.of(context).requestFocus(FocusNode()); }
          else { _send(_t(q), id: q["id"]); }
        },
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text("• ${_t(q)}")),
      )),
      const Divider(),
      Row(children: [
        Expanded(child: TextField(controller: textCtrl,
          decoration: InputDecoration(hintText: widget.locale == "hi" ? "Apna sawaal likhein…" : "Type your question…"))),
        IconButton(icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
          onPressed: () { final t = textCtrl.text.trim(); if (t.isNotEmpty) _send(t); }),
      ]),
    ]),
  );
}
```

Wire it into Home:
```dart
Stack(children: [
  HomeContent(),
  HelpBubble(
    service: HelpService(userJwt),
    locale: appLocale,                        // "hi" / "en"
    openChat: (convId) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId))),  // your existing screen
  ),
]),
```

---

## 4. Notes
- **Bilingual:** pick `hi`/`en` from the app locale; the backend always returns both.
- **Returning users:** if `existing_conversation_id` is present, skip the questions and open the chat
  directly (they've asked before — continue the same thread).
- **After send it's normal chat:** the ChatScreen uses your existing message list, send (text + media),
  and socket — nothing special. The team's replies arrive on the same socket.
- **Only on Home/Discovery:** don't mount the bubble globally.
- **Auth:** the same user JWT you already use for chat.

### One-line summary
Glowing help bubble on Home → tap → tailored bilingual questions + "Other inquiry" → Send → open the
real chat (full functionality). Backend: `GET /support/questions` + `POST /support/inquiry`.
