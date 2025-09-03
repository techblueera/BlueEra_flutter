import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';

class HttpsTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText,title;
  final OnChangeString? onChange;
  final bool isUrlValidate;
  final bool? isYoutubeValidation;
  final Widget? pIcon;

  const HttpsTextField({
    super.key,
    required this.controller,
    this.isUrlValidate = false,
    required this.hintText,
    this.title,
    this.onChange,
    this.pIcon,
    this.isYoutubeValidation,
  });

  @override
  State<HttpsTextField> createState() => _HttpsTextFieldState();
}

class _HttpsTextFieldState extends State<HttpsTextField> {
  bool _wasEmpty = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_prependHttps);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_prependHttps);
    super.dispose();
  }
  void _prependHttps() {
    final text = widget.controller.text;

    if (text.isEmpty) {
      _wasEmpty = true;
      return;
    }

    // Block http:// but allow https:// only
    if (text.startsWith('http://')) {
      widget.controller.value = TextEditingValue(
        text: '', // Clear text
        selection: const TextSelection.collapsed(offset: 0),
      );
      commonSnackBar(message: 'Only https:// links are allowed');
    }
    else if (_wasEmpty &&
        // !text.startsWith('http://') &&
        !text.startsWith('https://')) {
      final newText = 'https://$text';
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    _wasEmpty = false;
  }

  void _prependHttps_() {
    final text = widget.controller.text;

    if (text.isEmpty) {
      _wasEmpty = true;
      return;
    }

    if (_wasEmpty &&
        // !text.startsWith('http://') &&
        !text.startsWith('https://')) {
      final newText = 'https://$text';
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    _wasEmpty = false;
  }

  @override
  Widget build(BuildContext context) {
    if(widget.isYoutubeValidation??false)
      {
        return CommonTextField(
          textEditController: widget.controller,
          hintText: widget.hintText,
          isValidate: widget.isUrlValidate,
          onChange: widget.onChange,
          validationType: ValidationTypeEnum.Url,
          pIcon: widget.pIcon,
          title: widget.title,
          validator: (value){
            if (value == null || value.isEmpty) {
              return 'Please enter a YouTube link';
            }
            if (!value.startsWith('https://')) {
              return 'Only https:// links are allowed';
            }

            if (!isValidYouTubeUrl(value)) {
              return 'Enter a valid YouTube URL';
            }
            return null;
          },

        );

      }
    return CommonTextField(
      textEditController: widget.controller,
      hintText: widget.hintText,
      isValidate: widget.isUrlValidate,
      onChange: widget.onChange,
      validationType: ValidationTypeEnum.Url,
      pIcon: widget.pIcon,
      title: widget.title,

    );
  }
  bool isValidYouTubeUrl(String url) {
    final RegExp youTubeRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w\-]{11}(&\S*)?$',
      caseSensitive: false,
    );
    return youTubeRegex.hasMatch(url.trim());
  }
}
