import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart'
    as grocery;
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart'
    as medical;
import 'package:flutter_test/flutter_test.dart';

/// Grocery and medical select VARIANTS now, not whole products — the same
/// shape food uses. Two rules hold the flow together and both are easy to
/// break from a widget:
///
/// 1. The product is in the cart exactly while at least one of its variants
///    is. The floating cart counts products, the publish payload is built from
///    variants, and the two must never disagree.
/// 2. A variant the merchant already stocks can never enter the cart —
///    publishing it again is a duplicate inventory record against one
///    catalogue variant.
void main() {
  grocery.GroceryProductData groceryProduct() => grocery.GroceryProductData(
        sId: 'p1',
        name: 'Atta',
        variants: [
          grocery.ProductVariants(
            sId: 'v1',
            quantity: '1 kg',
            pricing: [grocery.Pricing(mrp: 60, sellingPrice: 50)],
          ),
          grocery.ProductVariants(
            sId: 'v2',
            quantity: '5 kg',
            pricing: [grocery.Pricing(mrp: 280, sellingPrice: 250)],
          ),
        ],
      );

  medical.MedicalProductData medicalProduct() => medical.MedicalProductData(
        sId: 'm1',
        name: 'Paracetamol',
        variants: [
          medical.VariantsData(
            sId: 'mv1',
            weight: 10,
            unit: 'tablet',
            pricing: [medical.Pricing(mrp: 30, sellingPrice: 25)],
          ),
          medical.VariantsData(
            sId: 'mv2',
            weight: 15,
            unit: 'tablet',
            pricing: [medical.Pricing(mrp: 45, sellingPrice: 40)],
          ),
        ],
      );

  group('grocery variant selection', () {
    test('first variant adds the product, last untick removes it', () {
      final c = GroceryController();
      final p = groceryProduct();

      c.toggleVariantSelection(p, p.variants![0]);
      expect(c.selectedGroceries.length, 1);
      expect(c.selectedVariantCount('p1'), 1);

      // A second variant of the SAME product must not add a second cart entry.
      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedGroceries.length, 1);
      expect(c.selectedVariantCount('p1'), 2);

      c.toggleVariantSelection(p, p.variants![0]);
      expect(c.selectedGroceries.length, 1);

      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedGroceries, isEmpty);
      expect(c.selectedProductVariants.containsKey('p1'), isFalse);
    });

    test('an already-stocked variant cannot be selected', () {
      final c = GroceryController();
      final p = groceryProduct();
      c.stockedVariantIds.add('v1');

      c.toggleVariantSelection(p, p.variants![0]);
      expect(c.selectedGroceries, isEmpty);
      expect(c.selectedVariantCount('p1'), 0);

      // The unstocked sibling is still selectable — this is a per-variant
      // gate, not a per-product one.
      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedVariantCount('p1'), 1);
    });

    test('publish payload carries one entry per selected variant', () {
      final c = GroceryController();
      final p = groceryProduct();
      c.toggleVariantSelection(p, p.variants![0]);

      final ids = c.selectedProductVariants['p1']!.map((v) => v.sId).toList();
      expect(ids, ['v1']);
    });
  });

  group('medical variant selection', () {
    test('first variant adds the product, last untick removes it', () {
      final c = MedicalController();
      final p = medicalProduct();

      c.toggleVariantSelection(p, p.variants![0]);
      expect(c.selectedMedicalProducts.length, 1);
      expect(c.selectedVariantCount('m1'), 1);
      expect(c.canSubmitProducts, isTrue);

      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedMedicalProducts.length, 1);
      expect(c.selectedVariantCount('m1'), 2);

      c.toggleVariantSelection(p, p.variants![0]);
      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedMedicalProducts, isEmpty);
      // Publish must not stay lit over an empty cart.
      expect(c.canSubmitProducts, isFalse);
    });

    test('an already-stocked variant cannot be selected', () {
      final c = MedicalController();
      final p = medicalProduct();
      c.stockedVariantIds.add('mv1');

      c.toggleVariantSelection(p, p.variants![0]);
      expect(c.selectedMedicalProducts, isEmpty);

      c.toggleVariantSelection(p, p.variants![1]);
      expect(c.selectedVariantCount('m1'), 1);
    });
  });

  // Snap search reaches the SAME inventory endpoint from a photo, so it needs
  // the same refusal — otherwise the camera is simply the way around the gate
  // the catalogue screens apply.
  group('snap search is gated too', () {
    test('medical: a stocked variant stays out of the snap cart', () {
      final c = MedicalController();
      final p = medicalProduct();
      c.stockedVariantIds.add('mv1');

      c.toggleSnapSearchVariant('m1', p.variants![0]);
      expect(c.selectedSnapSearchProductVariants, isEmpty);
      expect(c.canSubmitSnapSearchProducts, isFalse);

      c.toggleSnapSearchVariant('m1', p.variants![1]);
      expect(c.selectedSnapSearchProductVariants['m1']!.length, 1);
      expect(c.canSubmitSnapSearchProducts, isTrue);
    });

    test('grocery: a stocked variant stays out of the snap cart', () {
      final c = GroceryController();
      final p = groceryProduct();
      c.stockedVariantIds.add('v1');

      c.toggleVariant('p1', p.variants![0]);
      expect(c.selectedProductVariants, isEmpty);

      c.toggleVariant('p1', p.variants![1]);
      expect(c.selectedProductVariants['p1']!.length, 1);
    });
  });
}
