import 'dart:developer';

import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../models/medivila_models.dart';
import 'dio/dio.dart';
import 'endpoints.dart';
import 'exception_handler/data_source.dart';

// ───────────────────────────────────────────────────────────── 1. Bootstrap API
class BootstrapApi {
  BootstrapApi._();
  static final BootstrapApi instance = BootstrapApi._();

  Future<BootstrapData> getBootstrap() async {
    final response = await getHttp(Endpoints.bootstrap());
    if (response.statusCode != 200 || response.data is! Map) {
      throw const FormatException('Invalid bootstrap API response');
    }
    final responseData = response.data as Map;
    final data = responseData['data'] ?? responseData;
    if (data is! Map) {
      throw const FormatException('Invalid bootstrap data');
    }
    return BootstrapData.fromJson(Map<String, dynamic>.from(data));
  }
}

// ───────────────────────────────────────────────────────────── Service Banners
class ServiceBannersApi {
  ServiceBannersApi._();
  static final ServiceBannersApi instance = ServiceBannersApi._();

  Future<List<ServiceBanner>> getServiceBanners() async {
    final response = await getHttp(Endpoints.serviceBanners());
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid service banners API response');
    }
    final data = response.data;
    final list = data is Map
        ? (data['data'] is List ? data['data'] as List : const [])
        : const [];
    return list
        .map((e) => ServiceBanner.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

// ───────────────────────────────────────────────────────────── 2. Products API
class ProductsApi {
  ProductsApi._();
  static final ProductsApi instance = ProductsApi._();

  Future<List<MedicineProduct>> getProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int? limit,
  }) async {
    try {
      final products = <MedicineProduct>[];
      var currentPage = page;
      int? lastPage;

      do {
        final q = <String, dynamic>{
          'page': currentPage,
          'per_page': limit ?? 100,
          'view': 'listing',
        };
        if (categoryId != null && categoryId > 0) q['category_id'] = categoryId;
        if (search != null && search.trim().isNotEmpty)
          q['search'] = search.trim();

        final response = await getHttp(
          Endpoints.products(),
          queryParameters: q,
        );
        if (response.statusCode != 200 || response.data == null) {
          throw const FormatException('Invalid products API response');
        }

        final responseData = response.data;
        final List<dynamic> list;
        if (responseData is Map) {
          final data = responseData['data'];
          list = data is List ? data : const [];
          lastPage = int.tryParse(responseData['last_page']?.toString() ?? '');
        } else if (responseData is List) {
          list = responseData;
        } else {
          list = const [];
        }

        products.addAll(
          list.map(
            (e) => MedicineProduct.fromJson(Map<String, dynamic>.from(e)),
          ),
        );

        if (limit != null && products.length >= limit) {
          return products.take(limit).toList();
        }
        if (lastPage == null || list.isEmpty) break;
        currentPage++;
      } while (currentPage <= lastPage);

      return products;
    } catch (e) {
      log("ProductsApi Error: $e");
      rethrow;
    }
  }

  Future<MedicineProduct> getProductDetail(String slug) async {
    try {
      final response = await getHttp(Endpoints.productDetails(slug));
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data is Map
            ? response.data['data'] ?? response.data
            : response.data;
        return MedicineProduct.fromJson(Map<String, dynamic>.from(d));
      }
      throw DataSource.NOT_FOUND.getFailure();
    } catch (e) {
      log("Product detail API Error: $e");
      rethrow;
    }
  }
}

// ───────────────────────────────────────────────────────────── 2. Categories API
class CategoriesApi {
  CategoriesApi._();
  static final CategoriesApi instance = CategoriesApi._();

  Future<List<CategoryItem>> getCategories() async {
    final response = await getHttp(Endpoints.categories());
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid categories API response');
    }

    final data = response.data;
    final List<dynamic> categories;
    if (data is List) {
      categories = data;
    } else if (data is Map) {
      final payload = data['categories'] ?? data['data'];
      if (payload is! List) {
        throw const FormatException('Invalid categories API response');
      }
      categories = payload;
    } else {
      throw const FormatException('Invalid categories API response');
    }

