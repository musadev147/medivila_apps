import '../constants/app_config.dart';

// ───────────────────────────────────────────────────────────── 1. Bootstrap
class BootstrapResponse {
  final bool success;
  final BootstrapData? data;

  BootstrapResponse({required this.success, this.data});

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) {
    return BootstrapResponse(
      success: json['success'] == true || json['status'] == true,
      data: json['data'] != null
          ? BootstrapData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class BootstrapData {
  final String? logo;
  final String? brandSlogan;
  final List<CategoryItem> categories;
  final List<BannerItem> banners;
  final List<DistrictDelivery> districts;
  final ContactInfo? contactInfo;
  final CoinBonusSettings? bonus;
  final List<CoinPackage> coinPackages;

  BootstrapData({
    this.logo,
    this.brandSlogan,
    this.categories = const [],
    this.banners = const [],
    this.districts = const [],
    this.contactInfo,
    this.bonus,
    this.coinPackages = const [],
  });

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      logo: json['logo']?.toString(),
      brandSlogan: json['brand_slogan']?.toString() ?? AppConfig.appSlogan,
      categories: (json['categories'] as List? ?? [])
          .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      banners: (json['banners'] as List? ?? [])
          .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      districts: (json['districts'] as List? ?? [])
          .map((e) => DistrictDelivery.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      contactInfo: json['contactInfo'] != null
          ? ContactInfo.fromJson(Map<String, dynamic>.from(json['contactInfo']))
          : null,
      bonus: json['bonus'] != null
          ? CoinBonusSettings.fromJson(Map<String, dynamic>.from(json['bonus']))
          : null,
      coinPackages: (json['coinPackages'] as List? ?? [])
          .map((e) => CoinPackage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CategoryItem {
  final int id;
  final String name;
  final String? bnName;
  final String slug;
  final String? image;
  final List<CategoryItem> children;

  CategoryItem({
    required this.id,
    required this.name,
    this.bnName,
    required this.slug,
    this.image,
    this.children = const [],
  });

  String get displayName =>
      (bnName != null && bnName!.isNotEmpty) ? bnName! : name;
  String get imageUrl => AppConfig.resolveImageUrl(image);

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      bnName: json['bn_name']?.toString(),
      slug: json['slug']?.toString() ?? '',
      image: json['image']?.toString(),
      children: (json['children'] as List? ?? [])
          .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BannerItem {
  final int id;
  final String title;
  final String image;
  final String? link;

  BannerItem({
    required this.id,
    required this.title,
    required this.image,
    this.link,
  });

  String get imageUrl => AppConfig.resolveImageUrl(image);

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      link: json['link']?.toString(),
    );
  }
}

class DistrictDelivery {
  final int id;
  final String districtName;
  final double deliveryCharge;
  final String estimatedDays;
  final String? deliveryNote;

  DistrictDelivery({
    required this.id,
    required this.districtName,
    required this.deliveryCharge,
    required this.estimatedDays,
    this.deliveryNote,
  });

  factory DistrictDelivery.fromJson(Map<String, dynamic> json) {
    return DistrictDelivery(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      districtName: json['district_name']?.toString() ?? '',
      deliveryCharge:
          double.tryParse(json['delivery_charge']?.toString() ?? '60') ?? 60.0,
      estimatedDays: json['estimated_days']?.toString() ?? '1-2 Days',
      deliveryNote: json['delivery_note']?.toString(),
    );
  }
}

class ContactInfo {
  final String phone;
  final String email;
  final String address;

  ContactInfo({
    required this.phone,
    required this.email,
    required this.address,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone']?.toString() ?? AppConfig.helplinePhone,
      email: json['email']?.toString() ?? AppConfig.supportEmail,
      address: json['address']?.toString() ?? 'Dhaka, Bangladesh',
    );
  }
}

class CoinBonusSettings {
  final double firstRegBonus;
  final double bonusPercentage;
  final String coinName;

  CoinBonusSettings({
    required this.firstRegBonus,
    required this.bonusPercentage,
    required this.coinName,
  });

  factory CoinBonusSettings.fromJson(Map<String, dynamic> json) {
    return CoinBonusSettings(
      firstRegBonus:
          double.tryParse(json['first_reg_bonus']?.toString() ?? '50') ?? 50.0,
      bonusPercentage:
          double.tryParse(json['bonus_percentage']?.toString() ?? '5') ?? 5.0,
      coinName: json['coin_name']?.toString() ?? 'Medivila Coin',
    );
  }
}

class CoinPackage {
  final int id;
  final String packageName;
  final int coins;
  final double price;

  CoinPackage({
    required this.id,
    required this.packageName,
    required this.coins,
    required this.price,
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      packageName: json['package_name']?.toString() ?? '',
      coins: int.tryParse(json['coins']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

// ───────────────────────────────────────────────────────────── 2. Product / Medicine
class MedicineProduct {
  final int id;
  final String slug;
  final String name;
  final double price;
  final double? discountPrice;
  final int? categoryId;
  final String? categoryName;
  final String? genericName;
  final String? manufacturer;
  final String? dosageForm;
  final String? description;
  final List<String> images;
  final List<ProductSize> sizes;
  final List<BulkDiscount> bulkDiscounts;
  final bool requiresPrescription;

  MedicineProduct({
    required this.id,
    required this.slug,
    required this.name,
    required this.price,
    this.discountPrice,
    this.categoryId,
    this.categoryName,
    this.genericName,
    this.manufacturer,
    this.dosageForm,
    this.description,
    this.images = const [],
    this.sizes = const [],
    this.bulkDiscounts = const [],
    this.requiresPrescription = false,
  });

  double get effectivePrice =>
      (discountPrice != null && discountPrice! > 0) ? discountPrice! : price;

  bool get hasDiscount =>
      discountPrice != null && discountPrice! > 0 && discountPrice! < price;

  int get discountPercentage {
    if (!hasDiscount || price <= 0) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  String get primaryImageUrl =>
      images.isNotEmpty ? images.first : AppConfig.defaultImageFallback;

  factory MedicineProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List? ?? [];
    final imageList = <String>[];
    for (final item in rawImages) {
      if (item is Map && item['image'] != null) {
        imageList.add(AppConfig.resolveImageUrl(item['image'].toString()));
      } else if (item is String) {
        imageList.add(AppConfig.resolveImageUrl(item));
      }
    }
    if (json['thumbnail'] != null) {
      final thumb = AppConfig.resolveImageUrl(json['thumbnail'].toString());
      if (!imageList.contains(thumb)) imageList.insert(0, thumb);
    }

    final rawSizes = json['single_product_sizes'] as List? ?? [];
    final sizeList = rawSizes
        .map((e) => ProductSize.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawBulk = json['bulk_discounts'] as List? ?? [];
    final bulkList = rawBulk
        .map((e) => BulkDiscount.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return MedicineProduct(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      price:
          double.tryParse(
            json['price']?.toString() ??
                json['regular_price']?.toString() ??
                '0',
          ) ??
          0.0,
      discountPrice: double.tryParse(
        json['discount_price']?.toString() ??
            json['sale_price']?.toString() ??
            '',
      ),
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString(),
      genericName: json['generic_name']?.toString(),
      manufacturer:
          json['manufacturer']?.toString() ?? json['brand_name']?.toString(),
      dosageForm: json['dosage_form']?.toString() ?? json['unit']?.toString(),
      description:
          json['homepage']?.toString() ?? json['description']?.toString(),
      images: imageList,
      sizes: sizeList,
      bulkDiscounts: bulkList,
      requiresPrescription:
          json['requires_prescription'] == true ||
          (json['category_name']?.toString().toLowerCase().contains(
                'prescription',
              ) ??
              false),
    );
  }
}

class ProductSize {
  final int id;
  final String size;

  ProductSize({required this.id, required this.size});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      size: json['size']?.toString() ?? '',
    );
  }
}

class BulkDiscount {
  final int id;
  final String title;
  final int offerQuantity;
  final double discountPercentage;

  BulkDiscount({
    required this.id,
    required this.title,
    required this.offerQuantity,
    required this.discountPercentage,
  });

  factory BulkDiscount.fromJson(Map<String, dynamic> json) {
    return BulkDiscount(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      offerQuantity:
          int.tryParse(json['offer_quantity']?.toString() ?? '1') ?? 1,
      discountPercentage:
          double.tryParse(json['discount_percentage']?.toString() ?? '0') ??
          0.0,
    );
  }
}

// ───────────────────────────────────────────────────────────── 3. Doctors & Telemedicine
class DepartmentModel {
  final int id;
  final String name;
  final String? bnName;

  DepartmentModel({required this.id, required this.name, this.bnName});

  String get displayName =>
      (bnName != null && bnName!.isNotEmpty) ? bnName! : name;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      bnName: json['bn_name']?.toString(),
    );
  }
}

class DoctorModel {
  final int id;
  final String name;
  final String? title;
  final String degrees;
  final String specialityTitle;
  final String workplace;
  final int experienceYears;
  final double consultationFee;
  final double? discountedFee;
  final double rating;
  final int totalReviews;
  final bool isAvailableNow;
  final String? avatar;
  final DepartmentModel? department;
  final String? bmdcNumber;
  final String? bio;
  final String? availableTimeStart;
  final String? availableTimeEnd;

  DoctorModel({
    required this.id,
    required this.name,
    this.title,
    required this.degrees,
    required this.specialityTitle,
    required this.workplace,
    required this.experienceYears,
    required this.consultationFee,
    this.discountedFee,
    required this.rating,
    required this.totalReviews,
    required this.isAvailableNow,
    this.avatar,
    this.department,
    this.bmdcNumber,
    this.bio,
    this.availableTimeStart,
    this.availableTimeEnd,
  });

  double get effectiveFee => (discountedFee != null && discountedFee! > 0)
      ? discountedFee!
      : consultationFee;
  String get avatarUrl => AppConfig.resolveImageUrl(avatar);

  String get formattedName {
    final clean = name.trim();
    if (clean.startsWith('ডাঃ') || clean.toLowerCase().startsWith('dr.')) {
      return clean;
    }
    if (title != null && title!.trim().isNotEmpty) {
      return '${title!.trim()} $clean';
    }
    return 'ডাঃ $clean';
  }

  String get displaySpeciality {
    if (specialityTitle.trim().isNotEmpty) return specialityTitle.trim();
    if (department != null && department!.displayName.trim().isNotEmpty) {
      return department!.displayName.trim();
    }
    return '';
  }

  String get displayWorkplace => workplace.trim();

  String get displayExperience {
    if (experienceYears <= 0) return '';
    return '$experienceYears বছরের অভিজ্ঞতা';
  }

  String get displayAvailableTime {
    if (availableTimeStart != null &&
        availableTimeEnd != null &&
        availableTimeStart!.isNotEmpty) {
      return 'সময়: $availableTimeStart - $availableTimeEnd';
    }
    return '';
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      degrees: json['degrees']?.toString() ?? '',
      specialityTitle: json['speciality_title']?.toString() ?? '',
      workplace: json['workplace']?.toString() ?? '',
      experienceYears:
          int.tryParse(json['experience_years']?.toString() ?? '0') ?? 0,
      consultationFee:
          double.tryParse(json['consultation_fee']?.toString() ?? '0') ?? 0.0,
      discountedFee: double.tryParse(json['discounted_fee']?.toString() ?? ''),
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      isAvailableNow: json['is_available_now'] == true,
      avatar: json['avatar']?.toString() ?? json['avatar_url']?.toString(),
      department: json['department'] != null
          ? DepartmentModel.fromJson(
              Map<String, dynamic>.from(json['department']),
            )
          : null,
      bmdcNumber: json['bmdc_number']?.toString(),
      bio: json['bio']?.toString(),
      availableTimeStart: json['available_time_start']?.toString(),
      availableTimeEnd: json['available_time_end']?.toString(),
    );
  }
}

class TimeSlot {
  final String time;
  final bool isAvailable;

  TimeSlot({required this.time, required this.isAvailable});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time_slot']?.toString() ?? json['time']?.toString() ?? '',
      isAvailable: json['is_available'] == true,
    );
  }
}

// ───────────────────────────────────────────────────────────── 4. Lab Tests
class LabTestModel {
  final int id;
  final String name;
  final String slug;
  final String sampleType;
  final bool fastingRequired;
  final String reportTime;
  final double originalPrice;
  final double discountedPrice;
  final String? discount;
  final double rating;
  final bool isHomeCollection;
  final String? preparationNotes;
  final String? image;
  final String? description;

  LabTestModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.sampleType = '',
    this.fastingRequired = false,
    this.reportTime = '',
    required this.originalPrice,
    required this.discountedPrice,
    this.discount,
    this.rating = 0,
    this.isHomeCollection = false,
    this.preparationNotes,
    this.image,
    this.description,
  });

  String get imageUrl => image != null
      ? AppConfig.resolveImageUrl(image)
      : AppConfig.defaultImageFallback;

  factory LabTestModel.fromJson(Map<String, dynamic> json) {
    return LabTestModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sampleType: json['sample_type']?.toString() ?? '',
      fastingRequired: json['fasting_required'] == true,
      reportTime: json['report_time']?.toString() ?? '',
      originalPrice:
          double.tryParse(json['original_price']?.toString() ?? '0') ?? 0.0,
      discountedPrice:
          double.tryParse(json['discounted_price']?.toString() ?? '0') ?? 0.0,
      discount: json['discount']?.toString(),
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      isHomeCollection: json['is_home_collection'] == true,
      preparationNotes: json['preparation_notes']?.toString(),
      image: json['image']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

// ───────────────────────────────────────────────────────────── 5. Wholesale
class WholesaleProduct {
  final int id;
  final String name;
  final double mrp;
  final double calculatedWholesalePrice;
  final int minQty;
  final int marginPct;

  WholesaleProduct({
    required this.id,
    required this.name,
    required this.mrp,
    required this.calculatedWholesalePrice,
    required this.minQty,
    required this.marginPct,
  });

  factory WholesaleProduct.fromJson(Map<String, dynamic> json) {
    return WholesaleProduct(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0.0,
      calculatedWholesalePrice:
          double.tryParse(
            json['calculated_wholesale_price']?.toString() ?? '0',
          ) ??
          0.0,
      minQty: int.tryParse(json['wholesale_min_qty']?.toString() ?? '10') ?? 10,
      marginPct:
          int.tryParse(json['wholesale_margin_pct']?.toString() ?? '15') ?? 15,
    );
  }
}

// ───────────────────────────────────────────────────────────── 6. User Auth
class MedivilaUser {
  final int id;
  final String name;
  final String phone;
  final int points;
  final String type;
  final String? token;

  MedivilaUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.type,
    this.token,
  });

  factory MedivilaUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return MedivilaUser(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'user',
      token: token ?? json['token']?.toString(),
    );
  }
}
