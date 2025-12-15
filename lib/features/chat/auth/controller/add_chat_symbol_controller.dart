import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../model/contactListModel.dart';
enum PostType { image, video, text }

enum PostVisibility { public, private, custom }

class AddChatSymbolController extends GetxController {
  // Post type selection
  Rx<PostType?> selectedPostType = Rx<PostType?>(PostType.image);

  // File picked
  Rx<File?> selectedFile = Rx<File?>(null);

  // For text post
  TextEditingController textPostController = TextEditingController();

  // Caption
  TextEditingController captionController = TextEditingController();

  // Tag users
  RxList<String> taggedUsers = <String>[].obs;

  // Visibility
  Rx<PostVisibility> visibility = PostVisibility.public.obs;

  // Duration Days
  RxInt selectedDays = 1.obs;

  // Loading
  RxBool isPosting = false.obs;
  RxList<ExistingNotConnected> onTagSelectedList=<ExistingNotConnected>[].obs;
  RxList<ExistingNotConnected> onExceptContactSelectedList=<ExistingNotConnected>[].obs;
  // --- FUNCTIONS ---
  final RxBool showDurationSelector = false.obs;

  void toggleDurationSelector() {
    showDurationSelector.toggle();
  }

  void choosePostType(PostType type) {
    selectedPostType.value = type;

    if (type == PostType.text) {
      selectedFile.value = null; // No media
    }
  }

  void pickFile(File file) {
    selectedFile.value = file;
  }

  void setVisibility(PostVisibility v) {
    visibility.value = v;
  }

  void setDuration(int days) {
    if (days >= 1 && days <= 7) {
      selectedDays.value = days;
    }
  }

  void toggleTagUser(String user) {
    if (taggedUsers.contains(user)) {
      taggedUsers.remove(user);
    } else {
      taggedUsers.add(user);
    }
  }

  Future<void> submitPost() async {
    isPosting.value = true;

    await Future.delayed(const Duration(seconds: 2));

    print("POST TYPE: ${selectedPostType.value}");
    print("FILE: ${selectedFile.value}");
    print("TEXT: ${textPostController.text}");
    print("CAPTION: ${captionController.text}");
    print("VISIBILITY: ${visibility.value}");
    print("DURATION DAYS: ${selectedDays.value}");
    print("TAGGED USERS: $taggedUsers");

    isPosting.value = false;
  }
}
