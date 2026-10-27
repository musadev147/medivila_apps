import '../helpers/format_utils.dart';

class Product {
  Product(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get title => str(raw['title']);
  String get slug => str(raw['slug']);
  String get sku => str(raw['sku']);
  String get categoryName => str(raw['category_name']);
  String get brandName => str(raw['brand_name']);
  String get unit => str(raw['unit']);
  double get regularPrice => toDouble(raw['regular_price']);
  double? get salePrice => toDoubleOrNull(raw['sale_price']);
  double get effectivePrice =>
      toDoubleOrNull(raw['effective_price']) ?? toDoubleOrNull(raw['price']) ?? regularPrice;
  double? get flashPrice => toDoubleOrNull(raw['flash_price']);
  bool get isFlash => flashPrice != null;
  double get rating => toDouble(raw['average_rating']);
  int get reviewCount => toInt(raw['review_count']);
  int get stock => toInt(raw['stock_quantity']);
  bool get inStock => raw['is_in_stock'] ?? stock > 0;
  bool get lowStock => raw['is_low_stock'] == true;
  String? get thumbnail => mediaUrl(raw['thumbnail']);
  bool get featured => raw['is_featured'] == true;
  String get vendorName => str(raw['vendor_name']);
  String get vendorSlug => str(raw['vendor_slug']);
  int? get unitsSold => raw['units_sold'] == null ? null : toInt(raw['units_sold']);
  int get discount => discountPercent(effectivePrice, regularPrice);

  // seller-facing
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get rejectionReason => str(raw['rejection_reason']);
  int get lowStockThreshold => toInt(raw['low_stock_threshold']);
  String? get categoryId => raw['category']?.toString();
  String? get brandId => raw['brand']?.toString();
  int get viewsCount => toInt(raw['views_count']);

  // detail-only
  String get shortDescription => str(raw['short_description']);
  String get rawDescription => str(raw['description']);
  String get description => stripHtml(str(raw['description']));
  List<ProductImage> get images {
    final list = (raw['images'] as List? ?? const [])
        .map((e) => ProductImage(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<Variant> get variants =>
      (raw['variants'] as List? ?? const []).map((e) => Variant(Map<String, dynamic>.from(e))).toList();

  /// Gallery: thumbnail first, then gallery images by order.
  List<String> get gallery {
    final urls = <String>[];
    if (thumbnail != null) urls.add(thumbnail!);
    for (final i in images) {
      final u = i.url;
      if (u != null && !urls.contains(u)) urls.add(u);
    }
    return urls;
  }

  // flash-sale only
  int get flashQuantity => toInt(raw['flash_quantity']);
  int get flashSold => toInt(raw['flash_sold']);
  int get flashRemaining => toInt(raw['flash_remaining']);
}

class ProductImage {
  ProductImage(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String? get url => mediaUrl(raw['image']);
  int get order => toInt(raw['order']);
}

class Variant {
  Variant(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get attribute => str(raw['attribute_name']).isEmpty ? 'Option' : str(raw['attribute_name']);
  String get value => str(raw['attribute_value']);
  double? get priceOverride => toDoubleOrNull(raw['price_override']);
  int get stock => toInt(raw['stock_quantity']);
  String get label => '$attribute: $value';
}

class Category {
  Category(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get name => str(raw['name']);
  String get slug => str(raw['slug']);
  String? get parent => raw['parent']?.toString();
  String? get image => mediaUrl(raw['image']);
  String get icon => str(raw['icon']);
  String get description => str(raw['description']);
  int get productCount => toInt(raw['product_count']);
  int get subCount => toInt(raw['subcategories_count']);
}

class Brand {
  Brand(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get name => str(raw['name']);
  String get slug => str(raw['slug']);
  String? get logo => mediaUrl(raw['logo']);
  int get productCount => toInt(raw['product_count']);
}

class BannerItem {
  BannerItem(this.raw);
  final Map<String, dynamic> raw;
  String get title => str(raw['title']);
  String get subtitle => str(raw['subtitle']);
  String? get image => mediaUrl(raw['mobile_image']) ?? mediaUrl(raw['image']);
  String get buttonText => str(raw['button_text']);
  String get link => str(raw['link']);
  bool get overlay => raw['overlay'] == true;
  String get textColor => str(raw['text_color']);
}

class FlashSale {
  FlashSale(this.raw);
  final Map<String, dynamic> raw;
  String get title => str(raw['title']);
  String get description => str(raw['description']);
  DateTime? get startsAt => toDate(raw['starts_at']);
  DateTime? get endsAt => toDate(raw['ends_at']);
  String get phase => str(raw['phase']);
  bool get isLive => phase == 'live';
  DateTime? get countdownTo => isLive ? endsAt : startsAt;
  List<Product> get products =>
      (raw['products'] as List? ?? const []).map((e) => Product(Map<String, dynamic>.from(e))).toList();
}

class Review {
  Review(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get name => str(raw['customer_name'] ?? raw['customer']);
  int get rating => toInt(raw['rating']);
  String get comment => str(raw['comment']);
  bool get verified => raw['is_verified_purchase'] == true;
  DateTime? get createdAt => toDate(raw['created_at']);
}

class ReviewSummary {
  ReviewSummary(this.raw);
  final Map<String, dynamic> raw;
  double get average => toDouble(raw['average_rating']);
  int get count => toInt(raw['review_count']);
  Map<int, int> get distribution {
    final d = Map<String, dynamic>.from(raw['distribution'] ?? const {});
    return {for (var i = 5; i >= 1; i--) i: toInt(d['$i'])};
  }

  Review? get userReview =>
      raw['user_review'] == null ? null : Review(Map<String, dynamic>.from(raw['user_review']));
  List<Review> get reviews =>
      (raw['reviews'] as List? ?? const []).map((e) => Review(Map<String, dynamic>.from(e))).toList();
}

class VendorStore {
  VendorStore(this.raw);
  final Map<String, dynamic> raw;
  String get name => str(raw['store_name']);
  String get slug => str(raw['store_slug']);
  String get description => str(raw['description']);
  String? get logo => mediaUrl(raw['logo']);
  String? get banner => mediaUrl(raw['banner']);
  String get phone => str(raw['business_phone']);
  String get email => str(raw['business_email']);
  String get shippingPolicy => str(raw['shipping_policy']);
  String get returnPolicy => str(raw['return_policy']);
  int get productCount => toInt(raw['product_count']);
  Map<String, dynamic> get _rating => Map<String, dynamic>.from(raw['rating'] ?? const {});
  double get ratingAverage => toDouble(_rating['average']);
  int get ratingCount => toInt(_rating['count']);
  Map<int, int> get stars {
    final d = Map<String, dynamic>.from(_rating['stars'] ?? const {});
    return {for (var i = 5; i >= 1; i--) i: toInt(d['$i'])};
  }

  List<Review> get recentReviews =>
      (raw['recent_reviews'] as List? ?? const []).map((e) => Review(Map<String, dynamic>.from(e))).toList();
}
