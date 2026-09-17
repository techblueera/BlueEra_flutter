/// Guards against text that Skia's paragraph builder refuses to lay out.
///
/// Dart strings are sequences of UTF-16 code units, and any character outside
/// the BMP — every emoji, among others — is stored as a *surrogate pair* of two
/// units. Cutting a string at a code-unit boundary that falls between the two
/// leaves a lone surrogate, which is not valid UTF-16. `substring`, `[]`,
/// `codeUnits` and server-side truncation all cut by code unit and will do this
/// happily.
///
/// The engine does not tolerate it. `_NativeParagraphBuilder.addText` throws
///   Invalid argument(s): string is not well-formed UTF-16
/// from inside `RenderParagraph.performLayout` — during a frame, below any
/// widget, where no app-level try/catch can reach it. The whole frame dies.
library;

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

/// [input] with any unpaired surrogate removed; well-formed pairs are kept.
///
/// Returns the very same instance when nothing is wrong, which is the
/// overwhelmingly common case — so this costs one scan and no allocation for
/// ordinary text, and only builds a buffer once it has something to drop.
String stripLoneSurrogates(String input) {
  StringBuffer? out;

  for (var i = 0; i < input.length; i++) {
    final unit = input.codeUnitAt(i);

    if (_isHighSurrogate(unit)) {
      final hasPair = i + 1 < input.length &&
          _isLowSurrogate(input.codeUnitAt(i + 1));
      if (hasPair) {
        out?.writeCharCode(unit);
        out?.writeCharCode(input.codeUnitAt(i + 1));
        i++; // the low half belongs to this character
        continue;
      }
      out ??= StringBuffer(input.substring(0, i));
      continue; // lone high surrogate
    }

    if (_isLowSurrogate(unit)) {
      // A high surrogate would have consumed this one, so it is unpaired.
      out ??= StringBuffer(input.substring(0, i));
      continue;
    }

    out?.writeCharCode(unit);
  }

  return out?.toString() ?? input;
}

/// The first whole character of [input] — never half of a surrogate pair.
///
/// For the avatar initials this app derives with `substring(0, 1)`: a display
/// name beginning with an emoji yields a lone high surrogate that way, which
/// is the crash above. This returns the full character instead, so the emoji
/// also renders as the initial rather than being dropped.
///
/// Returns `''` for empty input, or when the string opens on an unpaired
/// surrogate and there is no whole character to show.
String firstCharacter(String input) {
  if (input.isEmpty) return '';

  final first = input.codeUnitAt(0);

  if (_isHighSurrogate(first)) {
    if (input.length > 1 && _isLowSurrogate(input.codeUnitAt(1))) {
      return input.substring(0, 2);
    }
    return '';
  }

  if (_isLowSurrogate(first)) return '';

  return input.substring(0, 1);
}

/// [firstCharacter] of [input] upper-cased, or [fallback] when there is no
/// character to show — null, empty, or an unpaired surrogate.
///
/// For avatar initials. `input?.substring(0, 1)` handles null but throws
/// RangeError on an empty string, which is a separate bug the call sites had.
String initialOr(String? input, String fallback) {
  final first = firstCharacter(input ?? '');
  return first.isEmpty ? fallback : first.toUpperCase();
}
