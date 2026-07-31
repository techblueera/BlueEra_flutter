import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RegularExpressionUtils {
  ///IN USED..
  static String emailPattern = r"[a-zA-Z0-9$_@.-]";
  static String alphabetSpacePatternDigit = r"[a-zA-Z0-9$_@.-]";
  static String alphabetSpacePatternDigitSpace = r"[a-zA-Z0-9$-/\_@. ]";
  static String alphabetSpacePattern = "[a-zA-Z-0-9 ]";
  static String alphabetOnlySpacePattern = "[a-zA-Z ]";
  static String alphabetSpacePattern_ = "[a-zA-Z-& ]";
  static String alphabetPattern = "[a-zA-Z]";
  static String alphabetPatternSpace = "[a-zA-Z ]";
  static String alphanumericPattern = "[a-zA-Z0-9]";
  static String discount = '[0-9]{0,3}';
  static String digitsPattern = r"[0-9]";
  static String skills = r'^[^\s][a-zA-Z0-9+\.\#_\-]*$';
  static String pinCodeRegExp = r'^[1-9][0-9]{5}$';

  static final String courseNameRegex = r"^[a-zA-Z .'-]*$";
  static final String institutionNameRegex = r"^[a-zA-Z0-9 .'-]*$";
  static final String phoneWithPrefixPattern = r'^[+0-9]*$';
  static final String linkRegex =
      r'^(https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}([\/\w\.-]*)*\/?$';

  static final String date = r"[0-9a-zA-Z/,\- ]";
  bool containsCharter(String text) {
    // બધા http links શોધો
    final httpRegex = RegExp(RegularExpressionUtils.alphabetSpacePattern);
    return httpRegex.hasMatch(text);
  }
}

bool containsHttpButNotHttps(String text) {
  // બધા http links શોધો
  final httpRegex = RegExp(r'http:\/\/[^\s]+');
  return httpRegex.hasMatch(text);
}

/// VALIDATION METHOD
class ValidationMethod {
  /// EMAIL VALIDATION METHOD
  static String? validateEmail(value) {
    if (value == null || value.toString().trim().isEmpty) {
      return AppStrings.emailIsRequired.tr;
    }

    final email = value.toString().trim();

    // Standard email regex (RFC 5322 compliant)
    bool regex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);

    if (!regex) {
      return AppStrings.pleaseEnterValidEmail.tr;
    }

    // Check the local part (before the @)
    final localPart = email.split('@')[0];

    // Optional: Reject emails that are ONLY numbers (e.g., 12345@domain.com)
    // Remove this block if you want to allow all-numeric local parts
    if (RegExp(r'^[0-9]+$').hasMatch(localPart)) {
      return AppStrings.pleaseEnterValidEmail.tr;
    }

