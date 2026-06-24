# Grocery Top-Selling — Product → Variants (integration guide)

**Status:** Ask #1 shipped on the backend. The `business-products` endpoint is now **product-first** —
one `data[]` item per product, with every variant of that product nested under `variants[]`.
Ask #2 (variant edit/delete endpoints) is **not yet implemented**; keep the sheet's edit/delete local-only
until those land.

---

## Endpoint

```
POST grocery-service/api/inventory/business-products          (auth, bearer token)
POST grocery-service/api/inventory/public/business-products   (public, no token)
```

**Request (unchanged):**

```jsonc
{
  "businessId": "664f1a2b3c4d5e6f7a8b9c0d",   // required
  "categoryId": "664f...",                     // optional (includes descendants)
  "pincode":    "400001",                      // optional
  "search":     "basmati",                     // optional, product-name, case-insensitive
  "inStock":    true,                          // optional
  "minDiscount": 10, "maxDiscount": 50,        // optional (0–100)
  "sortBy":     "discount_high_to_low",        // see table below
  "page":       1,
  "limit":      10                             // counts PRODUCTS, not variants
}
```

`sortBy` values: `discount_high_to_low`, `discount_low_to_high`, `price_high_to_low`,
`price_low_to_high`, `stock_high_to_low`, `stock_low_to_high`, `newest` *(default)*, `oldest`.
Sorting is applied on the **product-level rollups**.

---

## Response — one item per product

```jsonc
{
  "data": [
    {
      "_id": "<productId>",                 // group key = product id

      "product": {
        "_id": "<productId>",
        "name": "Aashirvaad Atta",
        "description": "...",
        "brand": "Aashirvaad",
        "images": [ "https://..." ]
      },

      "category": {
        "_id": "<categoryId>",
        "name": "Atta & Flour",
        "image": "https://..."
      },

      // Product-level rollups (product card header):
      "minSellingPrice": 40,
      "minMrp": 50,
      "avgDiscount": 20,                     // rounded to 2 dp, avg across variants
      "totalStock": 32,                      // sum across all variants
      "updatedAt": "2026-06-20T...",
      "createdAt": "2026-01-02T...",

      // Backwards-compat: ONE representative variant (first). Prefer variants[] below.
      "productVariant": {
        "_id": "<variantId>",
        "variantName": "Aashirvaad Atta",
        "unit": "g", "quantity": "500",
        "sku": "...", "barcode": "...",
        "pricing": [ ... ], "images": [ ... ],
        "weight": "...", "value": "...", "specification": "..."
        // public endpoint also: "isVegetarian": true | null
      },

      // NEW — every variant of this product:
      "variants": [
        {
          "_id": "<variantId>",
          "product": "<productId>",
          "variantName": "Aashirvaad Atta",
          "unit": "g",
          "quantity": "500",
          "sku": "...", "barcode": "...",
          "weight": "...", "value": "...", "specification": "...",
          "isVegetarian": true,             // PUBLIC endpoint only (else null / absent on auth)
          "images": [ { "url": "https://..." } ],
          "pricing": [
            { "_id": "...", "cityName": "...", "pincode": "...", "mrp": 50, "sellingPrice": 40, "currency": "INR" }
          ],
          "inventory": {
            "inventoryId": "<inventoryId>",
            "pincode": "400001",
            "cityName": "Mumbai",
            "totalStock": 12,
            "isOutOfStock": false,
            "batches": [ { "quantity": 12, "mrp": 50, "sellingPrice": 40, ... } ]
          }
        }
        // ...all other variants of this product
      ]
    }
  ],
  "pagination": { "total": 42, "page": 1, "limit": 10, "totalPages": 5 }
}
```

### Field notes

- **`data[]` is one per product.** A product no longer repeats across rows.
- **`variants[]`** is the source of truth for the variant sheet (view / edit / delete UI).
  `productVariant` (singular) remains only for backwards-compat — the first variant.
- **`variants[].inventory`** holds the stock for that variant (`totalStock`, `isOutOfStock`,
  `batches`). The top-level `totalStock` is the product-wide sum.
- **`isVegetarian`** is populated only by the **public** endpoint, and only for root grocery-food
  categories (`GROCERY_COOKING`, `DAIRY_BEVERAGES`, `PACKAGED_FOOD`, `VEGETABLES_FRUIT`);
  `null` otherwise. The authenticated endpoint does not include it.
- **Pagination counts products.** `limit: 10` → up to 10 product cards.
- Filters (`inStock`, `minDiscount`/`maxDiscount`) are applied **per variant** before grouping, so a
  product appears if **any** of its variants matches; only matching variants would be carried in
  rollups/filters — but `variants[]` itself lists all variants pushed after those filters.

---

## Client migration

```dart
// Prefer variants[]; fall back to the old grouping only if the field is absent.
final List rawVariants = item['variants'] as List? ?? const [];

if (rawVariants.isNotEmpty) {
  // New path: one card per product, sheet lists item['variants'].
  final variants = rawVariants.map(ProductVariant.fromJson).toList();
} else {
  // Legacy fallback: group flat data[] by product._id client-side (old behaviour).
}
```

- Product card header reads `minSellingPrice` / `minMrp` / `avgDiscount` / `totalStock` from the
  item (unchanged keys).
- The tap-sheet iterates `variants[]`. Per-variant price comes from `variants[].pricing`
  (filter to the user's city/pincode if multiple entries) and stock from `variants[].inventory`.
- You can **remove the client-side grouping-by-`product._id`** workaround once you read `variants[]`.

---

## Ask #2 — still pending (edit / delete)

The variant **edit** (MRP / selling price) and **delete** endpoints are **not yet built**. Until they
ship, keep the sheet's edit/delete **local-only** (optimistic, not persisted), as today. Proposed shapes
to wire against when they land:

```
PATCH grocery-service/api/inventory/variants/{variantId}/pricing
  body:     { "mrp": 50, "sellingPrice": 40, "cityName": "...", "pincode": "..." }
  response: { "success": true, "data": { /* updated variant */ } }

DELETE grocery-service/api/inventory/variants/{variantId}
  response: { "success": true, "message": "Variant deleted" }
```

Open behavioural questions (backend to confirm when implementing): whether deleting the **last**
variant removes the product from the list, and whether edit/delete are gated to the owning business.
