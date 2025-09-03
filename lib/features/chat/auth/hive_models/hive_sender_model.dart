// hive_sender_model.dart
import 'package:hive/hive.dart';

part 'hive_sender_model.g.dart';

@HiveType(typeId: 13)
class HiveSender extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? profileImage;

  HiveSender({this.id, this.name, this.profileImage});
}
