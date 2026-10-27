# Medivila Mobile Application API & Integration Documentation
> **Live Production Server**: `https://api.medivila.com`  
> **API Root Base URL**: `https://api.medivila.com/api`  
> **Image & Asset Storage**: `https://api.medivila.com/storage/`  
> **Target Platforms**: Android & iOS (Flutter / React Native / Native)  
> **Architecture**: RESTful JSON with Multipart Support for Prescriptions/Files  

---

## 1. Quick Start & Server Environment Configuration

### 1.1 Base URLs
```dart
// Flutter Configuration Example
class ApiConfig {
  static const String baseUrl = "https://data.medivila.com";
  static const String apiUrl = "https://data.medivila.com/data";
  static const String storageUrl = "https://data.medivila.com/storage";
  static const String defaultImageFallback = "https://data.medivila.com/medivila-default.jpg";
}
```

### 1.2 Global Request Headers
| Header Name | Value | Required On |
| :--- | :--- | :--- |
| `Accept` | `application/json` | **All requests** |
| `Content-Type` | `application/json` (or `multipart/form-data`) | All POST/PUT requests |
| `Authorization` | `Bearer <token>` | User Profile, Orders, Authenticated calls |

### 1.3 Critical Rule: Image URL Resolution
Images stored in the backend database are returned in different path formats (relative, absolute, or storage paths). Mobile apps **must** follow this normalization algorithm:

```dart
// Flutter / Dart Image URL Helper
String resolveImageUrl(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) {
    return "https://data.medivila.com/medivila-default.jpg";
  }
  final clean = rawPath.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return clean;
  }
  final normalized = clean.replaceAll(RegExp(r'^/+'), '');
  if (normalized.startsWith('images/') || normalized.startsWith('storage/')) {
    return "https://data.medivila.com/$normalized";
  }
  return "https://data.medivila.com/storage/$normalized";
}
```

### 1.4 Bangladeshi Phone Number Validation Rule
All customer, patient, and doctor phone numbers in Bangladesh must match:
- Regex: `^01[3-9]\d{8}$` (11 digits, begins with `01`, 3rd digit between 3-9).
- Clean phone numbers by stripping spaces, hyphens, and `+88` before sending to the API.

---

## 2. App Launch & Bootstrap API (Single-Call Initialization)

The mobile app should call this endpoint on the splash screen to load global config, banners, categories, delivery charges, logos, and settings in **one single network request**.

