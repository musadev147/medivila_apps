import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';
import '../models/account.dart';
import '../models/catalog.dart';
import '../models/common.dart';
import '../models/order.dart';
import '../models/wholesale.dart';

Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);
List<Map<String, dynamic>> _list(dynamic d) => (d as List? ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

Map<String, dynamic> _clean(Map<String, dynamic> q) => {
  for (final e in q.entries)
    if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value,
};

// ─────────────────────────────────────────────────────────────── App config
class ConfigApi {
  static Future<AppSettings> fetch({
    required String platform,
    required String version,
  }) async {
    final r = await api.get(
      '/app/config/',
      queryParameters: {'platform': platform, 'version': version},
    );
    return AppSettings(_map(r.data));
  }
}

// ─────────────────────────────────────────────────────────────── Catalogue
class CatalogApi {
  static Future<List<BannerItem>> banners() async =>
      _list((await api.get('/storefront/banners/')).data)
          .map(BannerItem.new)
          .toList();

  static Future<FlashSale?> flashSale() async {
    final r = await api.get('/promotions/flash-sales/current/');
    if (r.data is! Map || (r.data as Map).isEmpty || r.data['id'] == null)
      return null;
    final f = FlashSale(_map(r.data));
    return f.products.isEmpty ? null : f;
  }

  static Future<List<Category>> categories({bool onlyParents = false}) async {
    final r = await api.get(
      '/products/categories/',
      queryParameters: {if (onlyParents) 'only_parents': true},
    );
    final data = r.data is Map ? r.data['results'] : r.data;
    return _list(data)
        .map(Category.new)
        .where((c) => c.raw['is_active'] != false)
        .toList();
  }

  static Future<List<Brand>> brands() async {
    final r = await api.get('/products/brands/');
    final data = r.data is Map ? r.data['results'] : r.data;
    return _list(data)
        .map(Brand.new)
        .where((b) => b.raw['is_active'] != false)
        .toList();
  }

  static Future<Paged<Product>> products({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
    String? brand,
    String? vendor,
    bool? featured,
    String? ordering,
  }) async {
    final r = await api.get(
      '/products/',
      queryParameters: _clean({
        'page': page,
        'page_size': pageSize,
        'search': search,
        'category': category,
        'brand': brand,
        'vendor': vendor,
        'is_featured': featured == true ? 'true' : null,
        'ordering': ordering,
      }),
    );
    return Paged.fromJson(r.data, Product.new);
  }

  static Future<Map<String, dynamic>> suggest(String q) async => _map(
    (await api.get(
      '/products/search-suggest/',
      queryParameters: {'q': q},
    )).data,
  );

  static Future<Product> bySlug(String slug) async =>
      Product(_map((await api.get('/products/slug/$slug/')).data));

  static Future<Product> byId(String id) async =>
      Product(_map((await api.get('/products/$id/')).data));

  static Future<ReviewSummary> reviews(String productId) async => ReviewSummary(
    _map((await api.get('/products/$productId/reviews/')).data),
  );

  static Future<void> submitReview(
    String productId,
    int rating,
    String comment,
  ) => api.post(
    '/products/$productId/reviews/',
    data: {'rating': rating, 'comment': comment},
  );

  static Future<VendorStore> store(String slug) async =>
      VendorStore(_map((await api.get('/auth/vendors/store/$slug/')).data));
}

// ─────────────────────────────────────────────────────────────── Customer
class CustomerApi {
  static Future<List<Address>> addresses() async {
    final r = await api.get('/customers/addresses/');
    final data = r.data is Map ? r.data['results'] : r.data;
    return _list(data).map(Address.new).toList();
  }

  static Future<Address> createAddress(Map<String, dynamic> body) async =>
      Address(_map((await api.post('/customers/addresses/', data: body)).data));

  static Future<Address> updateAddress(
    String id,
    Map<String, dynamic> body,
  ) async => Address(
    _map((await api.patch('/customers/addresses/$id/', data: body)).data),
  );

  static Future<void> deleteAddress(String id) =>
      api.delete('/customers/addresses/$id/');

  static Future<void> makeDefault(String id) =>
      api.post('/customers/addresses/$id/default/');

  static Future<Set<String>> wishlistIds() async {
    final r = await api.get('/customers/wishlist/ids/');
    return ((r.data['product_ids'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
  }

  static Future<Paged<Product>> wishlist({int page = 1}) async {
    final r = await api.get(
      '/customers/wishlist/',
      queryParameters: {'page': page},
    );
    return Paged.fromJson(
      r.data,
      (m) => Product(Map<String, dynamic>.from(m['product'] ?? m)),
    );
  }

  static Future<void> addWishlist(String productId) =>
      api.post('/customers/wishlist/$productId/');
  static Future<void> removeWishlist(String productId) =>
      api.delete('/customers/wishlist/$productId/');
}

// ─────────────────────────────────────────────────────────────── Orders
class OrderApi {
  static Future<List<Map<String, dynamic>>> cartQuote(
    List<Map<String, dynamic>> items,
  ) async {
    final r = await api.post('/orders/cart-quote/', data: {'items': items});
    return _list(r.data['lines']);
  }

  static Future<Map<String, dynamic>> shippingQuote(String city) async => _map(
    (await api.get(
      '/orders/shipping-quote/',
      queryParameters: {'city': city},
    )).data,
  );

  static Future<Map<String, dynamic>> applyCoupon(
    String code,
    List<Map<String, dynamic>> items,
  ) async => _map(
    (await api.post(
      '/promotions/coupons/apply/',
      data: {'code': code.trim(), 'items': items},
    )).data,
  );

  static Future<Order> checkout(Map<String, dynamic> body) async =>
      Order(_map((await api.post('/orders/checkout/', data: body)).data));

  static Future<Paged<Order>> myOrders({int page = 1, String? status}) async {
    final r = await api.get(
      '/orders/my/',
      queryParameters: _clean({'page': page, 'status': status}),
    );
    return Paged.fromJson(r.data, Order.new);
  }

  static Future<Order> detail(String number) async =>
      Order(_map((await api.get('/orders/my/$number/')).data));

  static Future<void> cancel(String number, String reason) => api.post(
    '/orders/my/$number/cancel/',
    data: {if (reason.isNotEmpty) 'reason': reason},
  );

  static Future<void> rateSeller(
    String number,
    String packageId,
    int rating,
    String comment,
  ) => api.post(
    '/orders/my/$number/packages/$packageId/rate-seller/',
    data: {'rating': rating, 'comment': comment},
  );

  static Future<Map<String, dynamic>> summary({
    String? from,
    String? to,
  }) async => _map(
    (await api.get(
      '/orders/my-summary/',
      queryParameters: _clean({'from': from, 'to': to}),
    )).data,
  );

  // Returns
  static Future<ReturnRequest> createReturn({
    required String packageId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String description = '',
    List<String> photos = const [],
  }) async {
    final Object body;
    if (photos.isEmpty) {
      body = {
        'vendor_order': packageId,
        'items': items,
        'reason': reason,
        'description': description,
      };
    } else {
      body = FormData.fromMap({
        'vendor_order': packageId,
        'items': jsonEncode(items),
        'reason': reason,
        'description': description,
        'images': [
          for (final p in photos)
            await MultipartFile.fromFile(
              p,
              filename: p.split(RegExp(r'[\\/]')).last,
            ),
        ],
      });
    }
    return ReturnRequest(
      _map((await api.post('/orders/returns/', data: body)).data),
    );
  }

  static Future<Paged<ReturnRequest>> returns({
    int page = 1,
    String? status,
  }) async {
    final r = await api.get(
      '/orders/returns/',
      queryParameters: _clean({'page': page, 'status': status}),
    );
    return Paged.fromJson(r.data, ReturnRequest.new);
  }

  static Future<ReturnRequest> returnDetail(String id) async =>
      ReturnRequest(_map((await api.get('/orders/returns/$id/')).data));

  static Future<void> returnAction(String id, Map<String, dynamic> body) =>
      api.post('/orders/returns/$id/action/', data: body);
}

// ─────────────────────────────────────────────────────────────── Payments
class PaymentApi {
  static Future<Map<String, dynamic>> settings() async =>
      _map((await api.get('/payments/settings/')).data);

  static Future<Map<String, dynamic>> start(String orderNumber) async => _map(
    (await api.post(
      '/payments/orders/$orderNumber/start/',
      data: {'popup': false},
    )).data,
  );
}

// ─────────────────────────────────────────────────────────────── Notifications
class NotificationApi {
  static Future<Paged<AppNotification>> list({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final r = await api.get(
      '/notifications/',
      queryParameters: {'page': page, if (unreadOnly) 'unread': true},
    );
    return Paged.fromJson(r.data, AppNotification.new);
  }

  static Future<int> unreadCount() async =>
      (await api.get('/notifications/unread-count/')).data['unread_count'] ?? 0;

  static Future<int> markRead([List<String>? ids]) async {
    final r = await api.post(
      '/notifications/mark-read/',
      data: ids == null ? {} : {'ids': ids},
    );
    return r.data['unread_count'] ?? 0;
  }

  static Future<Map<String, dynamic>> preferences() async =>
      _map((await api.get('/notifications/preferences/')).data);

  static Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> body,
  ) async =>
      _map((await api.patch('/notifications/preferences/', data: body)).data);
}

// ─────────────────────────────────────────────────────────────── Wholesale
class WholesaleApi {
  static Future<WholesaleAccount?> account() async {
    final r = await api.get('/wholesale/my/');
    final a = r.data is Map ? r.data['account'] : null;
    return a == null ? null : WholesaleAccount(_map(a));
  }

  static Future<void> apply(
    Map<String, dynamic> body, {
    bool resubmit = false,
  }) => resubmit
      ? api.patch('/wholesale/my/', data: body)
      : api.post('/wholesale/my/', data: body);

  static Future<List<WholesaleProduct>> catalogue() async {
    final r = await api.get('/wholesale/my/catalogue/');
    final data = r.data is Map ? r.data['results'] : r.data;
    return _list(data).map(WholesaleProduct.new).toList();
  }

  static Future<WholesaleOrder> placeOrder(Map<String, dynamic> body) async =>
      WholesaleOrder(
        _map((await api.post('/wholesale/my/orders/', data: body)).data),
      );

  static Future<List<WholesaleOrder>> orders() async {
    final r = await api.get('/wholesale/my/orders/');
    final data = r.data is Map ? r.data['results'] : r.data;
    return _list(data).map(WholesaleOrder.new).toList();
  }

  static Future<void> cancel(String number, String reason) => api.post(
    '/wholesale/my/orders/$number/cancel/',
    data: {'reason': reason},
  );

  static Future<Map<String, dynamic>> pay({
    String? order,
    String? amount,
  }) async => _map(
    (await api.post(
      '/wholesale/my/pay/',
      data: {'order': ?order, 'amount': ?amount, 'popup': false},
    )).data,
  );

  static Future<Map<String, dynamic>> statement() async =>
      _map((await api.get('/wholesale/my/statement/')).data);
}