    return categories
        .map((item) => CategoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

// ───────────────────────────────────────────────────────────── 3. Specialist Doctors API
class DoctorsApi {
  DoctorsApi._();
  static final DoctorsApi instance = DoctorsApi._();

  Future<List<DoctorModel>> getDoctors({
    int? departmentId,
    String? search,
  }) async {
    final q = <String, dynamic>{};
    if (departmentId != null && departmentId > 0) {
      q['department_id'] = departmentId;
    }
    if (search != null && search.trim().isNotEmpty) {
      q['search'] = search.trim();
    }

    final response = await getHttp(
      Endpoints.specialistDoctors(),
      queryParameters: q,
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid doctors API response');
    }
    final doctorsData = response.data is Map
        ? response.data['doctors'] ?? response.data['data']
        : response.data;
    final list = doctorsData is Map
        ? doctorsData['data'] as List? ?? const []
        : (doctorsData is List ? doctorsData : const []);
    return list
        .map((e) => DoctorModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final response = await getHttp(Endpoints.specialistDepartments());
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid departments API response');
    }
    final data = response.data;
    final list = data is List
        ? data
        : data is Map
        ? data['departments'] as List? ?? data['data'] as List? ?? const []
        : const [];
    return list
        .map((e) => DepartmentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TimeSlot>> getDoctorSlots(int doctorId, String date) async {
    final response = await getHttp(
      Endpoints.doctorSlots(doctorId),
      queryParameters: {'date': date},
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid doctor slots API response');
    }
    final slots = response.data is Map
        ? response.data['slots'] as List? ?? const []
        : response.data as List? ?? const [];
    return slots
        .map((e) => TimeSlot.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> bookConsultation(FormData formData) async {
    final response = await postHttp(
      Endpoints.bookConsultation(),
      data: formData,
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.DEFAULT.getFailure();
  }
}

// ───────────────────────────────────────────────────────────── 4. Lab Tests API
class LabTestsApi {
  LabTestsApi._();
  static final LabTestsApi instance = LabTestsApi._();

  Future<List<LabTestModel>> getLabTests({String? search}) async {
    final q = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      q['search'] = search.trim();
    }
    final response = await getHttp(
      Endpoints.labTests(),
      queryParameters: q.isNotEmpty ? q : null,
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid lab tests API response');
    }
    final data = response.data;
    final list = data is List
        ? data
        : data is Map
        ? data['data'] as List? ?? const []
        : const [];
    final all = list
        .map((e) => LabTestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (search == null || search.trim().isEmpty) return all;

    final s = search.trim().toLowerCase();
    return all
        .where(
          (t) =>
              t.name.toLowerCase().contains(s) ||
              (t.description?.toLowerCase().contains(s) ?? false) ||
              t.sampleType.toLowerCase().contains(s),
        )
        .toList();
  }

  Future<Map<String, dynamic>> bookHomeLab(Map<String, dynamic> data) async {
    final response = await postHttp(Endpoints.bookHomeLab(), data: data);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.DEFAULT.getFailure();
  }
}

// ───────────────────────────────────────────────────────────── 5. Prescription Upload API
class PrescriptionApi {
  PrescriptionApi._();
  static final PrescriptionApi instance = PrescriptionApi._();

  Future<Map<String, dynamic>> uploadPrescription({
    required String name,
    required String phone,
    String? notes,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'name': name.trim(),
      'phone': phone.trim(),
      if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'prescription.jpg',
      ),
    });
    final response = await postHttp(
      Endpoints.uploadPrescription(),
      data: formData,
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.DEFAULT.getFailure();
  }
}

// ───────────────────────────────────────────────────────────── 6. Orders & Checkout API
class OrdersApi {
  OrdersApi._();
  static final OrdersApi instance = OrdersApi._();

  Future<Map<String, dynamic>> submitOrder(
    Map<String, dynamic> orderPayload,
  ) async {
    final response = await postHttp(Endpoints.cartStore(), data: orderPayload);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.DEFAULT.getFailure();
  }

  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    final response = await getHttp(Endpoints.orderTracking(orderId));
    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.NOT_FOUND.getFailure();
  }
}

// ───────────────────────────────────────────────────────────── 7. Wholesale API
class WholesaleApi {
  WholesaleApi._();
  static final WholesaleApi instance = WholesaleApi._();

  Future<List<WholesaleProduct>> getWholesaleProducts() async {
    final response = await getHttp(Endpoints.wholesaleProducts());
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid wholesale products API response');
    }
    final data = response.data;
    final list = data is List
        ? data
        : data is Map
        ? data['data'] as List? ?? const []
        : const [];
    return list
        .map((e) => WholesaleProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> submitApplication(
    Map<String, dynamic> data,
  ) async {
    final response = await postHttp(
      Endpoints.wholesaleApplications(),
      data: data,
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw DataSource.DEFAULT.getFailure();
  }
}

// ───────────────────────────────────────────────────────────── 8. User Auth & Wallet API
class UserAuthApi {
  UserAuthApi._();
  static final UserAuthApi instance = UserAuthApi._();

  Future<MedivilaUser> fastPhoneLogin(String phone) async {
    final response = await postHttp(
      Endpoints.userLogin(),
      data: {'phone': phone.trim()},
      options: Options(extra: {'noAuth': true}),
    );
    if (response.statusCode != 200 || response.data is! Map) {
      throw const FormatException('Invalid login API response');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final userData = data['user'];
    final token = data['token']?.toString();
    if (userData is! Map || token == null || token.isEmpty) {
      throw const FormatException('Login response is missing user or token');
    }
    return MedivilaUser.fromJson(
      Map<String, dynamic>.from(userData),
      token: token,
    );
  }

  Future<MedivilaUser> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final cleanPhone = AppConfig.cleanBdPhone(phone);
    final phoneInt = int.tryParse(cleanPhone) ?? 0;
    final payload = {
      'name': name.trim(),
      'phone': cleanPhone,
      'phone_number': phoneInt,
      'password': password,
      'password_confirmation': password,
      'type': 'user',
    };

    final response = await postHttp(
      Endpoints.register(),
      data: payload,
      options: Options(extra: {'noAuth': true}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw const FormatException('Registration failed');
    }

    return fastPhoneLogin(cleanPhone);
  }

  Future<MedivilaUser> currentUser() async {
    final response = await getHttp(Endpoints.userProfile());
    if (response.statusCode != 200 || response.data is! Map) {
      throw const FormatException('Invalid user profile API response');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final userData = data['user'] is Map ? data['user'] : data;
    return MedivilaUser.fromJson(Map<String, dynamic>.from(userData));
  }
}

// ------------------------------------------------------------- 10. Offers API
class OffersApi {
  OffersApi._();
  static final OffersApi instance = OffersApi._();

  Future<List<OfferItem>> getOffers() async {
    try {
      final response = await getHttp(Endpoints.offers());
      if (response.statusCode != 200 || response.data == null) {
        return const [];
      }
      final raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] : const []);
      final offers = list
          .map((e) => OfferItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      offers.sort((a, b) {
        if (a.sortOrder != b.sortOrder)
          return a.sortOrder.compareTo(b.sortOrder);
        return a.id.compareTo(b.id);
      });
      return offers;
    } catch (e) {
      log('OffersApi Error: $e');
      return const [];
    }
  }
}

// ------------------------------------------------------------- 11. Menus API
class MenusApi {
  MenusApi._();
  static final MenusApi instance = MenusApi._();

  Future<List<HomePageMenu>> getHomePageMenus() async {
    try {
      final response = await getHttp(Endpoints.menus());
      if (response.statusCode != 200 || response.data == null) {
        return const [];
      }
      final raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] : const []);
      final menus = list
          .map((e) => HomePageMenu.fromJson(Map<String, dynamic>.from(e)))
          .where(
            (m) =>
                m.menuType.toLowerCase() == 'home_page' && m.category != null,
          )
          .toList();
      menus.sort((a, b) => a.order.compareTo(b.order));
      return menus;
    } catch (e) {
      log('MenusApi Error: $e');
      return const [];
    }
  }
}