### `GET /api/bootstrap`
- **Description**: Consolidates categories, menus, sliders, district delivery rates, contact info, coin packages, and brand info.
- **Cache**: Cached on server with Redis/File cache for ultra-low latency response.
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
        "district_name": "Dhaka",
        "delivery_charge": 60,
        "estimated_days": "1-2 Days",
        "delivery_note": "ঢাকা সিটির ভেতরে দ্রুত ডেলিভারি"
      },
      {
        "id": 2,
        "district_name": "Chittagong",
        "delivery_charge": 120,
        "estimated_days": "2-3 Days",
        "delivery_note": "ঢাকার বাইরে কুরিয়ার ডেলিভারি"
      }
    ],
    "contactInfo": {
      "phone": "01XXXXXXXXX",
      "email": "support@medivila.com",
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

---

## 3. Product Catalog & E-Commerce Module

### 3.1 Product Listing & Search
- **Endpoint**: `GET /api/products`
- **Query Parameters**:
  - `page`: Page number (Default: `1`)
  - `per_page` or `limit`: Items per page (Default: `15`, max `100`)
  - `search`: Keyword for search (Name, Generic, Category, Price)
  - `category_id`: Filter by specific category ID
  - `category_ids`: Comma-separated category IDs (e.g. `1,3,5`)
  - `view`: Pass `listing` for lighter payload on product grids
- **Pagination**: Responses include `current_page`, `last_page`, `per_page`, and `total`. Clients should request each page through `last_page`; `per_page` can be set to `100` to reduce the number of requests.
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
- **Description**: Returns detailed product info, description HTML (`homepage`), full photo gallery, color variants, sizes, bulk quantity discounts, and add-on bump offers.

### 3.3 Related Products
- **Endpoint**: `GET /api/products/{slug}/related`
- **Description**: Returns other products within the same therapeutic category.

### 3.4 Categories
- **Endpoint**: `GET /api/category` (or single `GET /api/category/{id}`)
- **Description**: List of all medical categories and subcategories with icons.

### 3.5 Offers & Flash Deals
- **Endpoint**: `GET /api/offers`

---

## 4. Shopping Cart, Checkout & Order Submission

### 4.1 Create Order (Cash On Delivery & Online Payment)
- **Endpoint**: `POST /api/cartstore` (or `POST /api/customers`)
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "order_id": "MED1740643200",
  "customer_name": "Mohammad Rahim",
  "phone_number": "01712345678",
  "customer_address": "House 12, Road 4, Dhanmondi, Dhaka",
  "order_type": "product",
  "delivery_charge": 60,
  "product_price": 450,
  "total": 510,
  "payment_method": "cod",
  "delivery_note": "Please call before delivery",
  "items": [
    {
      "type": "product",
      "product_id": 101,
      "product_name": "Napa Extra 500mg Tablet",
      "quantity": 3,
      "price": 27.00,
      "size": "10 Tablets / Strip",
      "color": null
    }
  ]
}
```

### 4.2 Mixed Order (Medicine + Lab Test)
If the user adds both medicine and diagnostic lab tests into the cart:
```json
{
  "order_id": "MED1740643201",
  "customer_name": "Fatima Begum",
  "phone_number": "01812345678",
  "customer_address": "Mirpur 10, Dhaka",
  "order_type": "mixed",
  "delivery_charge": 60,
  "product_price": 250,
  "total": 1010,
  "payment_method": "cod",
  "items": [
    {
      "type": "product",
      "product_id": 101,
      "product_name": "Napa Extra",
      "quantity": 1,
      "price": 250
    },
    {
      "type": "lab_test",
      "lab_test_id": 4,
      "lab_id": 1,
      "lab_test_name": "HbA1c Diabetes Profile",
      "lab_name": "Popular Diagnostic Center",
      "price": 700,
      "patient_count": 1,
      "report_time": "24 Hours"
    }
  ]
}
```

### 4.3 Order Tracking
- **Endpoint**: `GET /api/customers/{order_id}`
- **Description**: Returns order delivery status (`New Order`, `Processing`, `Shipped`, `Delivered`, `Cancelled`), items list, and courier consignment details.

### 4.4 Customer Order History by Phone
- **Endpoint**: `GET /api/customers/search/customerdata?search={phone}`
- **Description**: Allows user to see all their past orders by entering their phone number.

---

## 5. Online Specialist Doctor Consultation (Telemedicine)

Complete telemedicine workflow modeled after digital healthcare apps (browsing departments, checking doctor schedules, booking slots, and joining video calls).

### 5.1 Specialist Departments
- **Endpoint**: `GET /api/specialist-departments`
- **Description**: Returns departments such as General Medicine, Cardiology, Gynecology, Pediatrics, Dermatology, Orthopedics, etc.

### 5.2 Specialist Doctors List & Filters
- **Endpoint**: `GET /api/specialist-doctors`
- **Query Parameters**:
  - `department_id`: Filter by department ID
  - `available_now`: `1` (instant consultation) or `0`
  - `featured`: `1` for top-rated specialists
  - `search`: Search by doctor name, degree, or hospital
  - `sort`: `rating` (default), `fee_low`, `fee_high`, `experience`
  - `page`: Page index
  - `per_page`: Count (e.g. `12`)
- **Response**:
```json
{
  "status": true,
  "doctors": {
    "data": [
      {
        "id": 5,
        "name": "Dr. Farzana Ahmed",
        "degrees": "MBBS, FCPS (Medicine)",
        "speciality_title": "Medicine Specialist",
        "workplace": "Dhaka Medical College Hospital",
        "experience_years": 8,
        "consultation_fee": 500,
        "discounted_fee": 400,
        "rating": "4.9",
        "total_reviews": 120,
        "is_available_now": true,
        "avatar": "doctors/farzana.jpg",
        "department": {
          "id": 2,
          "name": "Internal Medicine",
          "bn_name": "মেডিসিন"
        }
      }
    ]
  }
}
```

### 5.3 Doctor Profile & 7-Day Schedule
- **Endpoint**: `GET /api/specialist-doctors/{id}`
- **Response**: Full profile, BMDC registration number, biography, and `upcoming_schedule` for the next 7 days.

### 5.4 Available Time Slots for Specific Date
- **Endpoint**: `GET /api/specialist-doctors/{id}/slots?date=YYYY-MM-DD`
- **Response**:
```json
{
  "status": true,
  "doctor_id": 5,
  "date": "2026-10-28",
  "day_name": "Wednesday",
  "slots": [
    { "time": "06:00 PM - 06:20 PM", "is_available": true },
    { "time": "06:20 PM - 06:40 PM", "is_available": false },
    { "time": "06:40 PM - 07:00 PM", "is_available": true }
  ]
}
```

### 5.5 Book Doctor Appointment
- **Endpoint**: `POST /api/consultation-bookings`
- **Content-Type**: `multipart/form-data`
- **Payload Fields**:
  - `doctor_id`: (Required, int)
  - `patient_name`: (Required, string)
  - `patient_phone`: (Required, string - 11 digit BD format)
  - `patient_age`: (Optional, int)
  - `patient_gender`: `male` | `female` | `other`
  - `appointment_date`: (Required, format `YYYY-MM-DD`)
  - `appointment_time_slot`: (Required, string, e.g. `"06:00 PM - 06:20 PM"`)
  - `consultation_type`: `video` | `audio` | `in_person` (Default: `video`)
  - `patient_problem`: (Optional, description of medical issues)
  - `prescription_file`: (Optional, image/pdf file of previous prescriptions)
  - `payment_method`: `cash` | `bkash` | `nagad`
  - `transaction_id`: (Optional, for pre-paid mobile money)
- **Response**:
```json
{
  "status": true,
  "message": "আপনার ডাক্তারের অ্যাপয়েন্টমেন্ট সফলভাবে বুক করা হয়েছে!",
  "booking": {
    "id": 14,
    "booking_id": "DOC-20261028-XY78Z",
    "fee": 400,
    "meeting_link": "https://meet.jit.si/medivila-doc-20261028-xy78z",
    "status": "pending",
    "payment_status": "pending"
  }
}
```

### 5.6 Real-Time Consultation Tracking
- **Endpoint**: `GET /api/consultation-bookings/track/{booking_id}`
- **Description**: Track consultation status, doctor attendance, and open the video consultation room (`meeting_link`).

---

## 6. Diagnostic Lab Tests & Home Sample Collection

### 6.1 Lab Categories
- **Endpoint**: `GET /api/lab-categories`
- **Description**: Diagnostic categories (e.g. Blood, Lipid Profile, Thyroid, Diabetes, Liver Function).

### 6.2 Lab Tests Catalog & Health Packages
- **Endpoint**: `GET /api/lab-tests`
- **Description**: Returns all tests, test preparation notes, sample types (Blood, Urine), fasting requirements, report turnaround time, and partnered labs (Popular Diagnostic, Ibn Sina, etc.).
- **Response**:
```json
[
  {
    "id": 1,
    "name": "Complete Blood Count (CBC) with ESR",
    "slug": "cbc-with-esr",
    "sample_type": "Blood",
    "fasting_required": false,
    "report_time": "12-24 Hours",
    "original_price": 500,
    "discounted_price": 400,
    "discount": "20% OFF",
    "rating": 4.8,
    "is_home_collection": true,
    "labs": [
      {
        "id": 1,
        "name": "Popular Diagnostic Center",
        "original_price": 500,
        "discounted_price": 400,
        "is_recommended": true
      }
    ]
  }
]
```

### 6.3 Book Home Sample Collection
- **Endpoint**: `POST /api/home-lab-bookings`
- **Content-Type**: `multipart/form-data` (or JSON if no prescription file)
- **Payload**:
```json
{
  "patient_name": "Kamal Hossain",
  "patient_phone": "01799887766",
  "patient_age": 45,
  "patient_gender": "male",
  "patient_address": "House 5, Road 2, Sector 3, Uttara, Dhaka",
  "city_or_area": "Uttara",
  "collection_date": "2026-10-29",
  "time_slot": "Morning (8 AM - 11 AM)",
  "lab_id": 1,
  "lab_name": "Popular Diagnostic Center",
  "collection_fee": 100,
  "special_notes": "Patient is elderly, please ring the front bell.",
  "items": [
    {
      "id": 1,
      "name": "Complete Blood Count (CBC)",
      "price": 500,
      "discounted_price": 400
    }
  ]
}
```
- **Response**:
```json
{
  "status": true,
  "message": "হোম ল্যাব টেস্টের স্যাম্পল কালেকশন বুকিং সফলভাবে গ্রহণ করা হয়েছে!",
  "booking": {
    "booking_id": "LAB-20261029-KP991",
    "subtotal": 400,
    "collection_fee": 100,
    "total": 500,
    "status": "pending"
  }
}
```

### 6.4 Track Lab Test Sample Collection
- **Endpoint**: `GET /api/home-lab-bookings/track/{booking_id}`

---

## 7. Easy Prescription Upload (Order by Doctor's Slip)

Users can take a photo of their prescription with the phone camera and upload it directly. Medivila registered pharmacists review it, prepare the cart, and call the user for confirmation.

### 7.1 Upload Prescription
- **Endpoint**: `POST /api/prescriptions`
- **Content-Type**: `multipart/form-data`
- **Fields**:
  - `name`: (Required, string)
  - `phone`: (Required, string - 11 digit BD phone)
  - `notes`: (Optional, text instructions, e.g. "১ মাসের ওষুধ দিন")
  - `file`: (Required, image file `jpg, jpeg, png, pdf` up to 5MB)
- **Response**:
```json
{
  "message": "Prescription uploaded successfully",
  "data": {
    "id": 25,
    "name": "Akash Saha",
    "phone": "01711223344",
    "notes": "1 month supply",
    "file": "prescriptions/prescription_xyz.jpg"
  },
  "file_url": "https://api.medivila.com/storage/prescriptions/prescription_xyz.jpg"
}
```

---

## 8. B2B Wholesale & Pharmacy Supply Module

For pharmacies, clinics, and wholesale buyers looking for bulk medicine supply.

### 8.1 Wholesale Products Catalog
- **Endpoint**: `GET /api/wholesale/products`
- **Query Parameters**: `search`, `category_id`, `page`, `per_page`
- **Response**:
```json
{
  "data": [
    {
      "id": 101,
      "name": "Napa Extra 500mg Tablet",
      "mrp": 30.00,
      "calculated_wholesale_price": 24.60,
      "wholesale_min_qty": 10,
      "wholesale_margin_pct": 18
    }
  ]
}
```

### 8.2 Submit Wholesale Application
- **Endpoint**: `POST /api/wholesale-applications`
- **Content-Type**: `multipart/form-data`
- **Fields**:
  - `business_name`: (Required) Pharmacy / Hospital name
  - `owner_name`: (Required) Owner name
  - `phone`: (Required) Contact number
  - `address`: (Required) Pharmacy address
  - `trade_license`: (Optional, license number)
  - `trade_license_file`: (Optional, image/pdf)
  - `drug_license`: (Optional, DGDA drug license number)
  - `drug_license_file`: (Optional, image/pdf)
  - `estimated_monthly_order`: (Optional, e.g. "50,000 - 100,000 BDT")
- **Response**:
```json
{
  "status": true,
  "message": "পাইকারি (হোলসেল) অ্যাকাউন্ট আবেদন সফলভাবে গৃহীত হয়েছে।",
  "application_code": "WHS-20261028-W981Z"
}
```

### 8.3 Track Wholesale Application Status
- **Endpoint**: `GET /api/wholesale/track/{query}` (Query can be `application_code` or `phone`)

---

## 9. User Authentication & Medivila Loyalty Coin Wallet

Medivila offers a phone-first authentication system and a loyalty points/coins wallet where users earn points on purchases and registrations.
The documented mobile authentication contract supports phone login and profile retrieval; it does not define a customer-registration endpoint. The app must not submit an assumed registration payload or report registration success unless the backend publishes and enables that API.

### 9.1 Phone Number Fast Login
- **Endpoint**: `POST /api/userlogin`
- **Request Body**:
```json
{
  "phone": "01712345678"
}
```
- **Response**:
```json
{
  "user": {
    "id": 12,
    "name": "Rakib Hasan",
    "phone": "01712345678",
    "points": 150,
    "type": "user"
  },
  "token": "12|AbCdEf123456789TokenStringHere"
}
```

### 9.2 Get Authenticated User Profile
- **Endpoint**: `GET /api/user`
- **Headers**: `Authorization: Bearer <token>`

### 9.3 Check User Points Balance
- **Endpoint**: `GET /api/users/{phone}`
- **Response**: `{ "id": 12, "name": "Rakib", "phone": "01712345678", "points": 150 }`

### 9.4 Coin Bonus Settings & Packages
- **Endpoint**: `GET /api/bonuscoins` -> Registration bonus and coin value.
- **Endpoint**: `GET /api/coinpackages` -> Top-up coin packages.

### 9.5 Top-Up Coins Request
- **Endpoint**: `POST /api/cointransactions`
- **Body**:
```json
{
  "name": "Rakib Hasan",
  "phone": "01712345678",
  "wallet_number": "01712345678",
  "coin_package_id": 1
}
```

---

## 10. Delivery Charges & Payment Gateways

### 10.1 Delivery Charges List
- **Endpoint**: `GET /api/deliverycharges`
- Returns districts in Bangladesh with delivery fees and delivery duration.

### 10.2 Payment Methods
- **Endpoint**: `GET /api/paymentmethod`
- Returns active payment gateways (`bKash`, `Nagad`, `Rocket`, `Cash on Delivery`) along with payment numbers and logos.

### 10.3 COD Advance Policy
- **Endpoint**: `GET /api/codadvances`
- Returns whether any advance payment (e.g. delivery fee 100 BDT) is required before confirming Cash On Delivery orders.

---

## 11. Customer Support & Quick Callbacks

### 11.1 Quick Lead (Callback Request)
- **Endpoint**: `POST /api/leads`
- **Body**:
```json
{
  "customer_name": "Sumon",
  "phone_number": "01812345678",
  "product_name": "Inquiry about insulin",
  "page_url": "mobile_app_home"
}
```

### 11.2 Contact Inquiry Message
- **Endpoint**: `POST /api/contacts`
- **Body**:
```json
{
  "name": "Naimur",
  "email": "naimur@gmail.com",
  "phone": "01912345678",
  "subject": "Medicine availability inquiry",
  "message": "Is human insulin available in your Dhanmondi hub?",
  "status": 1
}
```

---

## 12. Recommended Mobile App Architecture & State Management

### 12.1 Recommended Tech Stack
- **Flutter** (Dart 3.x) or **React Native** (Expo / Bare).
- **HTTP Client**: `Dio` (Flutter) or `Axios` (React Native) with interceptors for automatic Bearer token injection, connection timeout (10s), and retry on transient 503/429 errors.
- **State Management**:
  - Flutter: `Bloc` / `Cubit` or `Riverpod`.
  - React Native: `Zustand` or `Redux Toolkit` + `TanStack React Query`.
- **Local Storage**: `Hive` or `shared_preferences` for caching bootstrap data, cart items, and auth tokens.

### 12.2 Standard Dio HTTP Client Setup (Flutter Example)
```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://data.medivila.com/data',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle global 401 unauthorized or server timeouts
          return handler.next(error);
        },
      ),
    );
}
```

---

## 13. Mobile App Screen-to-Endpoint Mapping Cheat Sheet

| Mobile App Screen | API Endpoint to Call | Method | Purpose |
| :--- | :--- | :--- | :--- |
| **Splash Screen** | `/api/bootstrap` | `GET` | Categories, District delivery fees, Banners, Logo |
| **Home Screen** | `/api/products?view=listing` | `GET` | Featured medicine cards |
| **Home Screen** | `/api/offers` | `GET` | Promo sliders & discounts |
| **Search Screen** | `/api/products?search={term}` | `GET` | Live debounce search |
| **Category Screen** | `/api/products?category_id={id}` | `GET` | Filter products by category |
| **Product Detail** | `/api/products/{slug}` | `GET` | Variations, description, images |
| **Product Detail** | `/api/products/{slug}/related`| `GET` | Related products carousel |
| **Cart & Checkout** | `/api/deliverycharges` | `GET` | Dynamic delivery charge per district |
| **Cart & Checkout** | `/api/paymentmethod` | `GET` | bKash, Nagad, Rocket numbers |
| **Place Order** | `/api/cartstore` | `POST` | Submit cart order |
| **Upload Prescription** | `/api/prescriptions` | `POST` | Upload prescription photo |
| **Doctor Home** | `/api/specialist-departments`| `GET` | Browse medical departments |
| **Doctor List** | `/api/specialist-doctors` | `GET` | Doctors directory with filters |
| **Doctor Profile** | `/api/specialist-doctors/{id}`| `GET` | Doctor bio, 7-day schedule |
| **Doctor Booking** | `/api/specialist-doctors/{id}/slots` | `GET` | Time slots for selected date |
| **Book Appointment** | `/api/consultation-bookings` | `POST` | Book slot & generate video link |
| **Appointment Status**| `/api/consultation-bookings/track/{id}` | `GET` | View appointment & open meeting |
| **Lab Tests Home** | `/api/lab-tests` | `GET` | All diagnostic tests & packages |
| **Book Lab Sample** | `/api/home-lab-bookings` | `POST` | Request home sample collection |
| **Track Lab Test** | `/api/home-lab-bookings/track/{id}` | `GET` | Sample collection tracking |
| **Wholesale Catalog** | `/api/wholesale/products` | `GET` | B2B bulk medicine catalog |
| **Wholesale Form** | `/api/wholesale-applications` | `POST` | Trade/Drug license verification |
| **Order Tracking** | `/api/customers/{order_id}` | `GET` | Track delivery status & courier |
| **User Login** | `/api/userlogin` | `POST` | 1-click mobile phone login |
| **User Profile** | `/api/user` | `GET` | Get logged-in user details |
| **Coin Wallet** | `/api/users/{phone}` | `GET` | View coin points balance |
