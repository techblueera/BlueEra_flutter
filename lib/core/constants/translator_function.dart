import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:get/get.dart';

class CustomTranslator {
  final translator = GoogleTranslator();

  Future<String> translateToOtherLanguage(String input,String localeCode) async {
    // var input = "Hola, ¿cómo estás?";
    try {
      var translation = await translator.translate(input, to: localeCode);
      log(translation.text);
      return translation.text;
    } catch (e) {
      return input;
    }
    // Outputs: Hello, how are you?
  }

  bool isTranslationRequired(String text,Locale locale) {
    if (text == '') {
      return true;
    }

    // Check if all characters in the text are within the ASCII range (a-z, A-Z, space, etc.)
    final asciiRange = locale.languageCode == 'en'? RegExp(r'^[\x00-\x7F]+$'):RegExp(r'^[\u0900-\u097F\s]+$');

    return asciiRange.hasMatch(text);
  }

  bool isEnglishText(String text) {
    if (text == '') {
      return true;
    }

    // Check if all characters in the text are within the ASCII range (a-z, A-Z, space, etc.)
    final asciiRange = RegExp(r'^[\x00-\x7F]+$');

    return asciiRange.hasMatch(text);
  }
}





class FeedTranslationController extends GetxController {
  final CustomTranslator translator = CustomTranslator();
  // final CustomTranslator translator = CustomTranslator();

  var isTranslated = false.obs;
  var currentText = "".obs;
  var isLoading = false.obs;
  String originalText = "";

  // Set the text safely
  void loadText(String text) {
    originalText = text;
    // Use .value but don't trigger logic that calls refresh during build
    if (currentText.value.isEmpty) {
      currentText.value = text;
    }
  }
  // // Observables to track state
  // var isTranslated = false.obs;
  // var currentText = "".obs;
  // var isLoading = false.obs;
  //
  // // Store the original text to allow toggling back
  // String originalText = "";
  //
  // void init(String text) {
  //   originalText = text;
  //   currentText.value = text;
  // }

  void toggleTranslation() async {
    if (isTranslated.value) {
      // Toggle back to original
      currentText.value = originalText;
      isTranslated.value = false;
    } else {

      // Translate to English (or Hindi if original is English)
      isLoading.value = true;

      // Determine target language based on current content
      String targetLanguage = translator.isEnglishText(originalText) ? 'hi' : 'en';

      String result = await translator.translateToOtherLanguage(originalText, targetLanguage);

      currentText.value = result;
      isTranslated.value = true;
      isLoading.value = false;
    }
  }
}