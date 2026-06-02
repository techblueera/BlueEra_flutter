/// Supported AI chat reply languages.
///
/// Selecting one tells the backend to reply **only** in that language (using
/// its native script) for the current conversation. The choice is sent as a
/// normal chat message whose text is the [languageDirective] (e.g.
/// `language=Tamil`) and stays locked server-side per conversation until the
/// user picks a different one.
class ChatLanguage {
  /// Value sent to the backend, e.g. "Tamil".
  final String label;

  /// Display label in the language's own script, e.g. "தமிழ்".
  final String native;

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

/// Build the directive the backend understands for a language selection.
String languageDirective(String label) => 'language=$label';
