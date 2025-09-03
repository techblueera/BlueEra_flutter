import 'package:flutter/services.dart';

class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith(' ')) {
      final String trimedText = newValue.text.trimLeft();

      return TextEditingValue(
        text: trimedText,
        selection: TextSelection(
          baseOffset: trimedText.length,
          extentOffset: trimedText.length,
        ),
      );
    }

    return newValue;
  }
}
class NoConsecutiveSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Check if the new value has consecutive spaces
    if (newValue.text.contains('  ')) {
      // If consecutive spaces are found, return the old value (keeping the old input)
      return oldValue;
    }
    // Otherwise, allow the new value
    return newValue;
  }
}
class UppercaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Convert the new text to uppercase
    String newText = newValue.text.toUpperCase();
    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}
