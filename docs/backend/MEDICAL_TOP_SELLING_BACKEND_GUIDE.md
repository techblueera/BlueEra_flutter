# Medical — merchant "Top Selling" products endpoint

**One-line ask:** give the medical merchant a store-wide product list, the way
`grocery-service/api/inventory/business-products` already does for grocery, so
the pharmacy's **Products** tab can show a "Top Selling" section like grocery's.

**Status:** blocked on backend. Everything else on the tab is built and shipped.

---

## 1. Why

`MedicalHomeScreenV2` → **Products** tab is now laid out exactly like
`GroceryHomeScreenV2`'s, minus one section:

```
GROCERY products tab              MEDICAL products tab (today)
┌────────────────────────┐        ┌────────────────────────┐
│  [ + Add Grocery ]     │        │  [ + Add Product ]     │  ✅ built
│ ┃ Top Selling     →   │        │                        │  ❌ THIS DOC
│   ██  ██  ██           │        │                        │
│ ┃ Categories     (+)  │        │ ┃ Categories     (+)  │  ✅ built
│   ┌───┐ ┌───┐          │        │   ┌───┐ ┌───┐          │
└────────────────────────┘        └────────────────────────┘
```

The section can't be built because **medical has no store-wide product list**:

| | Grocery | Medical |
|---|---|---|
| Store-wide products | `groceryBusinessProductsList` ← `POST .../inventory/business-products` | ❌ **nothing** |
| Products in ONE category | `fetchGlobalGroceryProducts(categoryId)` | `fetchMyGroceryProducts(categoryId)` — needs a categoryId, so it can't fill a store-wide rail |
| Categories (no products) | `groceryCategoryList` | `myMedicalCategoryList` — `MyMedicalSuperCategoryModel` is id/name/key/image only, **no products** |

So there is no client-side way to assemble the rail: the only medical product
call is scoped to a single category, and the category objects carry no products
to flatten.

---

## 2. What to add

Mirror the grocery endpoint as closely as possible — the client work is then a
copy of `GroceryController.fetchGroceryBusinessProductsRepo` and the section
renders with the same card.

```
POST medical-service/inventory/business-products
Authorization: Bearer <token>
```

Grocery's equivalents, for reference:
- `grocery-service/api/inventory/business-products` — merchant's own (auth-scoped)
- `grocery-service/api/inventory/public/business-products` — another store's (customer side)

**Please ship both.** The public twin is what a customer-side "Top Selling" rail
would use later (grocery's `visit_grocery_store_screen` uses exactly that), so
adding it now avoids a second round trip through this doc.

### Request

Match grocery's body — same keys, same paging:

```jsonc
{
  "businessId": "<businessId>",   // the store whose products to list
  "page": 1,
  "limit": 10
}
```

### Response

Match grocery's `GroceryProductsModel` shape so the client can reuse its
grouping + card:

```jsonc
{
  "success": true,
  "data": [ /* product rows — see 2.1 */ ],
  "pagination": { "page": 1, "limit": 10, "total": 42, "totalPages": 5 }
}
```

Paging contract must match grocery's: the client stops when
`pagination.page >= pagination.totalPages`.

### 2.1 A product row

⚠️ **One row per VARIANT is fine** — grocery does exactly that, and the client
groups by product id (`groupBusinessProductsByProduct`) so a product with three
pack sizes renders as one card that opens a variants sheet. Don't pre-group
server-side unless grocery does.

Each row needs what the card renders:

| Field | Why |
|---|---|
| `product._id`, `product.name`, `product.brand` | card title + grouping key |
| `product.images[].url` | card image |
| `product.product_form` | pack/form line |
| `product.is_prescription_required` | the red **Rx** badge |
| `variant._id`, `variant.variantName`, `variant.unit` | variant row in the sheet |
| `variant.pricing[].mrp` / `.sellingPrice` | price + strike-through + discount |
| `inventory.inventoryId`, `inventory.batches[].mrp` / `.sellingPrice` | batch pricing wins over catalog (same rule as grocery) |
| `category._id`, `category.name` | grouping / display |

### 2.2 What "Top Selling" should mean

Grocery's endpoint is named `business-products` and the UI calls it "Top
Selling" — so **ordering is the contract**, not the name. Return them in
descending sales order (or whatever ranking you use for grocery — match it).

If you have no sales signal yet, return newest-first and say so here; the client
shows whatever order you send and caps at a preview limit.

---

## 3. Empty is empty — don't invent rows

The client **hides the whole Top Selling section** when the list comes back
empty (no empty state, no placeholder — the section vanishes). This matches
grocery on both the merchant and customer screens. So an empty `data` array is a
perfectly good response; don't pad it.

---

## 4. Client work once this ships

Small, and entirely mechanical:

1. `medical_service_api.dart` — `medicalBusinessProducts` (+ the public twin).
2. `medical_repo.dart` — `fetchMedicalBusinessProductsRepo`, a copy of
   `GroceryRepo.fetchGroceryBusinessProductsRepo`.
3. `medical_controller.dart` — `medicalBusinessProductsList` +
   `fetchMedicalBusinessProductsResponse` + paging fields, copied from
   `GroceryController`.
4. `medical_home_screen_v2.dart` — drop `_buildTopSellingSection()` into
   `_buildProductsTab()` between the add button and the category card. The
   accent-bar header + CTA chip already exist there (`_categorySectionHeader` /
   `_addProductCta`) and can be reused verbatim.
5. `_fetchForTab(2)` — fire the new call alongside `fetchMyMedicalCategory()`.

---

## 5. Acceptance checklist

- [ ] `POST medical-service/inventory/business-products` returns the merchant's own products
- [ ] Public twin returns another store's products for a `businessId`
- [ ] Request accepts `businessId` / `page` / `limit`, matching grocery
- [ ] Response carries `data[]` + `pagination{page,limit,total,totalPages}`
- [ ] Rows include `is_prescription_required` and `product_form` (the Rx badge needs them — see `PHARMACY_CUSTOMER_FLOW_INTEGRATION.md` §2a, where `popularProducts` is missing exactly these)
- [ ] Rows include `inventory.batches[]` so batch pricing can beat catalog price
- [ ] Ordering is sales-ranked (or documented otherwise)
- [ ] Empty catalog → `data: []`, not a padded/placeholder list
