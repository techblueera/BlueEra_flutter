import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicalHomeResponseModel parsing', () {
    test('parses full response correctly', () {
      final json = {
        'businessProfile': {
          'id': 'bp1',
          'user_id': 'u1',
          'business_name': 'Test Pharmacy',
          'logo': 'https://example.com/logo.png',
          'business_description': 'A test pharmacy',
          'type_of_business': 'medical',
          'address': '123 Test St',
          'city_state_pincode': 'Delhi, 110001',
          'website_url': 'https://test.com',
          'business_location': {'lat': 28.61, 'lon': 77.21},
          'business_number': {
            'office_mob_no': {'pre': '91', 'number': '9876543210'},
            'office_landline_no': null,
          },
          'owner_details': [
            {'name': 'Owner', 'role_in_business': 'Owner', 'email': 'o@t.com'},
          ],
          'avg_rating': 4.5,
          'total_ratings': 120,
        },
        'aboutUs': null,
        'contact': null,
        'gallery': [
          {'imageUrls': ['https://example.com/g1.png']},
        ],
        'testimonials': null,
        'inventorySummary': {
          'popularProducts': [
            {
              '_id': 'pp1',
              'businessId': 'b1',
              'variant': {
                '_id': 'v1',
                'variantName': '500mg',
                'unit': 'mg',
                'pricing': [
                  {'mrp': 100, 'sellingPrice': 80, 'currency': 'INR'}
                ],
              },
              'product': {
                '_id': 'p1',
                'name': 'Paracetamol',
                'brand': 'Generic',
                'description': 'Pain relief',
                'images': [
                  {'url': 'https://example.com/p1.png'}
                ],
              },
              'batches': {'mrp': 100, 'sellingPrice': 80, 'quantity': 50},
            }
          ],
          'categoriesWithProducts': [
            {
              '_id': 'cat1',
              'name': 'OTC Medicines',
              'key': 'OTC_MEDICINES',
              'isActive': true,
              'level': 0,
              'children': [],
              'products': [
                {
                  '_id': 'cp1',
                  'name': 'Crocin',
                  'description': 'Fever reducer',
                  'brand': 'GSK',
                  'images': [],
                  'variants': [
                    {
                      '_id': 'cv1',
                      'variantName': '650mg',
                      'unit': 'mg',
                      'pricing': [
                        {'mrp': 30, 'sellingPrice': 25}
                      ],
                    }
                  ],
                }
              ],
            }
          ],
        },
      };

      final model = MedicalHomeResponseModel.fromJson(json);

      // Business Profile
      expect(model.businessProfile, isNotNull);
      expect(model.businessProfile!.businessName, 'Test Pharmacy');
      expect(model.businessProfile!.logo, 'https://example.com/logo.png');
      expect(model.businessProfile!.address, '123 Test St');
      expect(model.businessProfile!.avgRating, 4.5);
      expect(model.businessProfile!.totalRatings, '120');

      // Location
      expect(model.businessProfile!.businessLocation, isNotNull);
      expect(model.businessProfile!.businessLocation!.lat, 28.61);
      expect(model.businessProfile!.businessLocation!.lon, 77.21);

      // Phone
      expect(model.businessProfile!.businessNumber, isNotNull);
      expect(
          model.businessProfile!.businessNumber!.formattedMobile, '+91 9876543210');

      // Owner
      expect(model.businessProfile!.ownerDetails, isNotNull);
      expect(model.businessProfile!.ownerDetails!.length, 1);
      expect(model.businessProfile!.ownerDetails!.first.name, 'Owner');
      expect(model.businessProfile!.ownerDetails!.first.email, 'o@t.com');

      // Gallery
      expect(model.gallery, isNotNull);
      expect(model.gallery!.length, 1);

      // Inventory Summary
      expect(model.inventorySummary, isNotNull);

      // Popular Products
      final popular = model.inventorySummary!.popularProducts!;
      expect(popular.length, 1);
      expect(popular.first.product!.name, 'Paracetamol');
      expect(popular.first.batches!.mrp, 100);
      expect(popular.first.batches!.sellingPrice, 80);
      expect(popular.first.variant!.variantName, '500mg');

      // Categories With Products
      final categories = model.inventorySummary!.categoriesWithProducts!;
      expect(categories.length, 1);
      expect(categories.first.name, 'OTC Medicines');
      expect(categories.first.hasProducts, true);

      final products = categories.first.getAllProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Crocin');
      expect(products.first.variants!.first.variantName, '650mg');
    });

    test('parses null/empty response gracefully', () {
      final json = <String, dynamic>{
        'businessProfile': null,
        'inventorySummary': null,
      };

      final model = MedicalHomeResponseModel.fromJson(json);
      expect(model.businessProfile, isNull);
      expect(model.inventorySummary, isNull);
      expect(model.gallery, isNull);
    });

    test('BusinessNumber formattedMobile returns null when number is 0', () {
      final bn = BusinessNumber.fromJson({
        'office_mob_no': {'pre': '91', 'number': '0'},
      });
      expect(bn.formattedMobile, isNull);
    });

    test('BusinessNumber formattedMobile returns null when no mob number', () {
      final bn = BusinessNumber.fromJson({
        'office_mob_no': null,
      });
      expect(bn.formattedMobile, isNull);
    });

    test('CategoryWithProducts hasProducts returns false when empty', () {
      final cat = CategoryWithProducts.fromJson({
        '_id': 'c1',
        'name': 'Empty',
        'key': 'EMPTY',
        'children': [],
        'products': [],
      });
      expect(cat.hasProducts, false);
      expect(cat.getAllProducts(), isEmpty);
    });

    test('CategoryWithProducts hasProducts with nested children', () {
      final cat = CategoryWithProducts.fromJson({
        '_id': 'c1',
        'name': 'Parent',
        'key': 'PARENT',
        'children': [
          {
            '_id': 'c2',
            'name': 'Child',
            'key': 'CHILD',
            'products': [
              {
                '_id': 'p1',
                'name': 'Product',
                'variants': [],
              }
            ],
          }
        ],
        'products': [],
      });
      expect(cat.hasProducts, true);
      expect(cat.getAllProducts().length, 1);
      expect(cat.getAllProducts().first.name, 'Product');
    });
  });

  group('PharmacyItem parsing', () {
    test('parses from JSON correctly', () {
      final json = {
        '_id': 'ph1',
        'pharmacyName': 'Health Plus',
        'address': '456 Med Lane',
        'email': 'info@healthplus.com',
        'phone': '1234567890',
        'pincode': '110001',
        'openFrom': '09:00 AM',
        'openTill': '09:00 PM',
        'logo': 'https://example.com/pharmacy.png',
        'averageRating': 4.2,
        'numberOfReviews': 35,
        'inventories': [
          {'productVariant': 'v1', 'batches': []}
        ],
      };

      final item = PharmacyItem.fromJson(json);
      expect(item.id, 'ph1');
      expect(item.name, 'Health Plus');
      expect(item.address, '456 Med Lane');
      expect(item.email, 'info@healthplus.com');
      expect(item.phone, '1234567890');
      expect(item.pincode, '110001');
      expect(item.openFrom, '09:00 AM');
      expect(item.openTill, '09:00 PM');
      expect(item.logo, 'https://example.com/pharmacy.png');
      expect(item.rating, 4.2);
      expect(item.reviews, 35);
      expect(item.inventories.length, 1);
    });

    test('handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final item = PharmacyItem.fromJson(json);

      expect(item.id, '');
      expect(item.name, '');
      expect(item.address, '');
      expect(item.rating, 0.0);
      expect(item.reviews, 0);
      expect(item.inventories, isEmpty);
    });

    test('id field can be used as businessId for detail screen', () {
      final json = {
        '_id': 'business123',
        'pharmacyName': 'Test Pharmacy',
      };
      final item = PharmacyItem.fromJson(json);
      // This is the businessId passed to MedicalPharmacyDetailScreen
      expect(item.id, 'business123');
      expect(item.id.isNotEmpty, true);
    });
  });

  group('PopularProduct pricing calculations', () {
    test('discount calculation with valid prices', () {
      final product = PopularProduct.fromJson({
        '_id': 'pp1',
        'batches': {'mrp': 200, 'sellingPrice': 150, 'quantity': 10},
      });

      final mrp = product.batches!.mrp!;
      final selling = product.batches!.sellingPrice!;
      final discount = (((mrp - selling) / mrp) * 100).toInt();

      expect(discount, 25);
    });

    test('discount is 0 when mrp equals selling price', () {
      final product = PopularProduct.fromJson({
        '_id': 'pp1',
        'batches': {'mrp': 100, 'sellingPrice': 100, 'quantity': 5},
      });

      final mrp = product.batches!.mrp!;
      final selling = product.batches!.sellingPrice!;
      final discount = (mrp != selling)
          ? (((mrp - selling) / mrp) * 100).toInt()
          : 0;

      expect(discount, 0);
    });
  });

  group('CategoryProductVariant parsing', () {
    test('parses with inventory data', () {
      final json = {
        '_id': 'cpv1',
        'variantName': '100ml',
        'unit': 'ml',
        'sku': 'SKU001',
        'pricing': [
          {'mrp': 50, 'sellingPrice': 40, 'currency': 'INR'}
        ],
        'images': [
          {'url': 'https://example.com/v.png', '_id': 'img1'}
        ],
        'inventory': {
          'inventoryId': 'inv1',
          'pincode': '110001',
          'cityName': 'Delhi',
          'batches': [
            {
              'batchNumber': 'B001',
              'quantity': 100,
              'mrp': 50,
              'sellingPrice': 40,
              '_id': 'b1',
            }
          ],
        },
      };

      final variant = CategoryProductVariant.fromJson(json);
      expect(variant.sId, 'cpv1');
      expect(variant.variantName, '100ml');
      expect(variant.unit, 'ml');
      expect(variant.sku, 'SKU001');
      expect(variant.pricing!.length, 1);
      expect(variant.pricing!.first.mrp, 50);
      expect(variant.images!.length, 1);
      expect(variant.inventory, isNotNull);
      expect(variant.inventory!.inventoryId, 'inv1');
      expect(variant.inventory!.batches!.length, 1);
      expect(variant.inventory!.batches!.first.quantity, 100);
    });

    test('parses without inventory', () {
      final json = {
        '_id': 'cpv2',
        'variantName': '200mg',
        'pricing': [],
      };

      final variant = CategoryProductVariant.fromJson(json);
      expect(variant.inventory, isNull);
      expect(variant.images, isNull);
    });
  });
}
