import 'dart:io';

import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_flag_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_lock_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_pin_archive_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/custom_chat_tab_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  // The controllers load their settings from Hive boxes on init.
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync().path));
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the chat settings controllers outlive the screen that opened first',
      () {
    final lock = ChatLockController.to;
    final flags = ChatFlagController.to;
    final pins = ChatPinArchiveController.to;
    final tabs = CustomChatTabController.to;

    // What GetX does when the route that first registered them closes.
    Get.delete<ChatLockController>();
    Get.delete<ChatFlagController>();
    Get.delete<ChatPinArchiveController>();
    Get.delete<CustomChatTabController>();

    expect(ChatLockController.to, same(lock));
    expect(ChatFlagController.to, same(flags));
    expect(ChatPinArchiveController.to, same(pins));
    expect(CustomChatTabController.to, same(tabs));
  });

  test('logout drops them, so the next account loads its own', () {
    ChatLockController.to;
    ChatFlagController.to;
    ChatPinArchiveController.to;
    CustomChatTabController.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<ChatLockController>(), isFalse);
    expect(Get.isRegistered<ChatFlagController>(), isFalse);
    expect(Get.isRegistered<ChatPinArchiveController>(), isFalse);
    expect(Get.isRegistered<CustomChatTabController>(), isFalse);
  });
}
