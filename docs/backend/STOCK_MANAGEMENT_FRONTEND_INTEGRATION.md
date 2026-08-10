# Stock Management — Frontend Integration Guide

---

## How It Works (Plain English)

### The Big Picture

A business opens their dashboard and wants to see the health of their inventory — what's out of stock, what's running low, what's about to expire, and an overall summary. They can also manually mark items as out of stock (e.g., damaged goods, supplier issues) without deleting the batch data.

These APIs power a **Stock Management** section in the business dashboard. All 5 endpoints are business-only (require auth + BUSINESS role). The `businessId` is always extracted from the logged-in user's token — the frontend never sends it.

---

## Quick Reference

| # | Method | Endpoint | Purpose |
|---|--------|----------|---------|
| 1 | PATCH | `/api/inventory/stock/toggle-out-of-stock` | Bulk mark items in/out of stock |
| 2 | GET | `/api/inventory/stock/out-of-stock` | List all out-of-stock items |
| 3 | GET | `/api/inventory/stock/low-stock` | List items below reorder point |
| 4 | GET | `/api/inventory/stock/expiring-soon` | List items with batches expiring soon |
| 5 | GET | `/api/inventory/stock/summary` | Dashboard summary counts |

All endpoints require the `Authorization: Bearer <token>` header.

---

## New Field: `isOutOfStock`

A new boolean field `isOutOfStock` has been added to every inventory record. It defaults to `false`.

- When a business toggles it to `true`, that item is treated as out of stock **even if it still has batch quantity**.
- This flag now appears in the response of existing endpoints too: `getBusinessProductsById`, `getPublicBusinessProductsById`, and `getBusinessProducts` (inside the `inventory` sub-object).
- The `inStock=true` filter on existing endpoints now **also excludes** items where `isOutOfStock` is `true`.

**What this means for the frontend:** If you're showing an "In Stock" / "Out of Stock" badge on product cards, check both `totalStock > 0` AND `isOutOfStock !== true`. If either condition fails, the item is out of stock.

---

## Endpoint Details

### 1. Toggle Out of Stock

**`PATCH /api/inventory/stock/toggle-out-of-stock`**

Use this when the business taps an "Out of Stock" toggle on one or more items. Supports bulk operations — you can send multiple inventory IDs in one call.

**Request body:**

```json
{
  "inventoryIds": ["664f1a2b3c4d5e6f7a8b9c0d", "664f1a2b3c4d5e6f7a8b9c0e"],
  "isOutOfStock": true
}
```

- `inventoryIds` — array of inventory `_id` values. Must be non-empty. These are the `inventoryId` values you already get from `getBusinessProducts` (inside `variant.inventory.inventoryId`).
- `isOutOfStock` — `true` to mark out of stock, `false` to mark back in stock.

**Success response (200):**

```json
{
  "message": "Successfully updated isOutOfStock to true.",
  "matchedCount": 2,
  "modifiedCount": 2
}
```

- `matchedCount` — how many of the given IDs belong to this business and were found.
- `modifiedCount` — how many were actually changed (if they were already in the target state, this will be lower than matchedCount).

**Error responses:**

| Status | When |
|--------|------|
| 400 | `inventoryIds` is empty, not an array, contains invalid ObjectIds, or `isOutOfStock` is not a boolean |
| 404 | None of the given IDs belong to this business (ownership check) |

**Frontend notes:**
- After a successful toggle, refresh the relevant list (out-of-stock list, product list, or summary).
- You can wire this to a toggle switch on each item, or a "select multiple → mark out of stock" bulk action.

---

### 2. Out of Stock List

**`GET /api/inventory/stock/out-of-stock`**

Returns all items that are out of stock for this business. An item appears here if:
- `isOutOfStock` is `true` (manually marked), OR
- `totalStock` is 0 or less (naturally out of stock)

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `pincode` | string | — | Filter by pincode |
| `categoryId` | string | — | Filter by category (includes sub-categories) |
| `search` | string | — | Case-insensitive product name search |
| `page` | integer | 1 | Page number |
| `limit` | integer | 10 | Items per page |

**Example request:**

```
GET /api/inventory/stock/out-of-stock?page=1&limit=10&search=rice
```

**Response (200):**

