import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/languge_list_controller.dart';

class ChangeLanguageScreen extends StatelessWidget {
  final LanguageListController controller = Get.put(LanguageListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Change App Language',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.languages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language_outlined, size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('No languages found'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchLanguages(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.languages.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lang = controller.languages[index];
            return Obx(() {
              final isSelected = controller.selectedCode.value == lang.code;
              final isDownloading = controller.isLanguageDownloading(lang.code);
              final isDownloaded = controller.isLanguageDownloaded(lang.code);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Color(0xFF007AFF), width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.selectLanguage(lang.code),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Color(0xFF007AFF) : Color(0xFFD1D1D6),
                                width: 2,
                              ),
                              color: Colors.white,
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              lang.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1C1C1E),
                                letterSpacing: -0.24,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (!isDownloading && !isDownloaded) {
                                _showDownloadDialog(context, lang.code, lang.name);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              child: isDownloading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF8E8E93),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isDownloaded
                                          ? Icons.check_circle
                                          : Icons.file_download_outlined,
                                      size: 20,
                                      color: isDownloaded
                                          ? Color(0xFF34C759)
                                          : Color(0xFF8E8E93),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }

  void _showDownloadDialog(BuildContext context, String langCode, String langName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: 320,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Download Language Pack',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'To use this language, please\ndownload the required language\nfiles.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: BorderSide(color: Color(0xFF007AFF), width: 1),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.downloadLanguage(langCode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF007AFF),
                          padding: EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
