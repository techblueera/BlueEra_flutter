import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

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
  static final String linkRegex =   r'^(https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}([\/\w\.-]*)*\/?$';

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
    bool regex = RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(value);
    if (value == null) {
      return AppStrings.emailIsRequired;
    } else if (regex == false) {
      return AppStrings.pleaseEnterValidEmail;
    }

    return null;
  }

  emptyValidation(value) {
    if (value.toString().isEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  /// PHONE VALIDATION METHOD
  static String? validatePhone(value) {
    bool regex = RegExp(r"\d{10}").hasMatch(value);
    if (value == '') {
      return AppStrings.mobileIsRequired;
    } else if (regex == false) {
      return AppStrings.mobileIsRequired;
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

    return null;
  }


 static bool isValidURL(String url) {
    final Uri? uri = Uri.tryParse(url);

    return uri != null && uri.isAbsolute && (uri.hasScheme && uri.hasAuthority);
  }

 static String? urlValidation(value) {
    if (value == null || value.trim().isEmpty) {
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
    if (value == null || value.isEmpty) return 'Product description is required';
    if (value.length <= 20) return 'Product description name must be at least 20 characters';
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


}



String removeSpaceFromString(String data) {
  return data.toLowerCase().replaceAll(' ', '');
}
