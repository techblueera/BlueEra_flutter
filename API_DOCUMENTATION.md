# Medical Service - Complete API Documentation

**Base URLs:**
- Production: `https://be.beapp.in/api/medical-service`
- Development: `http://localhost:3000`
- Swagger UI: `/api-docs`

**Authentication:** Bearer token in `Authorization` header for protected routes.

---

## Table of Contents

1. [Product Creation Flow (Page-wise)](#product-creation-flow)
2. [Categories API](#categories-api)
3. [Products API](#products-api)
4. [Inventory API](#inventory-api)
5. [Orders API](#orders-api)
6. [Missing Product Requests API](#missing-product-requests-api)
7. [Smart Cart (AI Vision) API](#smart-cart-api)
8. [Profile API](#profile-api)
9. [Upload API](#upload-api)

---

## Product Creation Flow

This section describes the **page-wise flow** a frontend should follow to create a product and make it available for purchase. Each step maps to a frontend page/screen.

### Flow Diagram

```
PAGE 1: Category Setup
  Admin creates category hierarchy (if not exists)
    POST /categories
      └── Level 0: "Medicines"
           └── Level 1: "Pain Relief"
                └── Level 2: "Tablets"
                     └── Level 3: "Paracetamol"

PAGE 2: Product + Variants Creation (Admin)
  Admin creates product with variants
    POST /products/admin
      └── Creates Product + ProductVariant(s) in one transaction
      └── Optionally links to a MissingProductRequest

PAGE 3: Inventory Setup (Business)
  Business adds inventory for their store
    POST /inventory
      └── Links ProductVariant to business + pincode + batches

PAGE 4: Product is now live
  Users can search and order
    GET  /products/user/search?pincode=110001
    POST /orders
```

---

### PAGE 1: Category Management (Admin)

Before creating products, categories must exist. Categories support 4-level nesting.

#### Create Category

```
POST /categories
Content-Type: multipart/form-data
```

**Request Body (form-data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Category name |
| `key` | string | Yes | Unique uppercase key (e.g., `MEDICINES`) |
| `description` | string | No | Category description |
| `parentId` | string | No | Parent category ID (for sub-categories) |
| `isActive` | boolean | No | Default: `true` |
| `image` | file | No | Main category image |
| `imageOptions` | file[] | No | Up to 10 optional images |

**Example - Create root category:**
```json
{
  "name": "Medicines",
  "key": "MEDICINES",
  "description": "All pharmaceutical products"
}
```

**Example - Create sub-category:**
```json
{
  "name": "Pain Relief",
  "key": "PAIN_RELIEF",
  "parentId": "683abc123def456789012345",
  "description": "Pain relief medicines"
}
```

**Response (201):**
```json
{
  "_id": "683abc123def456789012345",
  "name": "Medicines",
  "key": "MEDICINES",
  "description": "All pharmaceutical products",
  "image": "https://s3.amazonaws.com/bucket/uploads/uuid.jpg",
  "imageOptions": [],
  "isActive": true,
  "parentId": null,
  "level": 0,
  "createdAt": "2026-03-19T10:00:00.000Z",
  "updatedAt": "2026-03-19T10:00:00.000Z"
}
```

#### Get Nested Category Tree

```
GET /categories/nested
GET /categories/nested?categoryKey=MEDICINES
```

**Response (200):**
```json
[
  {
    "_id": "683abc123def456789012345",
    "name": "Medicines",
    "key": "MEDICINES",
    "level": 0,
    "children": [
      {
        "_id": "683abc123def456789012346",
        "name": "Pain Relief",
        "key": "PAIN_RELIEF",
        "level": 1,
        "parentId": "683abc123def456789012345",
        "children": []
      }
    ]
  }
]
```

#### Other Category Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/categories` | Get all categories (flat, sorted by level) |
| `GET` | `/categories/with-inventory` | Root categories with inventory for auth'd business |
| `GET` | `/categories/search?key=MED&name=pain` | Search categories |
| `GET` | `/categories/with-image-options?categoryKeys=MEDICINES` | Get categories with imageOptions |
| `GET` | `/categories/{id}/children` | Direct children by ID |
| `GET` | `/categories/key/{key}/children` | Direct children by key |
| `PUT` | `/categories/{id}` | Update category (multipart/form-data) |
| `DELETE` | `/categories/{id}` | Delete category (fails if has children) |
| `DELETE` | `/categories/{id}/image-options` | Delete specific image option |

---

### PAGE 2: Product + Variants Creation (Admin)

#### Create Product with Variants

```
POST /products/admin
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "productData": {
    "name": "Dolo 650",
    "generic_name": "Paracetamol",
    "description": "Used for fever and mild to moderate pain relief",
    "brand": "Micro Labs",
    "category": "683abc123def456789012345",
    "tags": ["fever", "pain", "headache", "analgesic"],
    "filterKeywords": ["paracetamol", "antipyretic"],
    "images": [
      { "url": "https://s3.amazonaws.com/bucket/dolo-650.jpg", "altText": "Dolo 650 strip" }
    ],
    "isActive": true,
    "countryOfOrigin": "India",
    "manufacturerDetails": {
      "name": "Micro Labs Limited",
      "address": "Bangalore, Karnataka",
      "customerCare": "1800-123-4567"
    },
    "marketer_name": "Micro Labs Limited",
    "salt_composition": "Paracetamol 650mg",
    "strength": "650mg",
    "drug_type": "Allopathy",
    "product_form": "Tablet",
    "is_prescription_required": false,
    "pack_size": "15 Tablets",
    "pack_type": "Strip",
    "storage_conditions": "Store below 30°C in a dry place",
    "shelf_life": "24 months",
    "indications": ["Fever", "Headache", "Body ache", "Toothache"],
    "dosage_instructions": "1-2 tablets every 4-6 hours as needed. Max 4 tablets/day.",
    "contraindications": ["Severe liver disease", "Known allergy to paracetamol"],
    "side_effects": ["Nausea", "Skin rash", "Allergic reactions (rare)"],
    "drug_interactions": ["Warfarin", "Alcohol", "Carbamazepine"],
    "warnings_precautions": "Do not exceed 4g per day. Avoid with alcohol.",
    "use_in_pregnancy": "Generally considered safe. Consult doctor.",
    "use_in_lactation": "Generally considered safe in therapeutic doses.",
    "use_in_children": "Use age-appropriate pediatric formulation.",
    "use_in_elderly": "Dose adjustment may be needed for hepatic impairment."
  },
  "variantData": [
    {
      "variantName": "Dolo 650 - Strip of 15",
      "unit": "15 Tablets",
      "quantity": "15",
      "sku": "DOLO-650-15",
      "barcode": "8901790515671",
      "pricing": [
        {
          "pincode": "110001",
          "cityName": "Delhi",
          "mrp": 35.00,
          "sellingPrice": 30.00,
          "currency": "INR"
        }
      ],
      "images": [
        { "url": "https://s3.amazonaws.com/bucket/dolo-strip.jpg", "altText": "Strip of 15" }
      ],
      "weight": 0.05
    },
    {
      "variantName": "Dolo 650 - Strip of 10",
      "unit": "10 Tablets",
      "quantity": "10",
      "sku": "DOLO-650-10",
      "barcode": "8901790515672",
      "pricing": [
        {
          "pincode": "110001",
          "cityName": "Delhi",
          "mrp": 25.00,
          "sellingPrice": 22.00,
          "currency": "INR"
        }
      ],
      "weight": 0.035
    }
  ]
}
```

**With MissingProductRequest link (optional):**
```json
{
  "productData": {
    "name": "Dolo 650",
    "category": "683abc123def456789012345",
    "missingProductRequestId": "683abc123def456789099999",
    "...": "other fields"
  },
  "variantData": [{ "...": "variant fields" }]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Product and Variants created successfully",
  "data": {
    "product": {
      "_id": "683def456789012345abcdef",
      "name": "Dolo 650",
      "generic_name": "Paracetamol",
      "brand": "Micro Labs",
      "category": "683abc123def456789012345",
      "is_prescription_required": false,
      "product_form": "Tablet",
      "...": "all product fields"
    },
    "variants": [
      {
        "_id": "683ghi789012345abcdef012",
        "product": "683def456789012345abcdef",
        "variantName": "Dolo 650 - Strip of 15",
        "unit": "15 Tablets",
        "sku": "DOLO-650-15",
        "pricing": [{ "pincode": "110001", "cityName": "Delhi", "mrp": 35, "sellingPrice": 30, "currency": "INR" }],
        "...": "all variant fields"
      },
      {
        "_id": "683jkl012345abcdef678901",
        "product": "683def456789012345abcdef",
        "variantName": "Dolo 650 - Strip of 10",
        "unit": "10 Tablets",
        "sku": "DOLO-650-10",
        "...": "all variant fields"
      }
    ]
  }
}
```

**Error Responses:**
- `400` — Missing `productData` or `variantData`
- `404` — Category not found
- `409` — Duplicate SKU or Barcode

---

#### Update Product and Sync Variants (Admin)

```
PUT /products/admin/{productId}
Content-Type: application/json
Authorization: Bearer <admin_token>
```

**Key behavior:**
- Omit a variant's `_id` to **create** it as new
- Include `_id` to **update** existing
- Omit a variant entirely from `variantsData` to **delete** it (fails if it has inventory)

**Request Body:**
```json
{
  "productData": {
    "name": "Dolo 650 Updated",
    "description": "Updated description"
  },
  "variantsData": [
    {
      "_id": "683ghi789012345abcdef012",
      "variantName": "Dolo 650 - Strip of 15 (Updated)",
      "pricing": [{ "pincode": "110001", "cityName": "Delhi", "mrp": 38, "sellingPrice": 33, "currency": "INR" }]
    },
    {
      "variantName": "Dolo 650 - Bottle of 100",
      "unit": "100 Tablets",
      "sku": "DOLO-650-100",
      "pricing": [{ "pincode": "110001", "cityName": "Delhi", "mrp": 200, "sellingPrice": 180, "currency": "INR" }]
    }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Product and variants updated successfully",
  "data": {
    "_id": "683def456789012345abcdef",
    "name": "Dolo 650 Updated",
    "variants": [
      { "_id": "683ghi789012345abcdef012", "variantName": "Dolo 650 - Strip of 15 (Updated)", "..." : "..." },
      { "_id": "683new789012345abcdef012", "variantName": "Dolo 650 - Bottle of 100", "..." : "..." }
    ]
  }
}
```

---

#### Add Variant with Image Upload (Admin/Business)

```
POST /products/{productId}/variants
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

**Request Body (form-data):**

| Field | Type | Description |
|-------|------|-------------|
| `variantData` | string (JSON) | JSON string of variant object |
| `variantImages` | file[] | Up to 5 image files |

**variantData JSON:**
```json
{
  "variantName": "Dolo 650 Suspension",
  "unit": "60 ml Bottle",
  "quantity": "60ml",
  "sku": "DOLO-650-SUS-60",
  "pricing": [
    { "mrp": 55, "sellingPrice": 48 }
  ]
}
```

> Note: If `pincode`/`cityName` are omitted from pricing, they are auto-populated from a sibling variant's pricing.

**Response (201):**
```json
{
  "_id": "683mno345678abcdef901234",
  "product": "683def456789012345abcdef",
  "variantName": "Dolo 650 Suspension",
  "unit": "60 ml Bottle",
  "sku": "DOLO-650-SUS-60",
  "images": [
    { "url": "https://s3.amazonaws.com/bucket/uploads/uuid.jpg" }
  ],
  "pricing": [{ "pincode": "110001", "cityName": "Delhi", "mrp": 55, "sellingPrice": 48, "currency": "INR" }]
}
```

---

#### Update Variant (Admin direct / Business approval flow)

```
PUT /products/variants/{variantId}
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "variantName": "Dolo 650 - Strip of 15 Tablets",
  "pricing": [
    { "pincode": "110001", "cityName": "Delhi", "mrp": 40, "sellingPrice": 35, "currency": "INR" }
  ]
}
```

**Response (200) — Admin:**
```json
{
  "_id": "683ghi789012345abcdef012",
  "variantName": "Dolo 650 - Strip of 15 Tablets",
  "pricing": [{ "pincode": "110001", "mrp": 40, "sellingPrice": 35 }],
  "...": "full variant"
}
```

**Response (202) — Business user (change request created):**
```json
{
  "message": "Update request submitted for approval.",
  "changeRequest": {
    "_id": "683pqr678901abcdef234567",
    "variant": "683ghi789012345abcdef012",
    "requestedBy": "683user12345abcdef678901",
    "changes": { "variantName": "Dolo 650 - Strip of 15 Tablets", "pricing": ["..."] },
    "status": "pending"
  }
}
```

---

#### Delete Variant (Admin)

```
DELETE /products/variants/{variantId}
Authorization: Bearer <admin_token>
```

**Response (200):**
```json
{ "message": "Product variant deleted successfully." }
```

**Error (400):** Cannot delete if inventory exists for this variant.

---

#### Change Request Management (Admin)

**Get pending requests:**
```
GET /products/variants/change-requests?status=pending&page=1&limit=20
Authorization: Bearer <admin_token>
```

**Response (200):**
```json
{
  "data": [
    {
      "_id": "683pqr678901abcdef234567",
      "variant": {
        "_id": "683ghi789012345abcdef012",
        "variantName": "Dolo 650 - Strip of 15",
        "sku": "DOLO-650-15"
      },
      "requestedBy": "683user12345abcdef678901",
      "changes": { "pricing": [{ "mrp": 40, "sellingPrice": 35 }] },
      "status": "pending",
      "createdAt": "2026-03-19T10:00:00.000Z"
    }
  ],
  "pagination": { "total": 1, "page": 1, "limit": 20, "totalPages": 1 }
}
```

**Approve:**
```
POST /products/variants/change-requests/{requestId}/approve
Authorization: Bearer <admin_token>
```

**Response (200):**
```json
{
  "message": "Change request approved.",
  "variant": { "_id": "...", "variantName": "...", "pricing": ["updated pricing"] }
}
```

**Reject:**
```
POST /products/variants/change-requests/{requestId}/reject
Authorization: Bearer <admin_token>
Content-Type: application/json
```

```json
{ "rejectionReason": "Price increase not justified at this time." }
```

**Response (200):**
```json
{
  "message": "Change request rejected.",
  "request": { "_id": "...", "status": "rejected", "rejectionReason": "Price increase not justified at this time." }
}
```

---

### PAGE 3: Inventory Setup (Business)

#### Create Inventory

```
POST /inventory
Content-Type: application/json
Authorization: Bearer <business_token>
```

**Request Body (array):**
```json
[
  {
    "productVariant": "683ghi789012345abcdef012",
    "pincode": "110001",
    "cityName": "Delhi",
    "batches": [
      {
        "batchNumber": "BATCH-2026-001",
        "quantity": 100,
        "mfgDate": "2026-01-01",
        "expiryDate": "2028-01-01",
        "mrp": 35.00,
        "sellingPrice": 30.00
      },
      {
        "batchNumber": "BATCH-2026-002",
        "quantity": 50,
        "mfgDate": "2026-02-15",
        "expiryDate": "2028-02-15",
        "mrp": 35.00,
        "sellingPrice": 28.00
      }
    ],
    "supplierInfo": {
      "name": "ABC Pharma Distributors",
      "contact": "9876543210"
    },
    "location": {
      "aisle": "A",
      "shelf": "3"
    },
    "reorderPoint": 20
  }
]
```

**Response (201):**
```json
[
  {
    "_id": "683inv123def456789012345",
    "businessId": "683biz123def456789012345",
    "productVariant": "683ghi789012345abcdef012",
    "pincode": "110001",
    "cityName": "Delhi",
    "batches": [
      { "batchNumber": "BATCH-2026-001", "quantity": 100, "mfgDate": "2026-01-01T00:00:00.000Z", "expiryDate": "2028-01-01T00:00:00.000Z", "mrp": 35, "sellingPrice": 30 },
      { "batchNumber": "BATCH-2026-002", "quantity": 50, "mrp": 35, "sellingPrice": 28, "...": "..." }
    ],
    "supplierInfo": { "name": "ABC Pharma Distributors", "contact": "9876543210" },
    "location": { "aisle": "A", "shelf": "3" },
    "reorderPoint": 20,
    "totalStock": 150
  }
]
```

#### Get Business Inventory (Grouped by Category)

```
GET /inventory/my-products?page=1&limit=10&categoryId=683abc123def456789012345
Authorization: Bearer <business_token>
```

**Response (200):**
```json
{
  "data": [
    {
      "category": {
        "_id": "683abc123def456789012345",
        "name": "Medicines",
        "image": "https://s3.../cat.jpg",
        "productVariantCount": 5,
        "products": [
          {
            "_id": "683def456789012345abcdef",
            "name": "Dolo 650",
            "brand": "Micro Labs",
            "images": [{ "url": "..." }],
            "variants": [
              {
                "_id": "683ghi789012345abcdef012",
                "variantName": "Dolo 650 - Strip of 15",
                "unit": "15 Tablets",
                "sku": "DOLO-650-15",
                "inventory": {
                  "inventoryId": "683inv123def456789012345",
                  "pincode": "110001",
                  "batches": [{ "batchNumber": "BATCH-2026-001", "quantity": 100, "mrp": 35, "sellingPrice": 30, "expiryDate": "2028-01-01" }],
                  "totalStock": 150
                }
              }
            ]
          }
        ]
      }
    }
  ],
  "pagination": { "total": 1, "page": 1, "limit": 10, "totalPages": 1 }
}
```

#### Update Inventory

```
PUT /inventory/{id}
Content-Type: application/json
Authorization: Bearer <business_token>
```

```json
{
  "batches": [
    { "batchNumber": "BATCH-2026-003", "quantity": 200, "mfgDate": "2026-03-01", "expiryDate": "2028-03-01", "mrp": 36, "sellingPrice": 31 }
  ],
  "reorderPoint": 30
}
```

#### Delete Inventory

```
DELETE /inventory/{id}
Authorization: Bearer <business_token>
```

---

### PAGE 4: Product Discovery & Ordering (Customer)

#### Search Products (Customer)

```
GET /products/user/search?pincode=110001&searchTerm=dolo&page=1&limit=10
Authorization: Bearer <user_token>
```

**Query Parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `pincode` | string | Yes | User's delivery pincode |
| `key` | string | No | Category key filter |
| `searchTerm` | string | No | Text search |
| `page` | integer | No | Default: 1 |
| `limit` | integer | No | Default: 10 |
| `minPrice` | number | No | Min selling price filter |
| `maxPrice` | number | No | Max selling price filter |

**Response (200):**
```json
{
  "data": [
    {
      "_id": "683def456789012345abcdef",
      "name": "Dolo 650",
      "description": "Used for fever and mild to moderate pain relief",
      "brand": "Micro Labs",
      "category": "683abc123def456789012345",
      "images": [{ "url": "..." }],
      "variants": [
        {
          "_id": "683ghi789012345abcdef012",
          "variantName": "Dolo 650 - Strip of 15",
          "unit": "15 Tablets",
          "pricing": [{ "pincode": "110001", "mrp": 35, "sellingPrice": 30 }],
          "avgSellingPrice": 29,
          "inventory": [
            {
              "_id": "683inv123def456789012345",
              "businessId": "683biz123def456789012345",
              "batches": [{ "quantity": 100, "mrp": 35, "sellingPrice": 30 }],
              "totalStock": 150
            }
          ]
        }
      ]
    }
  ],
  "pagination": { "total": 1, "page": 1, "limit": 10, "totalPages": 1 }
}
```

#### Search Products (Business - for adding to inventory)

```
GET /products/search?searchTerm=dolo&pincode=110001&page=1&limit=10
Authorization: Bearer <business_token>
```

#### Get Product by ID (Public)

```
GET /products/{productId}
```

**Response (200):**
```json
{
  "data": {
    "_id": "683def456789012345abcdef",
    "name": "Dolo 650",
    "generic_name": "Paracetamol",
    "brand": "Micro Labs",
    "salt_composition": "Paracetamol 650mg",
    "product_form": "Tablet",
    "is_prescription_required": false,
    "indications": ["Fever", "Headache"],
    "side_effects": ["Nausea", "Skin rash"],
    "variants": [
      { "_id": "...", "variantName": "Strip of 15", "unit": "15 Tablets", "sku": "DOLO-650-15", "pricing": ["..."] },
      { "_id": "...", "variantName": "Strip of 10", "unit": "10 Tablets", "sku": "DOLO-650-10", "pricing": ["..."] }
    ]
  }
}
```

#### Get All Products (Admin)

```
GET /products/admin/all?page=1&limit=10&search=dolo&categoryStatus=all
Authorization: Bearer <admin_token>
```

#### Find Similar Products

```
POST /products/user/similar
Authorization: Bearer <user_token>
Content-Type: application/json
```

```json
{
  "productIds": ["683def456789012345abcdef"],
  "pincode": "110001"
}
```

#### Create Order

```
POST /orders
Content-Type: application/json
Authorization: Bearer <user_token>
```

```json
{
  "items": [
    {
      "inventory": "683inv123def456789012345",
      "productVariant": "683ghi789012345abcdef012",
      "quantity": 2,
      "mrp": 35.00,
      "sellingPrice": 30.00
    }
  ],
  "deliveryType": "self-pickup",
  "discount": 5
}
```

**Response (201):**
```json
{
  "_id": "683ord123def456789012345",
  "userId": "683user12345abcdef678901",
  "items": [
    {
      "inventory": "683inv123def456789012345",
      "productVariant": "683ghi789012345abcdef012",
      "quantity": 2,
      "mrp": 35,
      "sellingPrice": 30
    }
  ],
  "totalItems": 2,
  "totalMRP": 70,
  "discount": 5,
  "grandTotal": 55,
  "deliveryType": "self-pickup",
  "orderStatus": "placed",
  "createdAt": "2026-03-19T12:00:00.000Z"
}
```

#### Other Order Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/orders/status/me` | Check for ongoing order |
| `GET` | `/orders/me?page=1&limit=10&orderStatus=placed&sortBy=createdAt&sortOrder=desc` | Get all orders with filters |
| `GET` | `/orders/{orderId}/alternatives?filter=suggested` | Find alternative stores |
| `PUT` | `/orders/{id}` | Update order status / assign rider |

---

## Missing Product Requests API

### [Business] Create Single Request

```
POST /missing-product-requests
Content-Type: multipart/form-data
Authorization: Bearer <business_token>
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Product name |
| `brand` | string | Yes | Brand/manufacturer |
| `searchKeywords` | string | Yes | Space-separated search keywords |
| `unit` | string | Yes | Pack size (e.g., "15 Tablets") |
| `approxPrice` | number | Yes | Approximate MRP |
| `cityName` | string | Yes | Business city |
| `pincode` | string | Yes | Business pincode |
| `productImage` | file | No | Product image |

**Response (201):**
```json
{
  "message": "Missing product request raised successfully.",
  "data": {
    "_id": "683mpr123def456789012345",
    "name": "Calpol 500",
    "brand": "GSK",
    "searchKeywords": "calpol paracetamol 500 fever",
    "unit": "15 Tablets",
    "approxPrice": 25,
    "businessId": "683biz123def456789012345",
    "productImage": "https://s3.../missing-product-requests/img.jpg",
    "cityName": "Delhi",
    "pincode": "110001",
    "status": "pending",
    "createdAt": "2026-03-19T10:00:00.000Z"
  }
}
```

### [Business] Create Bulk Requests

```
POST /missing-product-requests/bulk
Content-Type: multipart/form-data OR application/json
Authorization: Bearer <business_token>
```

**JSON body:**
```json
{
  "cityName": "Delhi",
  "pincode": "110001",
  "items": [
    { "name": "Calpol 500", "brand": "GSK", "searchKeywords": "calpol paracetamol", "unit": "15 Tablets", "approxPrice": 25 },
    { "name": "Azithral 500", "brand": "Alembic", "searchKeywords": "azithral azithromycin antibiotic", "unit": "3 Tablets", "approxPrice": 95 }
  ]
}
```

**Response (201):**
```json
{
  "message": "2 missing product request(s) raised successfully.",
  "data": [
    { "_id": "...", "name": "Calpol 500", "status": "pending", "...": "..." },
    { "_id": "...", "name": "Azithral 500", "status": "pending", "...": "..." }
  ]
}
```

### [Business] Get My Requests

```
GET /missing-product-requests/my?status=pending&page=1&limit=10
Authorization: Bearer <business_token>
```

### [Admin] Get All Requests (Grouped by Business)

```
GET /missing-product-requests/admin?status=pending&page=1&limit=10
Authorization: Bearer <admin_token>
```

**Response (200):**
```json
{
  "data": [
    {
      "businessId": "683biz123def456789012345",
      "businessName": "MedPlus Pharmacy",
      "cityName": "Delhi",
      "dateTime": "2026-03-19T10:00:00.000Z",
      "numberOfRequests": 3,
      "productImages": ["https://s3.../img1.jpg"],
      "requests": [
        { "_id": "...", "name": "Calpol 500", "status": "pending", "...": "..." }
      ]
    }
  ],
  "pagination": { "total": 1, "page": 1, "limit": 10, "totalPages": 1 }
}
```

### [Admin] Update Request Status

```
PATCH /missing-product-requests/admin/{requestId}/status
Content-Type: application/json
Authorization: Bearer <admin_token>
```

```json
{
  "status": "approved",
  "adminNote": "Product will be added within 2 business days."
}
```

**Status transitions:** `pending` -> `in-review` -> `approved` / `rejected`

---

## Smart Cart API

### Snap & Search (AI Image Recognition)

```
POST /smart-cart/snap-search
Content-Type: multipart/form-data
```

| Field | Type | Description |
|-------|------|-------------|
| `images` | file[] | 1-5 images (max 5MB each). Medicine photos, prescriptions, bills. |

**Response (200):**
```json
{
  "success": true,
  "message": "Processed 3 items from images.",
  "data": {
    "totalDetected": 3,
    "foundCount": 2,
    "missingCount": 1,
    "foundProducts": [
      {
        "aiIdentifiedAs": "Dolo 650",
        "productDetails": {
          "_id": "683def456789012345abcdef",
          "name": "Dolo 650",
          "generic_name": "Paracetamol",
          "brand": "Micro Labs",
          "product_form": "Tablet",
          "variants": [
            { "_id": "...", "variantName": "Strip of 15", "sku": "DOLO-650-15", "pricing": ["..."] }
          ]
        }
      }
    ],
    "missingProducts": [
      {
        "name": "Volini Spray",
        "generic_name": "Diclofenac Diethylamine",
        "brand": "Sun Pharma",
        "searchKeywords": "volini spray pain relief diclofenac",
        "unit": "40 gm Spray",
        "approxPrice": 220,
        "product_form": "Spray",
        "strength": "1.16% w/w",
        "is_prescription_required": false
      }
    ]
  }
}
```

> **Frontend integration tip:** The `missingProducts` array items can be directly used to create missing product requests via `POST /missing-product-requests/bulk`.

---

## Profile API

### About Us

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `PUT` | `/profile/about-us` | Yes | Create/update about-us (logo, medicalStoreImage URLs) |
| `GET` | `/profile/about-us` | Yes | Get about-us details |

### Contact

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/profile/contact` | Yes | Create contact (auto-geocodes pincode) |
| `GET` | `/profile/contact` | Yes | Get contact details |
| `PUT` | `/profile/contact` | Yes | Update contact (upsert) |
| `DELETE` | `/profile/contact` | Yes | Delete contact |

**Contact request body:**
```json
{
  "pharmacyName": "MedPlus Pharmacy",
  "website": "https://medplus.in",
  "address": "123, Main Road, Connaught Place",
  "pincode": "110001",
  "phone": "+91-9876543210",
  "email": "contact@medplus.in",
  "description": "Your trusted neighbourhood pharmacy",
  "openFrom": "08:00",
  "openTill": "22:00"
}
```

### Testimonials

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/profile/testimonials` | Yes | Create testimonial |
| `GET` | `/profile/testimonials` | Yes | Get all testimonials |
| `GET` | `/profile/testimonials/active` | Yes | Get active only |
| `GET` | `/profile/testimonials/{id}` | Yes | Get by ID |
| `PUT` | `/profile/testimonials/{id}` | Yes | Update |
| `DELETE` | `/profile/testimonials/{id}` | Yes | Delete |
| `PATCH` | `/profile/testimonials/{id}/toggle-status` | Yes | Toggle active/inactive |

**Testimonial request body:**
```json
{
  "name": "Rahul Sharma",
  "image": "https://s3.../user.jpg",
  "rating": 5,
  "message": "Great service and genuine medicines!",
  "designation": "Regular Customer",
  "isActive": true
}
```

### Gallery

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/profile/gallery` | Yes | Create gallery entry |
| `GET` | `/profile/gallery` | Yes | Get all entries |
| `GET` | `/profile/gallery/{id}` | Yes | Get by ID |
| `PUT` | `/profile/gallery/{id}` | Yes | Update entry |
| `DELETE` | `/profile/gallery/{id}` | Yes | Delete entry |
| `DELETE` | `/profile/gallery/{id}/images` | Yes | Delete single image from entry |

**Gallery request body:**
```json
{
  "title": "Store Interior",
  "imageUrls": [
    "https://s3.../photo1.jpg",
    "https://s3.../photo2.jpg"
  ]
}
```

### Home Profile (Aggregated)

```
GET /profile/home/{businessId}
Authorization: Bearer <token>
```

Returns combined: business details, about-us, contact, gallery, testimonials, popular products, category-grouped products.

### Find Nearest Pharmacies

```
POST /profile/nearest
Content-Type: application/json
```

```json
{
  "pincode": "110001",
  "radius": 5
}
```

---

## Upload API

### Generate Pre-signed S3 Upload URL

```
GET /upload/init?fileName=photo.jpg&fileType=image/jpeg
```

**Response (200):**
```json
{
  "uploadUrl": "https://s3.amazonaws.com/bucket/uploads/uuid.jpg?X-Amz-Signature=...",
  "publicUrl": "https://s3.amazonaws.com/bucket/uploads/uuid.jpg",
  "fileKey": "uploads/uuid.jpg"
}
```

**Frontend usage:**
1. Call `GET /upload/init` to get a pre-signed URL
2. `PUT` the file directly to `uploadUrl`
3. Use `publicUrl` in subsequent API calls (e.g., product images, about-us logo)

---

## Frontend Integration: Complete Product Creation Sequence

```
Step 1: Upload images (if any)
  GET /upload/init?fileName=dolo.jpg&fileType=image/jpeg
  PUT <uploadUrl> with file binary
  → Save publicUrl

Step 2: Ensure category exists
  GET /categories/nested
  OR POST /categories (if admin creating new)

Step 3: Create product + variants
  POST /products/admin
  Body: { productData: { name, category, images: [{ url: publicUrl }], ... }, variantData: [...] }

Step 4: Business adds to inventory
  POST /inventory
  Body: [{ productVariant: variantId, pincode, batches: [...] }]

Step 5: Product is searchable
  GET /products/user/search?pincode=110001&searchTerm=dolo

Step 6: Customer places order
  POST /orders
  Body: { items: [{ productVariant, quantity, mrp, sellingPrice }], deliveryType: "self-pickup" }
```

---

## Error Response Format

All errors follow this structure:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "stack": "Error stack trace (development only)"
}
```

Common HTTP status codes:
- `400` — Validation error / bad request
- `401` — Missing or invalid auth token
- `403` — Insufficient permissions
- `404` — Resource not found
- `409` — Duplicate / conflict (SKU, barcode, etc.)
- `500` — Internal server error