    return null;
  }
  /*static String? validateEmail(value) {
    if (value == null || value.toString().trim().isEmpty) {
      return AppStrings.emailIsRequired.tr;
    }

    final email = value.toString().trim();

    // Standard email regex
    bool regex = RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);

    if (regex == false) {
      return AppStrings.pleaseEnterValidEmail.tr;
    }

    // Additional check to reject invalid TLDs like .vop or .vkm (as per user request)
    // And optionally enforce @gmail.com if that's the strict requirement
    if (!email.toLowerCase().endsWith('@gmail.com')) {
      return "Only @gmail.com emails are allowed";
    }

    final localPart = email.split('@')[0];
    if (RegExp(r'^[0-9]+$').hasMatch(localPart)) {
      return AppStrings.pleaseEnterValidEmail.tr;
    }

    return null;
  }*/

  emptyValidation(value) {
    if (value.toString().isEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  /// PHONE VALIDATION METHOD
  static String? validatePhone(value) {
    if (value == null || value.isEmpty) {
      return AppStrings.mobileIsRequired.tr;
    }

    // Indian mobile numbers: exactly 10 digits, starting with 6, 7, 8, or 9.
    // Anchored with ^ and $ to ensure no extra characters are present.
    bool regex = RegExp(r"^[6-9]\d{9}$").hasMatch(value);

    if (regex == false) {
      return AppStrings.enterValidPhoneNumber.tr;
    }

    return null;
  }

  /// PHONE VALIDATION METHOD
  static String? validateLandline(String? value) {
    if (value == null || value.isEmpty) {
      return "Required";
    }

    // Match only numbers, length between 6 and 8
    bool regex = RegExp(r'^\d{6,8}$').hasMatch(value);

    if (!regex) {
      return "Landline must be 6 to 8 digits";
    }

    if (RegExp(r'^0+$').hasMatch(value)) {
      return "Landline cannot be all zeros";
    }

    return null;
  }

  static bool isValidURL(String url) {
    return RegExp(RegularExpressionUtils.linkRegex).hasMatch(url);
  }

  static String? urlValidation(value, {bool isOptional = true}) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;
      return 'Please enter a link';
    } else if (!isValidURL(value.trim())) {
      return 'Enter a valid URL';
    }

    return null;
  }

  static String? userNameValidation(String? value) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    } else if (!alphanumericRegex.hasMatch(value.trim())) {
      return 'Username can only contain letters and numbers';
    }

    return null;
  }

  String? validateProductName(String? value) {
    if (value == null || value.isEmpty) return 'Product name is required';
    if (value.length <= 5) return 'Product name must be at least 5 characters';
    return null;
  }

  String? validateBrandName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 3) return 'Brand name must be at least 3 characters';
    return null;
  }

  String? validateProductDescription(String? value) {
    if (value == null || value.isEmpty)
      return 'Product description is required';
    if (value.length <= 15)
      return 'Product description name must be at least 15 characters';
    return null;
  }

  String? validateMinPrice(String? value, TextEditingController maxPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return "Min price is required";
    }

    final min = int.tryParse(value);
    if (min == null || min <= 0) {
      return "Enter valid min price";
    }

    final max = int.tryParse(maxPriceCtrl.text);
    if (max != null && min >= max) {
      return "Min must be less than Max";
    }

    return null;
  }

  String? validateMaxPrice(String? value, TextEditingController minPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return "Max price is required";
    }

    final max = int.tryParse(value);
    if (max == null || max <= 0) {
      return "Enter valid max price";
    }

    final min = int.tryParse(minPriceCtrl.text);
    if (min != null && max <= min) {
      return "Max must be greater than Min";
    }

    return null;
  }

  String? validatePrice(String? priceText, String? mrpText) {
    if (priceText == null || priceText.isEmpty) return "Enter price";
    if (mrpText == null || mrpText.isEmpty) return "Enter MRP";

    final price = num.tryParse(priceText.replaceAll('₹', '').trim());
    final mrp = num.tryParse(mrpText.replaceAll('₹', '').trim());

    if (price == null || mrp == null) return "Invalid number";

    if (price > mrp) return "Price cannot be more than MRP";

    return null;
  }

  String? validateMRP(String? value) {
    if (value == null || value.isEmpty) return 'MRP is required';
    if (double.tryParse(value) == null) return 'Please enter a valid price';
    if (double.parse(value) <= 0) return 'MRP must be greater than 0';
    return null;
  }

  String? validateProductWarranty(String? value) {
    if (value == null || value.isEmpty) return 'Product warranty is required';
    return null;
  }

  String? validateFeatures(String? value, int i) {
    if (value == null || value.trim().isEmpty) {
      return "Validation Error, Feature ${i + 1} cannot be empty";
    }
    if (value.length < 20) {
      return "Validation Error, Feature ${i + 1} must be at least 20 characters";
    }
    return null;
  }

  String? validateUserGuideLine(String? value, int i) {
    if (value == null || value.trim().isEmpty) {
      return "Validation Error, User GuideLine ${i + 1} cannot be empty";
    }
    if (value.length < 20) {
      return "Validation Error, User GuideLine ${i + 1} must be at least 20 characters";
    }
    return null;
  }

  String? validateProductExpiration(String? value) {
    if (value == null || value.isEmpty) return 'Product expiration is required';
    return null;
  }

  String? instructionValidation(value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your instructions';
    }
    if (value.length < 10) {
      return "Validation Error, Instructions must be at least 10 characters";
    }

    return null;
  }

  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }

    bool isValid = RegExp(r'^[2-9]{1}[0-9]{11}$').hasMatch(value);
    if (!isValid) {
      return 'Please enter a valid 12-digit Aadhaar number';
    }

    return null;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }

    bool isValid =
        RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase());
    if (!isValid) {
      return 'Please enter a valid PAN number (e.g. ABCDE1234F)';
    }

    return null;
  }

  static String? validateRC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'RC number is required';
    }

    bool isValid = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{1,4}$')
        .hasMatch(value.toUpperCase());
    if (!isValid) {
      return 'Please enter a valid vehicle registration number (e.g. UP32AB1234)';
    }

    return null;
  }

  static String? validateDrivingLicense(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Driving license number is required';
    }

    bool isValid =
        RegExp(r'^[A-Z]{2}[0-9]{2}\d{11,13}$').hasMatch(value.toUpperCase());
    if (!isValid) {
      return 'Please enter a valid driving license number (e.g. DL0420110148936)';
    }

    return null;
  }

  /// Vehicle registration number — see [VehicleNumber], which is the single
  /// definition of what the app accepts. Kept as a named entry point so form
  /// fields can pass `ValidationMethod.validateVehicleNumber` directly.
  static String? validateVehicleNumber(String? value) =>
      VehicleNumber.validate(value);

  String? validatePropertyDescription(String? value) {
    if (value == null || value.isEmpty)
      return 'Property description is required';
    if (value.length <= 20)
      return 'Property description name must be at least 20 characters';
    return null;
  }

  String? validateHomeStayDescription(String? value) {
    if (value == null || value.isEmpty) return 'House description is required';
    if (value.length <= 20)
      return 'House description must be at least 20 characters';
    return null;
  }

  String? validateVehicleDescription(String? value) {
    if (value == null || value.isEmpty)
      return 'Vehicle description is required';
    if (value.length <= 20)
      return 'Vehicle description must be at least 20 characters';
    return null;
  }

  String? validatePin(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN code is required';

    final regex = RegExp(r'^[1-9][0-9]{5}$');

    if (!regex.hasMatch(value.trim())) return 'Enter a valid 6-digit PIN code';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    // Must contain at least 2 letters
    bool hasLetters = RegExp(r'[a-zA-Z]').allMatches(value).length >= 2;
    if (!hasLetters) {
      return 'Please enter a valid name (at least 2 letters)';
    }

    // Validates that the name contains only alphabets, spaces and '
    bool isAllowedChars = RegExp(r"^[a-zA-Z\s']+$").hasMatch(value);
    if (!isAllowedChars) {
      return 'Please enter a valid name (letters only)';
    }

    return null;
  }

  static String? validatePosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Position is required';
    }
    String trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Position must be at least 2 characters long';
    }
    // Must contain at least one letter or number
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) {
      return 'Please enter a valid position (letters/numbers required)';
    }
    return null;
  }

  static String? validateEducation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Education is required';
    }
    String trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Education must be at least 2 characters long';
    }
    // Must contain at least one letter or number
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) {
      return 'Please enter a valid education (letters/numbers required)';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    String trimmed = value.trim();
    if (trimmed.length < 10) {
      return 'Description must be at least 10 characters long';
    }
    // Must contain at least one letter or number
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) {
      return 'Description must contain actual letters or numbers';
    }
    return null;
  }

  static String? validateBankHolderName(String? value) {
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (value == null || value.trim().isEmpty) {
      return 'Enter Bank Holder name';
    }
    if (!nameRegExp.hasMatch(value.trim())) {
      return 'Name should only Alphabetically';
    }
    return null;
  }

  static String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank name is required';
    }
    if (value.trim().length < 2) {
      return 'Bank name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z][a-zA-Z\s.&-]*$').hasMatch(value.trim())) {
      return 'Only letters, spaces, &, -, and . are allowed';
    }

    return null;
  }

  static String? validateAccountNumber(String? value) {
    // 1. Check if null or empty
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }

    final cleanValue = value.trim();

    // 2. Length check (Standard Indian bank accounts are usually 9-18 digits)
    if (cleanValue.length < 9 || cleanValue.length > 18) {
      return 'Enter a valid account number (9 to 18 digits)';
    }

    // 3. Ensure numeric only
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
      return 'Account number must contain only digits';
    }

    return null;
  }

  static String? validateIfscCode(String? value) {
    // 1. Check if null or empty
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }

    // 2. Clean input (remove spaces and convert to uppercase)
    final cleanValue = value.trim().toUpperCase();

    // 3. Length check
    if (cleanValue.length != 11) {
      return 'IFSC code must be exactly 11 characters long';
    }

    // 4. Pattern check (4 letters, a zero, 6 alpha-numeric)
    // Enforcing the 5th character as '0' is crucial.
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleanValue)) {
      return 'Invalid format. Example: SBIN0001234';
    }

    return null;
  }

  static String? validateTradeLicense(String? value) {
    if (value == null || value.isEmpty) {
      return "Trade License number is required";
    }

    // Must be between 5 and 30 characters
    final RegExp licenseRegex = RegExp(r'^[a-zA-Z0-9-/]{5,30}$');

    if (!licenseRegex.hasMatch(value)) {
      return "Invalid Trade License Number (Use A-Z, 0-9, - or /)";
    }

    return null;
  }

  static String? validateGSTIN(String? value) {
    if (value == null || value.isEmpty) {
      return "GSTIN is required";
    }

    if (value.length != 15) {
      return "GSTIN must be exactly 15 characters";
    }

    // Standard GST Regex
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value)) {
      return "Invalid GSTIN format";
    }
    return null;
  }

  static String? validateFSSAI(String? value) {
    if (value == null || value.isEmpty) return "FSSAI number is required";
    if (!RegExp(r'^[0-9]{14}$').hasMatch(value)) {
      return "FSSAI must be exactly 14 digits";
    }
    return null;
  }

  String? professionDescValidation(value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your description';
    }
    if (value.length < 10) {
      return "Validation Error, Instructions must be at least 10 characters";
    }

    return null;
  }

  static String? validatePUCNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter PUC Number';
    }
    // PUC numbers are usually long alphanumeric strings
    if (value.length < 6) {
      return 'Invalid PUC Number';
    }
    // Optional: Check for special characters that shouldn't exist
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Enter only letters and numbers';
    }
    return null;
  }

  static String? referralCodeValidation(String? value) {
    final trimmedValue = value?.trim();

    // 1. Check if empty
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return 'Referral code cannot be empty';
    }

    // 2. Check exact length
    if (trimmedValue.length != 6) {
      return 'Referral code must be exactly 6 characters';
    }

    // 3. Check for valid format (Alphanumeric only)
    // This prevents users from entering spaces, symbols, or emojis
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]+$')
        .hasMatch(trimmedValue)) {
      return "Code must contain both letters and numbers";
    }

    return null; // Valid
  }

  static String? validateStartTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Start time is required'.tr;
    }
    return null;
  }

  static String? validateEndTime(String? startTime, String? endTime) {
    if (endTime == null || endTime.isEmpty) {
      return 'End time is required'.tr;
    }

    if (startTime == null || startTime.isEmpty) {
      return null;
    }

    final start = parseTime(startTime);
    final end = parseTime(endTime);

    if (start == null || end == null) {
      return 'Invalid time format'.tr;
    }

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      return 'End time must be after start time'.tr;
    }

    return null;
  }
}

