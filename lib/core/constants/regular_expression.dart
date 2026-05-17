import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegularExpressionUtils {
  ///IN USED..
  static String emailPattern = r"[a-zA-Z0-9$_@.-]";
  static String alphabetSpacePatternDigit = r"[a-zA-Z0-9$_@.-]";
  static String alphabetSpacePatternDigitSpace = r"[a-zA-Z0-9$-/\_@. ]";
  static String alphabetSpacePattern = "[a-zA-Z-0-9 ]";
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

  static String? validateVehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle number is required.';
    }

    // Standard Indian plate (e.g. MH12AB1234) OR a `DF` prefix followed by
    // digits (e.g. DF1234) used for special/temporary registrations.
    final regex =
        RegExp(r'^([A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{1,4}|DF[0-9]+)$');

    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return 'Please enter a valid vehicle number (e.g. MH12AB1234 or DF1234).';
    }

    return null;
  }

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