```json
{
  "data": [
    {
      "_id": "664f1a2b3c4d5e6f7a8b9c0d",
      "pincode": "400001",
      "cityName": "Mumbai",
      "totalStock": 0,
      "isOutOfStock": true,
      "reorderPoint": 10,
      "batches": [...],
      "productVariant": {
        "_id": "...",
        "variantName": "Basmati Rice",
        "unit": "kg",
        "sku": "RICE-BAS-1KG",
        "images": [...]
      },
      "product": {
        "_id": "...",
        "name": "Basmati Rice",
        "brand": "India Gate",
        "images": [...]
      },
      "category": {
        "_id": "...",
        "name": "Rice & Grains",
        "image": "..."
      },
      "updatedAt": "2026-03-24T10:30:00.000Z"
    }
  ],
  "pagination": {
    "total": 12,
    "page": 1,
    "limit": 10,
    "totalPages": 2
  }
}
```

**Frontend notes:**
- Sorted by `updatedAt` descending (most recently updated first).
- Use `isOutOfStock` to distinguish between "manually marked" and "naturally out of stock (zero quantity)" — you might want to show a different label for each.
- This is the place to show a "Mark Back In Stock" button that calls the toggle endpoint with `isOutOfStock: false`.

---

### 3. Low Stock List

**`GET /api/inventory/stock/low-stock`**

Returns items where `0 < totalStock <= reorderPoint`. Items manually marked out of stock are excluded.

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `pincode` | string | — | Filter by pincode |
| `categoryId` | string | — | Filter by category (includes sub-categories) |
| `search` | string | — | Case-insensitive product name search |
| `sortBy` | string | `stock_low_to_high` | Sort order (see below) |
| `page` | integer | 1 | Page number |
| `limit` | integer | 10 | Items per page |

**Sort options:**

| Value | Description |
|-------|-------------|
| `stock_low_to_high` | Lowest stock first (default) |
| `stock_high_to_low` | Highest stock first |
| `newest` | Most recently updated first |
| `oldest` | Oldest first |

**Example request:**

```
GET /api/inventory/stock/low-stock?sortBy=stock_low_to_high&page=1&limit=20
```

**Response shape:** Same as the out-of-stock endpoint — each item has `totalStock`, `reorderPoint`, product/variant/category data, etc.

**Frontend notes:**
- A good UX is to show a warning badge: "Stock: 5 / Reorder at: 10" — both values are in the response.
- Default sort puts the most critical items (lowest stock) first.
- Consider highlighting items where `totalStock` is very close to 0 (e.g., `totalStock <= 3`) differently.

---

### 4. Expiring Soon

**`GET /api/inventory/stock/expiring-soon`**

Returns items that have at least one batch expiring within `days` days from now.

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `days` | integer | 30 | Expiry window in days from today |
| `pincode` | string | — | Filter by pincode |
| `categoryId` | string | — | Filter by category (includes sub-categories) |
| `search` | string | — | Case-insensitive product name search |
| `page` | integer | 1 | Page number |
| `limit` | integer | 10 | Items per page |

**Example request:**

```
GET /api/inventory/stock/expiring-soon?days=7&page=1&limit=10
```

**Response (200):**

Each item in `data` includes two extra fields compared to other endpoints:

```json
{
  "_id": "...",
  "nearestExpiryDate": "2026-03-28T00:00:00.000Z",
  "expiringBatches": [
    {
      "batchNumber": "BATCH-001",
      "quantity": "15",
      "expiryDate": "2026-03-28T00:00:00.000Z",
      "mrp": 60,
      "sellingPrice": 50
    }
  ],
  "batches": [...],
  "totalStock": 100,
  "productVariant": {...},
  "product": {...},
  "category": {...}
}
```

- `expiringBatches` — only the batches that fall within the expiry window (not all batches).
- `nearestExpiryDate` — the earliest expiry date among the expiring batches.
- `batches` — still contains ALL batches for reference.

**Frontend notes:**
- Sorted by `nearestExpiryDate` ascending — items expiring soonest appear first.
- Consider a quick-filter bar: "7 days", "14 days", "30 days" that changes the `days` param.
- Show how many days until expiry: `Math.ceil((new Date(nearestExpiryDate) - new Date()) / 86400000)`.
- You might want to color-code: red for ≤ 7 days, orange for ≤ 14 days, yellow for ≤ 30 days.

---

### 5. Stock Summary (Dashboard)

**`GET /api/inventory/stock/summary`**

Returns a single object with aggregate counts — perfect for a dashboard overview card or header stats.

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `pincode` | string | — | Optional. Scope summary to a specific pincode. |

**Example request:**

```
GET /api/inventory/stock/summary
GET /api/inventory/stock/summary?pincode=400001
```

**Response (200):**

