import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the field's formatters over [text] the way an [EditableText] would.
///
/// Mirrors Flutter's own `_formatText`: every formatter is handed the SAME
/// `oldValue`, while `newValue` accumulates through the chain. Feeding each
/// formatter the raw text instead would let the length limiter undo the
/// filtering the formatter before it just did.
TextEditingValue _apply(TextEditingValue oldValue, TextEditingValue newValue) {
  var value = newValue;
  for (final formatter in VehicleNumber.inputFormatters) {
    value = formatter.formatEditUpdate(oldValue, value);
  }
  return value;
}

/// Types [text] into an empty field.
TextEditingValue _type(String text) => _apply(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

/// Types [text] through the relaxed (emergency-profile) formatters.
String _typedRelaxed(String text) {
  var value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  for (final formatter in VehicleNumber.relaxedInputFormatters) {
    value = formatter.formatEditUpdate(TextEditingValue.empty, value);
  }
  return value.text;
}

String _typed(String text) => _type(text).text;

void main() {
  group('VehicleNumber.inputFormatters', () {
    test('first two slots take letters only', () {
      // A digit typed into an empty field must not land in the state-code slot.
      expect(_typed('1'), '');
      expect(_typed('12MH'), 'MH');
      expect(_typed('M1H'), 'MH');
    });

    test('letters and digits are both allowed from the third slot on', () {
      expect(_typed('MH12AB1234'), 'MH12AB1234');
      expect(_typed('DL1CAB1234'), 'DL1CAB1234');
    });

    test('upper-cases as you type', () {
      expect(_typed('mh12ab1234'), 'MH12AB1234');
    });

    test('strips separators from a pasted plate', () {
      expect(_typed('GJ-01-AB-1234'), 'GJ01AB1234');
      expect(_typed('GJ 01 AB 1234'), 'GJ01AB1234');
    });

    test('caps at maxLength', () {
      final long = _typed('MH12AB1234567890123');
      expect(long.length, VehicleNumber.maxLength);
      expect(long, 'MH12AB123456789');
    });

    test('keeps the caret where the user is typing, not at the end', () {
      // "MH12AB" with the caret after "MH", then a rejected character is typed
      // at that point — the caret must not jump to the end of the field.
      const start = TextEditingValue(
        text: 'MH12AB',
        selection: TextSelection.collapsed(offset: 2),
      );
      // User types "X" at offset 2 -> "MHX12AB", caret 3. X is allowed there.
      final next = _apply(
        start,
        const TextEditingValue(
          text: 'MHX12AB',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(next.text, 'MHX12AB');
      expect(next.selection.baseOffset, 3);
    });
  });

  group('VehicleNumber.relaxedInputFormatters', () {
    test('still polices the two-letter prefix', () {
      expect(_typedRelaxed('1'), '');
      expect(_typedRelaxed('12MH'), 'MH');
      expect(_typedRelaxed(' MH'), 'MH');
    });

    test('accepts anything after the prefix, separators included', () {
      expect(_typedRelaxed('MH 12 AB 1234'), 'MH 12 AB 1234');
      expect(_typedRelaxed('MH-12-AB-1234'), 'MH-12-AB-1234');
      expect(_typedRelaxed('MH12/AB.1234'), 'MH12/AB.1234');
    });

    test('still upper-cases and caps at maxLength', () {
      expect(_typedRelaxed('mh 12 ab 1234'), 'MH 12 AB 1234');
      expect(_typedRelaxed('MH 12 AB 1234 XYZ').length,
          VehicleNumber.maxLength);
    });

    test('a naturally-typed plate validates', () {
      // Separators are stripped by normalize() before matching.
      expect(VehicleNumber.validate(_typedRelaxed('MH 12 AB 1234')), isNull);
      expect(VehicleNumber.validate(_typedRelaxed('MH-12-AB-1234')), isNull);
    });

    test('free text starting with two letters ALSO validates', () {
      // Consequence of the rule as specified: past the two-letter prefix
      // nothing is constrained, and normalize() drops the spaces, so this
      // reaches validate() as "MHMYREDCAR" and passes. Recorded deliberately —
      // if this should be rejected, the rule needs a structural constraint back.
      expect(VehicleNumber.validate(_typedRelaxed('MH my red car')), isNull);
    });

    test('what cannot be typed still cannot validate', () {
      // The prefix is the one thing both layers agree to police.
      expect(_typedRelaxed('12 MH 1234').startsWith('MH'), isTrue);
      expect(VehicleNumber.validate('12MH1234'), isNotNull);
    });
  });

  group('VehicleNumber.validate', () {
    test('accepts the common plate layouts', () {
      for (final plate in ['MH12AB1234', 'DL1CAB1234', 'KA05MC1234', 'MH12A1234']) {
        expect(VehicleNumber.validate(plate), isNull, reason: plate);
      }
    });

    test('accepts layouts the old structural regex wrongly rejected', () {
      // Regression: `^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{1,4}$` refused all of
      // these even though the field let every character be typed.
      for (final plate in [
        'DF1234', // special / temporary registration
        'MHAB1234', // no district digits
        'MH12ABCD1234', // series longer than 3
        'MH12AB123456', // number longer than 4
        'MH12AB1234X', // trailing character
        'ABCDEFGHIJ', // letters throughout
      ]) {
        expect(VehicleNumber.validate(plate), isNull, reason: plate);
      }
    });

    test('accepts a plate that still carries separators', () {
      expect(VehicleNumber.validate('GJ-01-AB-1234'), isNull);
      expect(VehicleNumber.validate('gj 01 ab 1234'), isNull);
    });

    test('rejects empty values and anything not starting with two letters', () {
      expect(VehicleNumber.validate(null), isNotNull);
      expect(VehicleNumber.validate(''), isNotNull);
      expect(VehicleNumber.validate('   '), isNotNull);
      expect(VehicleNumber.validate('1234'), isNotNull);
      expect(VehicleNumber.validate('1MH234'), isNotNull);
      expect(VehicleNumber.validate('M1H234'), isNotNull);
    });

    test('rejects a value longer than maxLength', () {
      // Reachable from a saved profile / API payload, which never passed
      // through the field's formatters.
      expect(VehicleNumber.validate('MH' + '1' * VehicleNumber.maxLength),
          isNotNull);
    });

    test('accepts a bare two-letter prefix', () {
      // Documented consequence of the rule: nothing is required after the
      // two letters.
      expect(VehicleNumber.validate('MH'), isNull);
    });

    test('rejects the BH series, which the typing rule cannot produce', () {
      // Documented limitation: BH plates start with two digits.
      expect(VehicleNumber.validate('22BH1234AA'), isNotNull);
    });
  });

  group('emergency screen: submit gate and stored value', () {
    // The emergency form's Next button is gated on `VehicleNumber.validate(v)
    // == null` and it stores `VehicleNumber.normalize(v)`. These lock in that
    // pairing: anything the button lets through must store a canonical plate.
    bool gateOpen(String typed) => VehicleNumber.validate(typed) == null;

    test('an empty vehicle number keeps the button disabled', () {
      // Regression: the gate used to accept empty, so Next looked enabled on a
      // form that submit() would reject with a snackbar.
      expect(gateOpen(''), isFalse);
      expect(gateOpen('   '), isFalse);
    });

    test('a single letter keeps the button disabled', () {
      expect(gateOpen('M'), isFalse);
      // ...but a two-letter prefix is enough — see the note on VehicleNumber.
      expect(gateOpen('MH'), isTrue);
      expect(gateOpen('MH 12'), isTrue);
    });

    test('a naturally-typed plate opens the gate and stores canonically', () {
      const typed = 'MH 12 AB 1234';
      expect(gateOpen(typed), isTrue);
      // What reaches the backend must match every other screen's format.
      expect(VehicleNumber.normalize(typed), 'MH12AB1234');
    });

    test('separators never survive into the stored value', () {
      expect(VehicleNumber.normalize('MH-12-AB-1234'), 'MH12AB1234');
      expect(VehicleNumber.normalize('mh 12 ab 1234'), 'MH12AB1234');
    });
  });

  group('VehicleNumber.isValidOrEmpty', () {
    test('treats empty as not-yet-an-error', () {
      expect(VehicleNumber.isValidOrEmpty(''), isTrue);
      expect(VehicleNumber.isValidOrEmpty(null), isTrue);
    });

    test('agrees with validate on non-empty input', () {
      expect(VehicleNumber.isValidOrEmpty('MH12AB1234'), isTrue);
      expect(VehicleNumber.isValidOrEmpty('1234'), isFalse);
      expect(VehicleNumber.isValidOrEmpty('M1H2'), isFalse);
    });
  });
}
