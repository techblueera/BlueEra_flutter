import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthCamp Model', () {
    test('fromJson parses images and testCategories correctly', () {
      final json = {
        "_id": "123",
        "title": "Free Checkup",
        "description": "A health camp",
        "sqFoot": 200,
        "price": 499,
        "discountPrice": 399,
        "startDate": "2026-04-01T00:00:00.000",
        "endDate": "2026-04-05T00:00:00.000",
        "startTime": "09:00 AM",
        "laboratoryId": "lab123",
        "images": ["img1.jpg", "img2.jpg"],
        "testCategories": ["Blood & Routine Tests", "Diagnostics & Imaging"],
      };

      final camp = HealthCamp.fromJson(json);

      expect(camp.id, "123");
      expect(camp.title, "Free Checkup");
      expect(camp.images, isNotNull);
      expect(camp.images!.length, 2);
      expect(camp.images![0], "img1.jpg");
      expect(camp.testCategories, isNotNull);
      expect(camp.testCategories!.length, 2);
      expect(camp.testCategories![0], "Blood & Routine Tests");
    });

    test('fromJson handles null images and testCategories', () {
      final json = {
        "_id": "456",
        "title": "Camp",
        "description": "Desc",
        "sqFoot": 100,
        "price": 0,
        "discountPrice": 0,
        "startDate": "2026-04-01T00:00:00.000",
        "endDate": "2026-04-05T00:00:00.000",
        "startTime": "10:00 AM",
        "laboratoryId": "lab456",
      };

      final camp = HealthCamp.fromJson(json);

      expect(camp.images, isNull);
      expect(camp.testCategories, isNull);
    });

    test('toJson includes testCategories when present', () {
      final camp = HealthCamp(
        title: "Test Camp",
        description: "Desc",
        sqFoot: 100,
        price: 200,
        discountPrice: 150,
        startDate: "2026-04-01",
        endDate: "2026-04-05",
        startTime: "09:00 AM",
        laboratoryId: "lab1",
        testCategories: ["Blood & Routine Tests"],
      );

      final json = camp.toJson();

      expect(json.containsKey("testCategories"), true);
      expect(json["testCategories"], ["Blood & Routine Tests"]);
    });

    test('toJson excludes testCategories when null', () {
      final camp = HealthCamp(
        title: "Test Camp",
        description: "Desc",
        sqFoot: 100,
        price: 200,
        discountPrice: 150,
        startDate: "2026-04-01",
        endDate: "2026-04-05",
        startTime: "09:00 AM",
        laboratoryId: "lab1",
      );

      final json = camp.toJson();

      expect(json.containsKey("testCategories"), false);
    });

    test('toJson excludes id when null', () {
      final camp = HealthCamp(
        title: "No ID Camp",
        description: "Desc",
        sqFoot: 50,
        price: 100,
        discountPrice: 80,
        startDate: "2026-05-01",
        endDate: "2026-05-03",
        startTime: "08:00 AM",
        laboratoryId: "lab2",
      );

      final json = camp.toJson();

      expect(json.containsKey("_id"), false);
    });

    test('toJson includes id when present', () {
      final camp = HealthCamp(
        id: "abc",
        title: "Camp",
        description: "Desc",
        sqFoot: 50,
        price: 100,
        discountPrice: 80,
        startDate: "2026-05-01",
        endDate: "2026-05-03",
        startTime: "08:00 AM",
        laboratoryId: "lab2",
      );

      final json = camp.toJson();

      expect(json["_id"], "abc");
    });
  });
}