String removeSpaceFromString(String data) {
  return data.toLowerCase().replaceAll(' ', '');
}

/// The single definition of a vehicle registration number: what the user is
/// allowed to type, and what counts as valid on submit.
///
/// Before this existed the rule lived in three places that had drifted apart —
/// `ValidationMethod.validateVehicleNumber` (uppercased, allowed a `DF` prefix),
/// `ValidationMethod.validateDeliveryVehicleNumber` (case-insensitive, no `DF`,
/// series capped at 2 letters), and a private `vehicleNumberRegExp` on
/// `EmergencyBasicInfoController`. The same plate was accepted on one screen and
/// rejected on another. Everything now routes through here.
///
/// ## Typing rule
///
/// [inputFormatters] enforces it as the user types, so an invalid character
/// simply never appears in the field:
///
///  * the first two characters are letters only (the state code),
///  * everything after is letters or digits,
///  * input is upper-cased,
///  * total length is capped at [maxLength].
///
/// ## What validates
///
/// [validate] applies the SAME rule as the typing filter — two leading letters,
/// then any letters/digits, within [maxLength]. Validation and input agree by
/// construction, so a field can never accept a keystroke it will later reject.
///
/// It deliberately does not model plate structure. Earlier versions required
/// `[state][district][series][number]` (and a `DF…` special case), which turned
/// out to reject real plates users typed — a longer series, extra trailing
/// characters, or any layout outside that one template. See [_plate].
///
/// Separators are normalised away first, so `GJ-01-AB-1234` and `GJ 01 AB 1234`
/// both validate and both store as `GJ01AB1234`.
///
/// The BH series (`22BH1234AA`) is still rejected: it starts with two digits,
/// which the letters-first rule forbids at the input stage too.
///
/// Note this accepts a bare `MH` — the rule as specified puts no lower bound on
/// what follows the two letters.
class VehicleNumber {
  const VehicleNumber._();