```json
{
  "totalItems": 150,
  "outOfStockCount": 12,
  "lowStockCount": 25,
  "inStockCount": 138,
  "expiringSoonCount": 8,
  "totalStockValue": 245000.50,
  "totalUnits": 5200
}
```

| Field | Description |
|-------|-------------|
| `totalItems` | Total inventory records for this business |
| `outOfStockCount` | Items where `isOutOfStock=true` OR `totalStock <= 0` |
| `lowStockCount` | Items where `0 < totalStock <= reorderPoint` and not manually marked out of stock |
| `inStockCount` | Items where `totalStock > 0` and not manually marked out of stock |
| `expiringSoonCount` | Items with at least one batch expiring within 30 days |
| `totalStockValue` | Sum of `quantity × sellingPrice` across all batches (in ₹) |
| `totalUnits` | Sum of all batch quantities |

**Frontend notes:**
- Call this on page load for the stock management dashboard.
- Each count can be a clickable card that navigates to the corresponding list endpoint.
- If no inventory exists at all, all values will be 0.
- `outOfStockCount + inStockCount = totalItems` (they're mutually exclusive).
- `lowStockCount` is a subset of `inStockCount`.

---

## Suggested Dashboard Layout

```
┌─────────────────────────────────────────────────────┐
│  Stock Summary (from /stock/summary)                │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ 150      │ │ 12       │ │ 25       │ │ 8      │ │
│  │ Total    │ │ Out of   │ │ Low      │ │ Expiry │ │
│  │ Items    │ │ Stock    │ │ Stock    │ │ Soon   │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ │
│                                                     │
│  Total Value: ₹2,45,000.50    Units: 5,200          │
├─────────────────────────────────────────────────────┤
│  Tab: [Out of Stock] [Low Stock] [Expiring Soon]    │
│                                                     │
│  Filters: [Pincode ▾] [Category ▾] [Search...]     │
│                                                     │
│  ┌─ Item Card ────────────────────────────────────┐ │
│  │ 🖼 Basmati Rice 1kg  │  Stock: 0  │ [Toggle] │ │
│  │    India Gate         │  Reorder: 10│          │ │
│  └────────────────────────────────────────────────┘ │
│  ... more items ...                                 │
│                                                     │
│  [← Page 1 of 2 →]                                  │
└─────────────────────────────────────────────────────┘
```

---

## Changes to Existing Endpoints

### `POST /api/inventory/business-products` and `POST /api/inventory/public/business-products`

- Response now includes `isOutOfStock` field on each inventory item.
- The `inStock: true` filter now **also excludes** items where `isOutOfStock` is `true`. Previously it only checked `totalStock > 0`.

### `GET /api/inventory/my-products`

- The `inventory` sub-object inside each variant now includes `isOutOfStock`:

```json
{
  "inventory": {
    "inventoryId": "...",
    "pincode": "400001",
    "cityName": "Mumbai",
    "batches": [...],
    "totalStock": 50,
    "isOutOfStock": false
  }
}
```

---

## Common Patterns

### Checking if an item is effectively out of stock

```js
const isEffectivelyOutOfStock = (item) => {
  return item.isOutOfStock === true || item.totalStock <= 0;
};
```

### Building the toggle request

```js
// Single item toggle
const toggleStock = async (inventoryId, markOutOfStock) => {
  const response = await fetch('/api/inventory/stock/toggle-out-of-stock', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      inventoryIds: [inventoryId],
      isOutOfStock: markOutOfStock,
    }),
  });
  return response.json();
};
```

### Bulk toggle (select multiple items)

```js
const bulkToggle = async (selectedIds, markOutOfStock) => {
  const response = await fetch('/api/inventory/stock/toggle-out-of-stock', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      inventoryIds: selectedIds,
      isOutOfStock: markOutOfStock,
    }),
  });
  return response.json();
};
```

### Calculating days until expiry

```js
const daysUntilExpiry = (expiryDateStr) => {
  const now = new Date();
  const expiry = new Date(expiryDateStr);
  return Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
};

// Usage in component
const days = daysUntilExpiry(item.nearestExpiryDate);
// days <= 7  → red
// days <= 14 → orange
// days <= 30 → yellow
```

---

## Error Handling

All endpoints follow the same error pattern:

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 400 | Bad request (invalid input) |
| 401 | Not authenticated (missing/invalid token) |
| 403 | Not authorized (not a BUSINESS role) |
| 404 | Resource not found / ownership check failed |
| 500 | Server error |

Error responses always have a `message` field:

```json
{
  "message": "inventoryIds must be a non-empty array."
}
```
