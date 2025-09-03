import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinkInput extends StatefulWidget {
  const SocialLinkInput({super.key});

  @override
  State<SocialLinkInput> createState() => _SocialLinkInputState();
}

class _SocialLinkInputState extends State<SocialLinkInput> {
  final TextEditingController _linkController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedIcon;
  List<Map<String, String>> savedLinks = [];

  final Map<String, String> iconAssets = {
    'YouTube': 'assets/svg/SocialMediaIcon3.svg',
    'X': 'assets/svg/SocialMediaIcon2.svg',
    'LinkedIn': 'assets/svg/SocialMediaIcon4.svg',
    'Instagram': 'assets/svg/SocialMediaIcon1.svg',
  };

  void onIconSelect(String platform) {
    setState(() {
      selectedIcon = platform;
      _linkController.clear();
    });
  }

  bool isValidURL(String url) {
    final Uri? uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute && (uri.hasScheme && uri.hasAuthority);
  }

  void onSave() {
    if (_formKey.currentState?.validate() != true || selectedIcon == null)
      return;
    if (savedLinks.length >= 5) return;

    setState(() {
      savedLinks.add({
        'platform': selectedIcon!,
        'link': _linkController.text.trim(),
      });
      _linkController.clear();
      selectedIcon = null;
    });
  }

  Future<void> _launchLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch link")),
      );
    }
  }

  void onDelete(int index) {
    setState(() {
      savedLinks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue35,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Other Social Media Link's (Optional)",
                  style: TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                
                Row(
                  children: iconAssets.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => onIconSelect(entry.key),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedIcon == entry.key
                              ? AppColors.blue3F
                              : Colors.transparent,
                        ),
                        child: SvgPicture.asset(
                          entry.value,
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _linkController,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a link';
                    } else if (!isValidURL(value.trim())) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.grey80,
                    hintText: "Paste ${selectedIcon ?? ''} URL here",
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: selectedIcon != null
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              iconAssets[selectedIcon]!,
                              width: 20,
                              height: 20,
                              color: AppColors.white,
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: AppColors.grey80),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: AppColors.grey80),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: AppColors.blueDF),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    backgroundColor: AppColors.blueDF,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text("Save"),
                ),

                const SizedBox(height: 16),

                if (savedLinks.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saved Links:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(savedLinks.length, (index) {
                        final item = savedLinks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                iconAssets[item['platform']]!,
                                width: 20,
                                height: 20,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _launchLink(item['link']!),
                                  child: Text(
                                    item['link'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.blueDF,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.red),
                                onPressed: () => onDelete(index),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
