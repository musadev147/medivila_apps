# Medivila Mobile Application API & Integration Documentation
> **Configured API Server**: `https://api.medivila.com`  
> **API Root Base URL**: `https://api.medivila.com/api`  
> **Image & Asset Storage**: `https://api.medivila.com/storage/`  
> **Target Platforms**: Android & iOS (Flutter / React Native / Kotlin / Swift)  
> **Architecture**: RESTful JSON with Multipart Support for Prescriptions/Files  
> **Last Updated**: November 2026

---

## Table of Contents
1. [Quick Start & Server Environment Configuration](#1-quick-start--server-environment-configuration)
2. [App Launch & Bootstrap API](#2-app-launch--bootstrap-api)
3. [Product Catalog & E-Commerce Module](#3-product-catalog--e-commerce-module)
4. [Shopping Cart, Checkout & Order Submission](#4-shopping-cart-checkout--order-submission)
5. [Strict Delivery Charge & Address Resolution Rules](#5-strict-delivery-charge--address-resolution-rules)
6. [Online Specialist Doctor Consultation (Telemedicine)](#6-online-specialist-doctor-consultation-telemedicine)
7. [Diagnostic Lab Tests & Home Sample Collection](#7-diagnostic-lab-tests--home-sample-collection)
8. [Easy Prescription Upload (Order by Doctor's Slip)](#8-easy-prescription-upload-order-by-doctors-slip)
9. [B2B Wholesale & Pharmacy Supply Module](#9-b2b-wholesale--pharmacy-supply-module)
10. [User Authentication](#10-user-authentication)
11. [Medivila Loyalty Coin Wallet & Bonuses](#11-medivila-loyalty-coin-wallet--bonuses)
12. [Payment Gateways & COD Advance Policy](#12-payment-gateways--cod-advance-policy)
13. [Customer Support, Leads & Callbacks](#13-customer-support-leads--callbacks)
14. [Performance, 0ms Cache-First Rendering & App Architecture](#14-performance-0ms-cache-first-rendering--app-architecture)
15. [Screen-to-Endpoint Mapping Cheat Sheet](#15-screen-to-endpoint-mapping-cheat-sheet)

## Implementation verification (Flutter client)

This document includes both API integration guidance and backend contract examples. The rows below were checked against the current Flutter source. A route being documented or declared in `Endpoints` does **not** prove that the production server implements it; backend-only behavior, response examples, validation limits, and business rules must be confirmed against the server.

Read-only production GET requests were also checked on 2026-11-02 for bootstrap, products, product details, doctor departments, doctors, doctor slots, lab tests, and wholesale products. Their returned shapes were compatible with the current client parsers. No write request or authenticated request was sent during this check; all POST payload requirements and protected endpoints still need a safe authenticated integration test.

| Client operation | Request currently sent by the app |
| :--- | :--- |
| Bootstrap | `GET /api/bootstrap` |
| Category list | `GET /api/category` |
| Product list | `GET /api/products?page={page}&per_page=100&view=listing`, optionally `category_id` and `search` |
| Product details | `GET /api/products/{slug}` |
| Product detail suggestions | `GET /api/products?category_id={category_id}`; the current product is excluded in the app |
| Doctor departments | `GET /api/specialist-departments` |
| Doctor list | `GET /api/specialist-doctors`, optionally `department_id` and `search` |
| Doctor slots | `GET /api/specialist-doctors/{id}/slots?date=YYYY-MM-DD` |
| Doctor booking | `POST /api/consultation-bookings` as multipart form data |
| Lab-test catalog | `GET /api/lab-tests`, optionally `search` |
| Home lab booking | `POST /api/home-lab-bookings` as JSON |
| Prescription upload | `POST /api/prescriptions` as multipart form data |
| Product order | `POST /api/cartstore` as JSON |
| Order tracking | `GET /api/customers/{order_id}` |
| Wholesale catalog/application | `GET /api/wholesale/products`; `POST /api/wholesale-applications` as JSON |
| Phone login/profile/registration | `POST /api/userlogin`, `GET /api/user`, and `POST /api/users` |
| Signed-in wishlist | `GET /api/customers/wishlist/ids/`; `POST` or `DELETE /api/customers/wishlist/{product_id}/` |
| Signed-in notification badge | `GET /api/notifications/unread-count/` on login, resume, and every 60 seconds |

The app's base URL is configurable with the `BASE_URL` compile-time define and defaults to `https://api.medivila.com/api`. Requests use the shared Dio client in `lib/networks/api_client.dart`; the app sends an `Accept: application/json` header, attaches the stored access token except on requests marked `noAuth`, and lets Dio select JSON or multipart encoding from the request body.

The shared client also contains a refresh-token request to `/api/auth/token/refresh/`; it runs only when a stored refresh token is available and an authenticated request receives 401.

The following documented routes currently have no active app call path: related products, offers, delivery charges, payment methods, COD advances, customer order search, consultation/lab/wholesale tracking, lab categories, service banners, diagnostic-lab administration, coin endpoints, leads, and contacts. Some additional methods are declared but not invoked, including payment settings, wishlist listing, notification read/preferences, and the standalone app-config endpoint. Treat these sections as backend/reference documentation, not as features currently integrated by this Flutter app.

---

## 1. Quick Start & Server Environment Configuration

### 1.1 Base URLs
```dart
// Flutter Configuration Example
class ApiConfig {
  static const String baseUrl = "https://api.medivila.com";
  static const String apiUrl = "https://api.medivila.com/api";
  static const String storageUrl = "https://api.medivila.com/storage";
  static const String defaultImageFallback = "https://api.medivila.com/medivila-default.jpg";
}
```

### 1.2 Global Request Headers
| Header Name | Value | Required On |
| :--- | :--- | :--- |
| `Accept` | `application/json` | **All requests** |
| `Content-Type` | Chosen from the request body by Dio | Requests with a body; let Dio set multipart boundaries |
| `Authorization` | Bearer access token, when available | Authenticated requests; attached by the shared client |

### 1.3 Critical Rule: Image URL Resolution
Images stored in the backend database are returned in different path formats (relative, absolute, or storage paths). Mobile apps **must** follow this normalization algorithm:

```dart
// Flutter / Dart Image URL Helper
String resolveImageUrl(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) {
    return "https://api.medivila.com/medivila-default.jpg";
  }
  final clean = rawPath.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return clean;
  }
  final normalized = clean.replaceAll(RegExp(r'^/+'), '');
  if (normalized.startsWith('images/') || normalized.startsWith('storage/')) {
    return "https://api.medivila.com/$normalized";
  }
  return "https://api.medivila.com/storage/$normalized";
}
```

### 1.4 Bangladeshi Phone Number Validation Rule
All customer, patient, and doctor phone numbers in Bangladesh must match:
- Regex: `^01[3-9]\d{8}$` (11 digits, begins with `01`, 3rd digit between 3-9).
- Clean phone numbers by stripping spaces, hyphens, and `+88` before sending to the API.

---

## 2. App Launch & Bootstrap API

The app calls this endpoint on the splash screen. It also starts separate product, lab-test, doctor, profile-restore, and local-cart operations, so app startup is **not** a single-network-request bootstrap.

### `GET /api/bootstrap`
- **Client behavior**: Accepts either a root object or a response with a `data` object. The Flutter model reads `logo`, `brand_slogan`, `categories`, `banners`, `districts`, `contactInfo`, `bonus`, and `coinPackages`; missing arrays are treated as empty and some fields have client-side defaults.
- **Server behavior**: Cache implementation and the availability of each field cannot be verified from this client repository.
- **Response Structure**:
```json
{
  "success": true,
  "data": {
    "logo": "website_logos/logo.png",
    "brand_slogan": "আপনার নির্ভরযোগ্য অনলাইন ফার্মেসি ও স্বাস্থ্যসেবা",
    "categories": [
      {
        "id": 1,
        "name": "Prescription Medicine",
        "bn_name": "প্রেসক্রিপশন মেডিসিন",
        "slug": "prescription-medicine",
        "image": "categories/med.png",
        "children": []
      }
    ],
    "banners": [
      {
        "id": 1,
        "title": "বিশেষ ছাড় ওষুধে",
        "image": "banners/banner1.jpg",
        "link": "/category/prescription-medicine"
      }
    ],
    "districts": [
      {
        "id": 1,
        "district_name": "ঢাকার ভিতরে",
        "delivery_charge": 70,
        "estimated_days": 2,
        "delivery_note": "ঢাকার ভিতরে দ্রুত হোম ডেলিভারি"
      },
      {
        "id": 2,
        "district_name": "ঢাকার বাইরে",
        "delivery_charge": 130,
        "estimated_days": 4,
        "delivery_note": "ঢাকার বাইরে সারাদেশে হোম ডেলিভারি"
      }
    ],
    "contactInfo": {
      "phone": "01625491153",
      "email": "medivila.com@gmail.com",
      "address": "Dhaka, Bangladesh"
    },
    "bonus": {
      "first_reg_bonus": 50,
      "bonus_percentage": 5,
      "coin_name": "Medivila Coin"
    },
    "coinPackages": [
      {
        "id": 1,
        "package_name": "Starter 100 Coins",
        "coins": 100,
        "price": 95
      }
    ]
  }
}
```
The example is illustrative, not a captured production response. In particular, delivery-rate values must be confirmed; they currently differ from the hard-coded checkout values described in Section 5.

---

The `banners` array contains slider items created in the admin panel. `image` is required when creating a slider, while `title`, `description`, and `link` can be empty. Show only active items when `is_active` is present, order by `sort_order`, and pass the image through `resolveImageUrl`. Relative links are in-app routes; absolute URLs can open in a browser.

## 3. Product Catalog & E-Commerce Module

### 3.1 Product Listing & Search
- **Endpoint**: `GET /api/products`
- **Query parameters sent by this app**: `page`, `per_page=100`, `view=listing`; optional `category_id` and `search`. The client follows `last_page` when the response is paginated.
- **Response parsing**: Accepts a root list or an object whose `data` is a list. Confirm any additional fields and filtering behavior with the backend.
- **Response**:
```json
{
  "data": [
    {
      "id": 101,
      "slug": "napa-extra-500mg",
      "name": "Napa Extra 500mg Tablet",
      "price": 30.00,
      "discount_price": 27.00,
      "category_id": 1,
      "clothing": false,
      "images": [
        { "id": 1, "image": "products/napa.jpg" }
      ],
      "colors": [],
      "single_product_sizes": [
        { "id": 1, "size": "10 Tablets / Strip" },
        { "id": 2, "size": "1 Box (120 Tablets)" }
      ],
      "bulk_discounts": [
        {
          "id": 1,
          "title": "Buy 5 Strips Get 5% Off",
          "offer_quantity": 5,
          "discount_percentage": 5
        }
      ],
      "bumps": []
    }
  ],
  "current_page": 1,
  "last_page": 10,
  "per_page": 15,
  "total": 150
}
```

### 3.2 Product Details
- **Endpoint**: `GET /api/products/{slug}`
- **Client status**: Called by the product detail screen. The client accepts either a root product object or a product in `data`. Exact server fields should be confirmed against a real response.

### 3.3 Related Products
- **Endpoint**: `GET /api/products/{slug}/related`
- **Client status**: The app does not call this route. Product details load suggestions through the verified product-list `category_id` filter instead; the current product is excluded from the results.

### 3.4 Categories
- **Endpoint**: `GET /api/category` (or single `GET /api/category/{id}`)
- **Client status**: Not currently called as a standalone endpoint. The home/category UI reads categories from bootstrap.

### 3.5 Offers & Flash Deals
- **Endpoint**: `GET /api/offers`
- **Client status**: Not currently called by this app.

---

## 4. Shopping Cart, Checkout & Order Submission

### 4.1 Create Product Order
- **Endpoint called by the app**: `POST /api/cartstore` (JSON)
- **Client sends**: `order_id`, `customer_name`, `phone_number`, `customer_address`, `order_type`, `delivery_charge`, `product_price`, `total`, `payment_method`, `delivery_note`, and `items`.
- The current client does **not** send `city`, `state`, or `subtotal`; do not treat these example fields as fields sent by this app. Whether the server requires them must be verified with the backend.
- **Request Body**:
```json
{
  "order_id": "A2C84920",
  "customer_name": "Ashraful Islam",
  "phone_number": "01712345678",
  "customer_address": "House 12, Road 4, Sector 7, Uttara, Dhaka",
  "order_type": "product",
  "delivery_charge": 60,
  "product_price": 999.00,
  "total": 1059.00,
  "payment_method": "cod",
  "delivery_note": "Please call before delivery",
  "items": [
    {
      "type": "product",
      "product_id": 101,
      "product_name": "Portable Turbo Fan",
      "quantity": 1,
      "price": 999.00,
      "size": null
    }
  ]
}
```

### 4.2 Mixed Order (Medicine + Lab Test)
Mixed orders are not currently represented in the Flutter cart: cart line items are serialized as `type: "product"` and lab bookings use the separate `/api/home-lab-bookings` endpoint. The mixed-order example previously shown here was not a request made by this app. Confirm server support and agree on a payload before implementing mixed checkout.

### 4.3 Order Tracking
- **Endpoint**: `GET /api/customers/{order_id}`
- **Client status**: Called with the entered order ID. The client returns the response map; status values and response fields must be confirmed against the backend.

### 4.4 Customer Order History by Phone
- **Endpoint**: `GET /api/customers/search/customerdata?search={phone}`
- **Client status**: Not currently called by this app.

---

## 5. Strict Delivery Charge & Address Resolution Rules

### 5.1 Intended Delivery Rule and Current Client Mismatch
The intended policy documented here is to calculate delivery charges from the customer's selected district, rather than allowing a manual "inside/outside Dhaka" choice. **The current Flutter checkout does not follow this policy**: it displays two manually selectable choices ("ঢাকা সিটি" ৳60 and "ঢাকার বাইরে" ৳120), defaults to ৳60, and submits the selected amount. It does not call `/api/deliverycharges` or derive the charge from an address/district.

The documented example rates elsewhere in this file (৳70/৳130) also differ from the current client rates (৳60/৳120). Confirm the authoritative rates and district rules with the API owner before changing either side; the production server's behavior cannot be established from this client repository.

### 5.2 Intended Dhaka District Rule (Not Enforced by Current Client)
> [!IMPORTANT]
> **Dhaka District ONLY = Inside Dhaka (`ঢাকার ভিতরে`)**  
> Dhaka Division contains 13 separate districts: Dhaka, Gazipur, Narayanganj, Manikganj, Munshiganj, Rajbari, Madaripur, Gopalganj, Faridpur, Tangail, Kishoreganj, Narsingdi, Shariatpur.  
> **Only Dhaka District qualifies for the "Inside Dhaka" rate.** All other 12 districts in Dhaka division and all districts in other divisions MUST receive the "Outside Dhaka" rate.

### 5.3 Intended UI Display Rules (Not Current Client Behavior)
1. **Before District is Selected**:
   - Do **NOT** display `"Free"` or `"ফ্রি"`.
   - Display a neutral placeholder: `"--"` or `"Select district to calculate"` / `"জেলা অনুযায়ী যুক্ত হবে"`.
   - Keep the checkout confirmation button disabled or display `"অর্ডার নিশ্চিত করুন (জেলা নির্বাচন করুন)"`.
2. **After District is Selected**:
   - If Dhaka District: Automatically apply ৳70 (or DB rate) and display badge `"ঢাকার ভিতরে (ঢাকা জেলা)" · ২-৩ কার্যদিবস`.
   - If Any Other District: Automatically apply ৳130 (or DB rate) and display badge `"ঢাকার বাইরে ({district} জেলা)" · ৩-৫ কার্যদিবস`.

### 5.4 Reference Flutter / Dart Implementation Helper
The following is a reference for the intended policy only; it is **not** the implementation currently used by the app. It must not be presented as evidence that checkout already calculates district rates:

```dart
class DeliveryHelper {
  /// Strictly checks whether a given district is Dhaka District.
  static bool isDhakaDistrict(String? districtName) {
    if (districtName == null || districtName.trim().isEmpty) return false;
    final normalized = districtName.trim().toLowerCase();

    // Guard against outside districts in Dhaka division
    const outsideDistricts = [
      'gazipur', 'গাজীপুর',
      'narayanganj', 'নারায়ণগঞ্জ',
      'manikganj', 'মানিকগঞ্জ',
      'munshiganj', 'মুন্সিগঞ্জ',
      'narsingdi', 'নরসিংদী',
      'tangail', 'টাঙ্গাইল',
      'faridpur', 'ফরিদপুর',
      'kishoreganj', 'কিশোরগঞ্জ',
      'gopalganj', 'গোপালগঞ্জ',
      'madaripur', 'মাদারীপুর',
      'rajbari', 'রাজবাড়ী',
      'shariatpur', 'শরীয়তপুর'
    ];

    for (final outside in outsideDistricts) {
      if (normalized.contains(outside)) return false;
    }

    return normalized == 'dhaka' ||
        normalized == 'ঢাকা' ||
        normalized == 'dhaka district' ||
        normalized == 'ঢাকা জেলা' ||
        normalized == 'dhaka zilla' ||
        normalized == 'ঢাকার ভিতরে' ||
        normalized == 'inside dhaka';
  }

  /// Auto-calculates delivery charge based on districts list from /api/bootstrap or /api/deliverycharges
  static Map<String, dynamic> resolveDeliveryCharge(
      List<dynamic> deliveryCharges, String? districtName) {
    if (districtName == null || districtName.trim().isEmpty) {
      return {
        'charge': 0.0,
        'estimated_days': '',
        'label': 'জেলা নির্বাচন করুন',
        'is_selected': false,
      };
    }

    final isDhaka = isDhakaDistrict(districtName);

    // Default fallbacks
    double charge = isDhaka ? 70.0 : 130.0;
    String estimatedDays = isDhaka ? '২-৩' : '৩-৫';
    String label = isDhaka ? 'ঢাকার ভিতরে (ঢাকা জেলা)' : 'ঢাকার বাইরে ($districtName জেলা)';

    if (deliveryCharges.isNotEmpty) {
      for (final item in deliveryCharges) {
        final name = (item['district_name'] ?? '').toString().toLowerCase();
        if (isDhaka) {
          if ((name.contains('ঢাকা') || name.contains('dhaka') || name.contains('ভিতরে')) &&
              !name.contains('বাইরে') && !name.contains('outside')) {
            charge = double.tryParse(item['delivery_charge'].toString()) ?? charge;
            estimatedDays = item['estimated_days']?.toString() ?? estimatedDays;
            break;
          }
        } else {
          if (name.contains('বাইরে') || name.contains('outside') || name.contains('বাহিরে')) {
            charge = double.tryParse(item['delivery_charge'].toString()) ?? charge;
            estimatedDays = item['estimated_days']?.toString() ?? estimatedDays;
            break;
          }
        }
      }
    }

    return {
      'charge': charge,
      'estimated_days': estimatedDays,
      'label': label,
      'is_selected': true,
      'is_dhaka': isDhaka,
    };
  }
}
```

---

## 6. Online Specialist Doctor Consultation (Telemedicine)

Complete telemedicine workflow for browsing medical departments, viewing doctor schedules, booking appointments, and conducting encrypted video consultations.

### 6.1 Specialist Departments
- **Endpoint**: `GET /api/specialist-departments`
- **Client status**: Called by the doctor directory. Exact returned departments are server data and should be confirmed from a live response.

### 6.2 Specialist Doctors List & Filters
- **Endpoint**: `GET /api/specialist-doctors`
- **Query Parameters**:
  - `department_id`: Filter by department ID
  - `search`: Search text
- **Client status**: Only the two parameters above are sent by this app; the other filters sometimes listed in backend examples are not currently exposed or sent.

### 6.3 Doctor Profile & 7-Day Schedule
- **Endpoint**: `GET /api/specialist-doctors/{id}`
- **Client status**: The route is declared but there is no client service method or current call to fetch a doctor profile by ID. The response fields and schedule described by backend examples are not verified here.

### 6.4 Available Time Slots for Specific Date
- **Endpoint**: `GET /api/specialist-doctors/{id}/slots?date=YYYY-MM-DD`
- **Observed production response**: Slot items use `time_slot`, `start_time`, `end_time`, and `is_available`. The Flutter parser accepts either `time_slot` or `time` as the display value.
- **Response**:
```json
{
  "status": true,
  "doctor_id": 4,
  "date": "2026-11-02",
  "day_name": "Monday",
  "slots": [
    {
      "time_slot": "06:00 PM - 06:15 PM",
      "start_time": "18:00",
      "end_time": "18:15",
      "is_available": false
    },
    {
      "time_slot": "06:15 PM - 06:30 PM",
      "start_time": "18:15",
      "end_time": "18:30",
      "is_available": true
    }
  ]
}
```

### 6.5 Book Doctor Appointment
- **Endpoint**: `POST /api/consultation-bookings`
- **Content-Type**: `multipart/form-data`
- **Fields sent by the main booking screen**: `doctor_id`, `patient_phone`, `problem`, `appointment_date`, `appointment_time_slot`, and `consultation_type=video`; optionally `medical_documents[]`.
- **Fields sent by the doctor-list booking sheet**: `doctor_id`, `patient_name`, `patient_phone`, `appointment_date`, `appointment_time_slot`, and `consultation_type=video`.
- The main screen allows up to 3 images. The Flutter picker does not select PDF files. The app does not send `patient_age`, `patient_gender`, `patient_problem`, `prescription_file`, payment fields, or transaction IDs. Server-side accepted fields, file limits, and validation rules need backend confirmation.
- **Response**:
```json
{
  "status": true,
  "message": "আপনার ডাক্তারের অ্যাপয়েন্টমেন্ট সফলভাবে বুক করা হয়েছে!",
  "booking": {
    "id": 14,
    "booking_id": "DOC-20261031-XY78Z",
    "fee": 400,
    "meeting_link": "https://meet.jit.si/medivila-doc-20261031-xy78z",
    "status": "pending",
    "payment_status": "pending"
  }
}
```

### 6.6 Real-Time Consultation Tracking
- **Endpoint**: `GET /api/consultation-bookings/track/{booking_id}`
- **Client status**: A path helper exists, but the app has no tracking call. The response fields and document URL behavior are backend contract details that must be verified with the API owner.

---

## 7. Diagnostic Lab Tests & Home Sample Collection

### 7.1 Lab Categories
- **Endpoint**: `GET /api/lab-categories`
- **Client status**: Not called by the app; the home screen gets categories from bootstrap.

### 7.2 Home Service Banners (হোমপেজ সার্ভিস ব্যানার কার্ডস)
- **Endpoint**: `GET /api/service-banners`
- **Method**: `GET`
- **Description**: Dedicated endpoint specifically for the **Home Screen Service Banners Carousel** (the top cards under the main slider displaying title, badge, price, card color, button, and image). Only banners explicitly added or selected as service banners in the admin panel are returned here.
- **Admin Configuration**: Managed via Admin Panel under **Site Management > Banner > Service Banners (সার্ভিস ব্যানার কার্ডসমূহ)**. The admin can either link an existing lab test (auto-filling name, price, image, and link) or create a completely custom service banner.

**Client status:** This route is not declared or called by the current Flutter app. The separate service-banner schema and renderer below are backend/integration reference only, not a verified active app integration.

#### Key Response Fields
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Unique service banner ID |
| `lab_test_id` | `int?|null` | Optional foreign key referencing the underlying lab test (if linked) |
| `title` | `string` | Banner/Service title (e.g. `"CBC (Complete Blood Count)"`, `"PBF (Peripheral Blood Film)"`) |
| `tag` | `string` | Top badge/pill (e.g. `"HOME"`, `"Specialist"`, `"20% OFF"`) |
| `button_text` | `string` | Button text label (e.g. `"Book Now ↗"`, `"অর্ডার করুন"`) |
| `button_link` | `string?|null` | Target navigation route/URL (e.g. `"/lab-tests/cbc"`, `"/appointment"`, or external URL). If empty, app should open the test booking dialog |
| `card_color` | `string?|null` | Card background color or Tailwind gradient string (e.g. `"from-[#eaf9ff] via-[#eaf9ff] to-[#ffffff]"` or `"#eaf9ff"`) |
| `image_url` | `string?|null` | Absolute URL of the banner illustration / product image |
| `original_price` | `float?|null` | Regular price before discount |
| `discounted_price` | `float?|null` | Discounted / offer price |
| `sort_order` | `int` | Display sort order (ascending) |
| `is_active` | `bool` | Whether the banner is active on the homepage |
| `lab_test` | `object?|null` | Complete linked lab test details (if linked) |

### 7.3 Diagnostic Lab Tests & Medical Catalog
- **Endpoint**: `GET /api/lab-tests`
- **Method**: `GET`
- **Client status**: Called by the app; it optionally sends `search`. The client accepts either a root list or an object with a `data` list, then performs an additional local name/description/sample-type search.
- **Admin Configuration**: Managed via Admin Panel under **Lab & Doctor Services > Lab Tests**.

The catalog includes `tag`, `category_slug`, `category_name`, `link`, `button_text`, `test_includes`, and `is_package` where available. `image` is already a resolved URL. Staff can create a test with a name and original price; when they leave discounted price blank, it equals original price. Handle a missing image and an empty `labs` array. `link` is an optional card destination; otherwise use the normal booking flow.

#### Flutter / Dart Model & Dynamic Card Renderer
```dart
import 'package:flutter/material.dart';

class ServiceBannerItem {
  final int id;
  final String name;
  final String tag;
  final String buttonText;
  final String? link;
  final String? cardColor;
  final String? imageUrl;
  final double originalPrice;
  final double discountedPrice;

  ServiceBannerItem({
    required this.id,
    required this.name,
    required this.tag,
    required this.buttonText,
    this.link,
    this.cardColor,
    this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
  });

  factory ServiceBannerItem.fromJson(Map<String, dynamic> json) {
    return ServiceBannerItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tag: json['tag'] ?? 'HOME',
      buttonText: json['button_text'] ?? 'Book Now',
      link: json['link'],
      cardColor: json['card_color'],
      imageUrl: json['image_url'] ?? json['image'],
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Parses Tailwind gradient string or hex color to Flutter BoxDecoration
  BoxDecoration getBoxDecoration() {
    final raw = (cardColor ?? '').trim();
    if (raw.startsWith('#')) {
      final hex = raw.replaceAll('#', '');
      final color = Color(int.parse(hex.length == 6 ? 'FF' + hex : hex, radix: 16));
      return BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    // Default or Tailwind gradient fallback
    // e.g. from-[#eaf9ff] via-[#eaf9ff] to-[#ffffff]
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEAF9FF), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
```

### 7.4 Book Home Sample Collection
- **Endpoint**: `POST /api/home-lab-bookings`
- **Content-Type sent by the app**: `application/json`
- **Payload sent by the current app**:
```json
{
  "patient_name": "Kamal Hossain",
  "patient_phone": "01799887766",
  "patient_address": "House 5, Road 2, Sector 3, Uttara, Dhaka",
  "time_slot": "সকাল (8 AM - 11 AM)",
  "lab_test_id": 1,
  "lab_test_name": "Complete Blood Count (CBC)"
}
```
- The current client does not send a collection date, a diagnostic `lab_id`/`lab_name`, a fee, or an `items` array. Confirm which fields the server requires.
- **Response handling**: The client accepts a 200/201 JSON object and displays `message` if present; the example below is illustrative and not validated against a live server.
```json
{
  "status": true,
  "message": "হোম ল্যাব টেস্টের স্যাম্পল কালেকশন বুকিং সফলভাবে গ্রহণ করা হয়েছে!",
  "booking": {
    "booking_id": "LAB-20261101-KP991",
    "subtotal": 400,
    "collection_fee": 100,
    "total": 500,
    "status": "pending"
  }
}
```

### 7.5 Track Lab Test Sample Collection
- **Endpoint**: `GET /api/home-lab-bookings/track/{booking_id}`
- **Client status**: No tracking call is currently implemented.

### 7.6 Diagnostic Lab Directory Management (Staff Only)
- **Endpoints**: `GET /api/diagnostic-labs`, `POST /api/diagnostic-labs`, `PUT /api/diagnostic-labs/{id}`, `DELETE /api/diagnostic-labs/{id}`
- **Client status**: No such endpoints or staff API calls exist in this Flutter app. The route/authentication claims need backend confirmation.

---

## 8. Easy Prescription Upload (Order by Doctor's Slip)

Users can photograph their paper prescription or attach a medical PDF. Registered pharmacists review the document, prepare the cart, and call the user for delivery confirmation.

### 8.1 Upload Prescription
- **Endpoint**: `POST /api/prescriptions`
- **Content-Type**: `multipart/form-data`
- **Fields sent by the app**: `name`, `phone`, optional `notes`, and `file`. The current UI selects an image only; the client uploads it with the filename `prescription.jpg`.
- The app does not select PDF files. Accepted server file types, maximum size, and response fields beyond the `message` read by the UI must be confirmed with the backend.
- **Response**:
```json
{
  "message": "Prescription uploaded successfully",
  "data": {
    "id": 25,
    "name": "Akash Saha",
    "phone": "01711223344",
    "notes": "1 month supply",
    "file": "prescriptions/prescription_xyz.pdf"
  },
  "file_url": "https://api.medivila.com/storage/prescriptions/prescription_xyz.pdf"
}
```

---

## 9. B2B Wholesale & Pharmacy Supply Module

For pharmacies, medical stores, and clinics purchasing bulk medicines.

### 9.1 Wholesale Products Catalog
- **Endpoint**: `GET /api/wholesale/products`
- **Client status**: Called without query parameters; the documented filters are not currently sent.

### 9.2 Submit Wholesale Application
- **Endpoint**: `POST /api/wholesale-applications`
- **Content-Type sent by the app**: JSON
- **Fields sent by the current form**: `business_name`, `owner_name`, `phone`, and `drug_license`. The form requires business name and phone; the other fields in older backend examples are not collected or sent by this UI.
- Confirm server-side required fields and whether file uploads are supported before treating the multipart example as the current contract.
- **Response**:
```json
{
  "status": true,
  "message": "পাইকারি (হোলসেল) অ্যাকাউন্ট আবেদন সফলভাবে গৃহীত হয়েছে।",
  "application_code": "WHS-20261028-W981Z"
}
```

### 9.3 Track Wholesale Application Status
- **Endpoint**: `GET /api/wholesale/track/{query}` (Query can be `application_code` or `phone`)
- **Client status**: A path helper exists, but there is no tracking service call or UI flow in the app.

---

## 10. User Authentication

The Flutter client implements phone-based login and a registration request. The order-gating policy and authentication rules described by backend examples are not verifiable from this repository; confirm them with the API owner.

### 10.1 Phone Login

- **Endpoint**: `POST /api/userlogin`
- **Request Body**:
```json
{
  "phone": "01712345678"
}
```
- **Successful Response (HTTP 200)**:
```json
{
  "user": {
    "id": 12,
    "name": "Ashraful Islam",
    "phone": "01712345678",
    "address": "House 12, Road 4, Sector 7, Uttara, Dhaka",
    "points": 150,
    "type": "user"
  },
  "token": "12|AbCdEf123456789TokenStringHere"
}
```
- **Client behavior**: Requires a `user` object and non-empty `token` in the successful response. It does not send a `name` with the login request. Error status, order-gating behavior, and server message are backend-dependent.

### 10.2 Registration
- **Endpoint**: `POST /api/users`
- **Content-Type**: JSON
- **Fields sent by the app**: `name`, `phone`, `phone_number` (integer), `password`, `password_confirmation`, and `type: "user"`. On successful registration, the app performs phone login to obtain a session.
- Registration requirements and success response must be verified with the backend.

### 10.3 Get Authenticated User Profile
- **Endpoint**: `GET /api/user`
- **Headers**: The shared client attaches the stored bearer access token when available.

---

## 11. Medivila Loyalty Coin Wallet & Bonuses

### 11.1 Check User Points Balance
- **Endpoint**: `GET /api/users/{phone}`
- **Response**: `{ "id": 12, "name": "Ashraful", "phone": "01712345678", "points": 150 }`
- **Client status**: Not called by the app.

### 11.2 Coin Settings & Top-Up Packages
- **Endpoint**: `GET /api/bonuscoins` -> Registration bonus and coin conversion rate (e.g. 1 coin = 1 BDT).
- **Endpoint**: `GET /api/coinpackages` -> Top-up coin packages.
- **Client status**: These routes are not called by the app. Conversion rates and package behavior are backend claims and need server verification.

### 11.3 Top-Up Coins Request
- **Endpoint**: `POST /api/cointransactions`
- **Client status**: Not called by the app.
- **Body**:
```json
{
  "name": "Ashraful",
  "phone": "01712345678",
  "wallet_number": "01712345678",
  "coin_package_id": 1
}
```

---

## 12. Payment Gateways & COD Advance Policy

### 12.1 Delivery Charges List
- **Endpoint**: `GET /api/deliverycharges`
- **Client status**: Not called by the app. Current checkout uses hard-coded, manually selected rates; see Section 5.

### 12.2 Payment Methods
- **Endpoint**: `GET /api/paymentmethod`
- **Client status**: Not called by the app. Payment options currently shown at checkout are not loaded from this endpoint.

### 12.3 COD Advance Policy
- **Endpoint**: `GET /api/codadvances`
- **Client status**: Not called by the app; server behavior needs verification.

---

## 13. Customer Support, Leads & Callbacks

### 13.1 Quick Lead (Callback Request)
- **Endpoint**: `POST /api/leads`
- **Client status**: Not called by the app.
- **Body**:
```json
{
  "customer_name": "Sumon",
  "phone_number": "01812345678",
  "product_name": "Inquiry about insulin",
  "page_url": "mobile_app_home"
}
```

### 13.2 Contact Inquiry Message
- **Endpoint**: `POST /api/contacts`
- **Client status**: Not called by the app.
- **Body**:
```json
{
  "name": "Naimur",
  "email": "naimur@gmail.com",
  "phone": "01912345678",
  "subject": "Medicine availability inquiry",
  "message": "Is human insulin available in your hub?",
  "status": 1
}
```

---

## 14. Performance, 0ms Cache-First Rendering & App Architecture

### 14.1 Suggested Product Transition Pattern (Not Current Client Behavior)
The following is an integration suggestion, not the current app implementation:
1. **Pass Seed Product in Route Arguments**: When navigating from product list to product detail screen, pass the already-fetched `Product` object as an argument:
```dart
// Flutter Example: 0ms Instant Transition
Navigator.pushNamed(
  context,
  '/product-detail',
  arguments: product, // Instant seed data
);
```
2. **Immediate Render**: The product detail screen immediately displays the title, price, images, and description from the seed product.
3. **Background Sync**: In the background, call `GET /api/products/{slug}` to quietly fetch any additional details (like related products or live stock updates) without blocking the user.

### 14.2 HTTP Client Used by This App

The app uses `lib/networks/api_client.dart`, not a separate `SharedPreferences` interceptor. The API base URL comes from the `BASE_URL` compile-time define (default `https://api.medivila.com/api`); credentials use `FlutterSecureStorage`, and a 401 may trigger one token-refresh attempt when a refresh token is available. Requests use the shared Dio instance. See the source file for exact behavior.

---

## 15. Screen-to-Endpoint Mapping Cheat Sheet

Only rows marked as integrated below are currently called by this Flutter app. See the implementation verification section for the unintegrated backend/reference routes.

| Mobile App Screen | Endpoint | Method | Current use |
| :--- | :--- | :--- | :--- |
| **Splash / Home** | `/api/bootstrap` | `GET` | Fetch categories, banners, and bootstrap data |
| **Home / Search / Category** | `/api/products?page={page}&per_page=100&view=listing` | `GET` | Product listing; optional `search` and `category_id` |
| **Product Detail** | `/api/products/{slug}` | `GET` | Fetch product details |
| **Doctor Directory** | `/api/specialist-departments` | `GET` | Fetch departments |
| **Doctor Directory** | `/api/specialist-doctors` | `GET` | Fetch doctors; optional `department_id` and `search` |
| **Doctor Booking** | `/api/specialist-doctors/{id}/slots?date={date}` | `GET` | Fetch available time slots |
| **Doctor Booking** | `/api/consultation-bookings` | `POST` | Submit booking as multipart form data |
| **Home / Lab Tests** | `/api/lab-tests` | `GET` | Fetch tests; optional `search` |
| **Lab Booking** | `/api/home-lab-bookings` | `POST` | Submit patient/test fields as JSON |
| **Prescription Upload** | `/api/prescriptions` | `POST` | Upload image and patient details as multipart form data |
| **Cart / Checkout** | `/api/cartstore` | `POST` | Submit product order as JSON |
| **Order Tracking** | `/api/customers/{order_id}` | `GET` | Fetch order information |
| **Wholesale Catalog** | `/api/wholesale/products` | `GET` | Fetch catalog without query parameters |
| **Wholesale Application** | `/api/wholesale-applications` | `POST` | Submit application as JSON |
| **Login / Registration / Profile** | `/api/userlogin`, `/api/users`, `/api/user` | `POST`, `POST`, `GET` | Phone login, registration, and profile restore |
| **Signed-in Wishlist** | `/api/customers/wishlist/ids/`, `/api/customers/wishlist/{product_id}/` | `GET`, `POST`, `DELETE` | Load, add, and remove wishlist products |
| **Signed-in Notifications** | `/api/notifications/unread-count/` | `GET` | Poll unread count every 60 seconds and on resume |
