// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'package:translator/translator.dart';
//
// class CustomTranslator {
//   final translator = GoogleTranslator();
//
//   Future<String> translateToOtherLanguage(String input,String localeCode) async {
//     // var input = "Hola, ¿cómo estás?";
//     try {
//       var translation = await translator.translate(input, to: localeCode);
//       log(translation.text);
//       return translation.text;
//     } catch (e) {
//       return input;
//     }
//     // Outputs: Hello, how are you?
//   }
//
//   bool isTranslationRequired(String text,Locale locale) {
//     if (text == '') {
//       return true;
//     }
//
//     // Check if all characters in the text are within the ASCII range (a-z, A-Z, space, etc.)
//     final asciiRange = locale.languageCode == 'en'? RegExp(r'^[\x00-\x7F]+$'):RegExp(r'^[\u0900-\u097F\s]+$');
//
//     return asciiRange.hasMatch(text);
//   }
//
//   bool isEnglishText(String text) {
//     if (text == '') {
//       return true;
//     }
//
//     // Check if all characters in the text are within the ASCII range (a-z, A-Z, space, etc.)
//     final asciiRange = RegExp(r'^[\x00-\x7F]+$');
//
//     return asciiRange.hasMatch(text);
//   }
// }
