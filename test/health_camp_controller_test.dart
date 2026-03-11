import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthCamp Model', () {
    test('fromJson parses images correctly', () {
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
      };

      final camp = HealthCamp.fromJson(json);

      expect(camp.id, "123");
      expect(camp.title, "Free Checkup");
      expect(camp.images, isNotNull);
      expect(camp.images!.length, 2);
      expect(camp.images![0], "img1.jpg");
    });

    test('fromJson handles null images', () {
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
      expect(camp.location, isNull);
      expect(camp.testDiscounts, isNull);
    });

    test('toJson includes images as URL strings', () {
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
        images: [
          "https://s3.example.com/img1.jpg",
          "https://s3.example.com/img2.jpg"
        ],
      );

      final json = camp.toJson();

      expect(json["images"], isA<List<String>>());
      expect(json["images"].length, 2);
    });

    test('toJson excludes null optional fields', () {
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

      expect(json.containsKey("images"), false);
      expect(json.containsKey("location"), false);
      expect(json.containsKey("testDiscounts"), false);
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

  group('HealthCampLocation Model', () {
    test('fromJson parses correctly', () {
      final json = {
        "name": "Health Center",
        "type": "Point",
        "coordinates": [72.8777, 19.0760],
      };

      final loc = HealthCampLocation.fromJson(json);

      expect(loc.name, "Health Center");
      expect(loc.type, "Point");
      expect(loc.coordinates!.length, 2);
      expect(loc.coordinates![0], 72.8777);
      expect(loc.coordinates![1], 19.0760);
    });

    test('toJson produces correct structure', () {
      final loc = HealthCampLocation(
        name: "Clinic",
        type: "Point",
        coordinates: [72.5, 19.1],
      );

      final json = loc.toJson();

      expect(json["name"], "Clinic");
      expect(json["type"], "Point");
      expect(json["coordinates"], [72.5, 19.1]);
    });

    test('toJson defaults type to Point', () {
      final loc = HealthCampLocation(
        name: "Place",
        coordinates: [0, 0],
      );

      final json = loc.toJson();
      expect(json["type"], "Point");
    });
  });

  group('Test Model', () {
    test('fromJson parses full test object', () {
      final json = {
        "_id": "test123",
        "testName": "CBC Test",
        "groupCategory": "Blood & Routine Tests",
        "customerPrice": 119,
        "testFees": 150,
        "estimatedReportHours": 6,
        "specimen": "Blood",
        "description": "Complete blood count",
        "packageType": "Basic Blood Test",
      };

      final test = Test.fromJson(json);

      expect(test.id, "test123");
      expect(test.testName, "CBC Test");
      expect(test.groupCategory, "Blood & Routine Tests");
      expect(test.customerPrice, 119);
      expect(test.testFees, 150);
      expect(test.estimatedReportHours, 6);
      expect(test.specimen, "Blood");
    });

    test('toJson produces correct structure', () {
      final test = Test(
        id: "t1",
        testName: "Hemoglobin",
        groupCategory: "Blood & Routine Tests",
        testFees: 80,
        customerPrice: 59,
      );

      final json = test.toJson();

      expect(json["_id"], "t1");
      expect(json["testName"], "Hemoglobin");
      expect(json["groupCategory"], "Blood & Routine Tests");
      expect(json["testFees"], 80);
      expect(json["customerPrice"], 59);
    });
  });

  group('TestDiscount Model', () {
    test('fromJson parses populated test object', () {
      final json = {
        "test": {
          "_id": "test123",
          "testName": "CBC Test",
          "groupCategory": "Blood & Routine Tests",
          "customerPrice": 119,
          "testFees": 150,
        },
        "discountType": "percentage",
        "discountValue": 20,
        "_id": "disc1",
      };

      final discount = TestDiscount.fromJson(json);

      expect(discount.test, isNotNull);
      expect(discount.test!.id, "test123");
      expect(discount.test!.testName, "CBC Test");
      expect(discount.discountType, "percentage");
      expect(discount.discountValue, 20);
      expect(discount.id, "disc1");
    });

    test('fromJson handles string test ID', () {
      final json = {
        "test": "test456",
        "discountType": "percentage",
        "discountValue": 10,
      };

      final discount = TestDiscount.fromJson(json);

      expect(discount.test, isNotNull);
      expect(discount.test!.id, "test456");
    });

    test('fromJson handles null test', () {
      final json = {
        "discountType": "percentage",
        "discountValue": 0,
      };

      final discount = TestDiscount.fromJson(json);
      expect(discount.test, isNull);
    });

    test('toJson sends test ID not full object', () {
      final discount = TestDiscount(
        test: Test(id: "t1", testName: "CBC"),
        discountType: "percentage",
        discountValue: 15,
      );

      final json = discount.toJson();

      expect(json["test"], "t1");
      expect(json["discountType"], "percentage");
      expect(json["discountValue"], 15);
      expect(json.containsKey("_id"), false);
    });

    test('toJson defaults discountType and discountValue', () {
      final discount = TestDiscount(test: Test(id: "test789"));

      final json = discount.toJson();

      expect(json["discountType"], "percentage");
      expect(json["discountValue"], 0);
    });
  });

  group('HealthCamp with location and testDiscounts', () {
    test('fromJson parses full API payload with populated tests', () {
      final json = {
        "_id": "camp1",
        "title": "Full Camp",
        "description": "Complete",
        "sqFoot": 500,
        "price": 999,
        "discountPrice": 799,
        "startDate": "2026-06-01",
        "endDate": "2026-06-05",
        "startTime": "08:00 AM",
        "laboratoryId": "lab1",
        "images": ["https://s3.example.com/a.jpg"],
        "location": {
          "name": "City Hospital",
          "type": "Point",
          "coordinates": [72.8777, 19.0760],
        },
        "testDiscounts": [
          {
            "test": {
              "_id": "t1",
              "testName": "CBC",
              "groupCategory": "Blood & Routine Tests",
              "customerPrice": 59,
              "testFees": 80,
              "estimatedReportHours": 4,
              "specimen": "Blood",
            },
            "discountType": "percentage",
            "discountValue": 10,
            "_id": "disc1",
          },
          {
            "test": {
              "_id": "t2",
              "testName": "Lipid Profile",
              "groupCategory": "Blood & Routine Tests",
              "customerPrice": 299,
              "testFees": 350,
            },
            "discountType": "percentage",
            "discountValue": 25,
            "_id": "disc2",
          },
        ],
      };

      final camp = HealthCamp.fromJson(json);

      expect(camp.location, isNotNull);
      expect(camp.location!.name, "City Hospital");
      expect(camp.location!.coordinates![0], 72.8777);
      expect(camp.testDiscounts, isNotNull);
      expect(camp.testDiscounts!.length, 2);
      expect(camp.testDiscounts![0].test!.id, "t1");
      expect(camp.testDiscounts![0].test!.testName, "CBC");
      expect(camp.testDiscounts![0].test!.groupCategory, "Blood & Routine Tests");
      expect(camp.testDiscounts![0].discountValue, 10);
      expect(camp.testDiscounts![1].test!.id, "t2");
      expect(camp.testDiscounts![1].discountValue, 25);
    });

    test('toJson includes location and testDiscounts with test IDs', () {
      final camp = HealthCamp(
        title: "Camp",
        description: "D",
        sqFoot: 100,
        price: 100,
        discountPrice: 50,
        startDate: "2026-06-01",
        endDate: "2026-06-02",
        startTime: "09:00 AM",
        laboratoryId: "lab1",
        images: ["url1"],
        location: HealthCampLocation(
          name: "Place",
          type: "Point",
          coordinates: [72.0, 19.0],
        ),
        testDiscounts: [
          TestDiscount(
            test: Test(id: "t1", testName: "CBC"),
            discountType: "percentage",
            discountValue: 10,
          ),
        ],
      );

      final json = camp.toJson();

      expect(json["location"]["name"], "Place");
      expect(json["location"]["type"], "Point");
      expect(json["location"]["coordinates"], [72.0, 19.0]);
      expect(json["testDiscounts"].length, 1);
      expect(json["testDiscounts"][0]["test"], "t1");
      expect(json["testDiscounts"][0]["discountValue"], 10);
    });

    test('fromJson with mixed test discount formats', () {
      final json = {
        "_id": "camp2",
        "title": "Mixed Camp",
        "description": "Test",
        "sqFoot": 100,
        "price": 100,
        "discountPrice": 50,
        "startDate": "2026-06-01",
        "endDate": "2026-06-02",
        "startTime": "09:00 AM",
        "laboratoryId": "lab1",
        "testDiscounts": [
          {
            "test": "simple_id_string",
            "discountType": "percentage",
            "discountValue": 5,
          },
          {
            "test": {
              "_id": "populated_id",
              "testName": "Full Test",
              "groupCategory": "Diagnostics & Imaging",
            },
            "discountType": "percentage",
            "discountValue": 15,
          },
        ],
      };

      final camp = HealthCamp.fromJson(json);

      expect(camp.testDiscounts!.length, 2);
      expect(camp.testDiscounts![0].test!.id, "simple_id_string");
      expect(camp.testDiscounts![0].test!.testName, isNull);
      expect(camp.testDiscounts![1].test!.id, "populated_id");
      expect(camp.testDiscounts![1].test!.testName, "Full Test");
      expect(camp.testDiscounts![1].test!.groupCategory, "Diagnostics & Imaging");
    });
  });
}
