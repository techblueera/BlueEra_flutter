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

  // Covers the major Indian scripts: Devanagari (Hindi/Marathi/Sanskrit),
  // Bengali/Assamese, Gurmukhi (Punjabi), Gujarati, Oriya, Tamil, Telugu,
  // Kannada, Malayalam, Sinhala. Any character in these ranges means the
  // text is NOT pure English and translation should be offered.
  static final RegExp _indicScriptRegex = RegExp(
    r'[\u0900-\u097F'    // Devanagari
    r'\u0980-\u09FF'    // Bengali / Assamese
    r'\u0A00-\u0A7F'    // Gurmukhi
    r'\u0A80-\u0AFF'    // Gujarati
    r'\u0B00-\u0B7F'    // Oriya
    r'\u0B80-\u0BFF'    // Tamil
    r'\u0C00-\u0C7F'    // Telugu
    r'\u0C80-\u0CFF'    // Kannada
    r'\u0D00-\u0D7F'    // Malayalam
    r'\u0D80-\u0DFF'    // Sinhala
    r']',
  );

  bool isTranslationRequired(String text, Locale locale) {
    if (text == '') {
      return true;
    }

    // Detect by presence of any Indic script character, ignoring emojis/symbols.
    final hasIndic = _indicScriptRegex.hasMatch(text);
    if (locale.languageCode == 'en') {
      // "English" if there is no Indic content.
      return !hasIndic;
    } else {
      // Non-English locale: needs translation if any Indic content is present.
      return hasIndic;
    }
  }

  bool isEnglishText(String text) {
    if (text == '') {
      return true;
    }

    // Treat as English ONLY if the text contains no characters from any
    // Indian script. Emojis, punctuation, digits and Latin letters are
    // ignored, so captions like "Hello 😀" are still detected as English,
    // while "வணக்கம்", "ਸਤ ਸ੍ਰੀ ਅਕਾਲ", "નમસ્તે", "নমস্কার", "నమస్తే" etc.
    // are correctly detected as non-English and the Translate button shows.
    return !_indicScriptRegex.hasMatch(text);
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
      currentTitleText.value = title;
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

      // Determine ONE target language for the whole post so title and
      // subtitle never diverge (e.g. Hindi subtitle + English-looking title).
      // Prefer the subtitle's language since the Translate button visibility
      // is driven by the subtitle; fall back to the title if subtitle is empty.
      final String sourceForDetection =
          originalText.trim().isNotEmpty ? originalText : originalTitleText;
      final String targetLanguage =
          translator.isEnglishText(sourceForDetection) ? 'hi' : 'en';

      String result = await translator.translateToOtherLanguage(originalText, targetLanguage);
      String resultTitle = await translator.translateToOtherLanguage(originalTitleText, targetLanguage);

      currentText.value = result;
      currentTitleText.value = resultTitle;
      isTranslated.value = true;
      isLoading.value = false;
    }
  }
}