  /// Hard cap on the field, matching the `maxLength` the forms pass.
  static const int maxLength = 15;

  /// Two leading letters, then anything — run against the normalised value.
  ///
  /// This deliberately does NOT model `[state][district][series][number]`. It
  /// used to (`^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{1,4}$`), and that rigid shape
  /// rejected real plates the user could legitimately type: anything with a
  /// longer series, extra trailing characters, or a layout outside that one
  /// template failed validation even though the field had accepted every
  /// keystroke. The rule is the same one the typing filter enforces — first two
  /// characters are letters, the rest is free — so what can be typed is exactly
  /// what validates.
  ///
  /// Because [normalize] strips separators first, `[A-Z0-9]*` here covers "any
  /// character or digit" as typed: `MH 12 AB 1234` arrives as `MH12AB1234`.
  ///
  /// The old `DF[0-9]+` special case is gone — it is subsumed by this rule.
  static final RegExp _plate = RegExp(r'^[A-Z]{2}[A-Z0-9]*$');

  /// Upper-cases and strips anything that isn't a letter or a digit, so values
  /// that arrive from outside the field — a saved profile, a pasted plate with
  /// spaces or dashes — are compared in the same shape the field produces.
  static String normalize(String? value) =>
      (value ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Formatters for the field. Pass to `CommonTextField.inputFormatters`.
  ///
  /// Note this REPLACES that widget's default formatter list, so the length
  /// limit is included here rather than relying on `inputLength`.
  static List<TextInputFormatter> get inputFormatters => [
        const _VehicleNumberFormatter(),
        LengthLimitingTextInputFormatter(maxLength),
      ];

  /// Same two-letter prefix rule, but anything goes after it — spaces, dashes,
  /// punctuation — instead of letters and digits only.
  ///
  /// Used by the emergency profile, where the plate is typed once by someone
  /// recalling it rather than copied off a document, so `MH 12 AB 1234` and
  /// `MH-12-AB-1234` should be typeable as written.
  ///
  /// [validate] is UNCHANGED for these fields and still requires a real plate:
  /// it strips the separators via [normalize] before matching, so the relaxed
  /// input is about what the user may type, not about accepting a looser value.
  static List<TextInputFormatter> get relaxedInputFormatters => [
        const _VehicleNumberFormatter(allowAnyAfterPrefix: true),
        LengthLimitingTextInputFormatter(maxLength),
      ];

  /// Form-field validator.
  static String? validate(String? value) {
    final plate = normalize(value);
    if (plate.isEmpty) return AppStrings.emergencyFillVehicle.tr;
    // The length bound is re-checked here, not just left to the field: a value
    // can reach this from a saved profile or an API payload, which never went
    // through the formatters.
    if (plate.length > maxLength || !_plate.hasMatch(plate)) {
      return AppStrings.emergencyInvalidVehicle.tr;
    }
    return null;
  }

  /// Whether [value] is a well-formed plate. Empty counts as valid so callers
  /// driving an "is the form complete" flag can treat a blank optional field as
  /// not-yet-an-error; use [validate] for the field itself.
  static bool isValidOrEmpty(String? value) =>
      normalize(value).isEmpty || validate(value) == null;
}

/// Applies [VehicleNumber]'s typing rule on every keystroke.
///
/// Positional rather than a flat character filter: the first two slots take
/// letters only, so a digit typed into an empty field is dropped instead of
/// landing where the state code belongs. Characters are tested against the
/// position they would occupy in the RESULT, not in the raw input, so deleting
/// the leading letters of `MH12` correctly re-tests `1` and `2`.
class _VehicleNumberFormatter extends TextInputFormatter {
  const _VehicleNumberFormatter({this.allowAnyAfterPrefix = false});

  /// When true, only the two-letter prefix is policed and everything after it
  /// is accepted as typed — see [VehicleNumber.relaxedInputFormatters].
  final bool allowAnyAfterPrefix;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final input = newValue.text.toUpperCase();
    final buffer = StringBuffer();
    // Track the caret: every character dropped from before it shifts it left,
    // otherwise the cursor drifts to the end on any mid-string edit.
    final int caret = newValue.selection.end;
    int newCaret = caret;

    for (int i = 0; i < input.length; i++) {
      final int code = input.codeUnitAt(i);
      final bool isLetter = code >= 0x41 && code <= 0x5A; // A-Z
      final bool isDigit = code >= 0x30 && code <= 0x39; // 0-9
      // Position in the OUTPUT decides what is allowed here. The first two
      // slots are letters-only in both modes; what may follow them is what the
      // two modes differ on.
      final bool allowed = buffer.length < 2
          ? isLetter
          : (allowAnyAfterPrefix || isLetter || isDigit);

      if (allowed && buffer.length < VehicleNumber.maxLength) {
        buffer.write(input[i]);
      } else if (i < caret) {
        newCaret--;
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newCaret.clamp(0, text.length),
      ),
    );
  }
}
