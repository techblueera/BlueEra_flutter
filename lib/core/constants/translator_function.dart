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
  var currentTitleText = "".obs;
  var currentText = "".obs;
  var isLoading = false.obs;
  String originalText = "";
  String originalTitleText = "";

  // Set the text safely
  void loadText(String title,String text) {
    originalText = text;
    originalTitleText = title;
    // Use .value but don't trigger logic that calls refresh during build
    if (currentTitleText.value.isEmpty) {
      currentTitleText.value = text;
    }
    if (currentText.value.isEmpty) {
      currentText.value = text;
    }
  }


  void toggleTranslation() async {
    if (isTranslated.value) {
      // Toggle back to original
      currentTitleText.value = originalTitleText;
      currentText.value = originalText;
      isTranslated.value = false;
    } else {

      // Translate to English (or Hindi if original is English)
      isLoading.value = true;

      // Determine target language based on current content
      String targetLanguage = translator.isEnglishText(originalText) ? 'hi' : 'en';
      String targetTitleLanguage = translator.isEnglishText(originalTitleText) ? 'hi' : 'en';

      String result = await translator.translateToOtherLanguage(originalText, targetLanguage);
      String resultTitle = await translator.translateToOtherLanguage(originalTitleText, targetTitleLanguage);

      currentText.value = result;
      currentTitleText.value = resultTitle;
      isTranslated.value = true;
      isLoading.value = false;
    }
  }
}