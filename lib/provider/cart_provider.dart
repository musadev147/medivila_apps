import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/format_utils.dart';
import '../models/medivila_models.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.title,
    required this.thumbnail,
    required this.unitPrice,
    required this.vendorName,
    this.slug = '',
    this.variantLabel = '',
    this.regularPrice = 0,
    this.requiresPrescription = false,
  });

  final String product;
  final String? variant;
  int quantity;
  final String title;
  final String? thumbnail;
  double unitPrice;
  double regularPrice;
  final String vendorName;
  final String slug;
  final String variantLabel;
  final bool requiresPrescription;

  bool available = true;
  int? stock;
  String message = '';
  bool isFlash = false;

  String get key => '$product|${variant ?? ''}';
  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toApi() => {
        'type': 'product',
        'product_id': int.tryParse(product) ?? product,
        'product_name': title,
        'quantity': quantity,
        'price': unitPrice,
        'size': variantLabel.isNotEmpty ? variantLabel : null,
      };

  Map<String, dynamic> toJson() => {
        'product': product,
        'variant': variant,
        'quantity': quantity,
        'title': title,
        'thumbnail': thumbnail,
        'unit_price': unitPrice.toStringAsFixed(2),
        'regular_price': regularPrice.toStringAsFixed(2),
        'vendor_name': vendorName,
        'slug': slug,
        'variant_label': variantLabel,
        'requires_prescription': requiresPrescription,
      };

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        product: str(j['product']),
        variant: j['variant']?.toString(),
        quantity: toInt(j['quantity']).clamp(1, 999),
        title: str(j['title']),
        thumbnail: j['thumbnail'] as String?,
        unitPrice: toDouble(j['unit_price']),
        regularPrice: toDouble(j['regular_price']),
        vendorName: str(j['vendor_name']),
        slug: str(j['slug']),
        variantLabel: str(j['variant_label']),
        requiresPrescription: j['requires_prescription'] == true,
      );
}

class CartProvider extends ChangeNotifier {
  static const _key = 'medivila_cart_v1';
  final List<CartLine> lines = [];
  bool quoting = false;
  bool priceChanged = false;

  String _selectedDistrict = 'Dhaka';
  double _deliveryCharge = 60.0;

  String get selectedDistrict => _selectedDistrict;
  double get deliveryCharge => _deliveryCharge;

  void setDistrict(String name, double charge) {
    _selectedDistrict = name;
    _deliveryCharge = charge;
    notifyListeners();
  }

  int get count => lines.fold(0, (s, l) => s + l.quantity);
  double get subtotal => lines.fold(0, (s, l) => s + l.lineTotal);
  double get grandTotal => subtotal + _deliveryCharge;
  bool get hasProblems => lines.any((l) => !l.available);
  bool get isEmpty => lines.isEmpty;
  bool get requiresPrescription => lines.any((l) => l.requiresPrescription);

  List<Map<String, dynamic>> get apiItems => lines.map((l) => l.toApi()).toList();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      lines
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e) => CartLine.fromJson(Map<String, dynamic>.from(e))));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lines.map((l) => l.toJson()).toList()));
  }

  void addMedicine(MedicineProduct product, {int quantity = 1, ProductSize? size}) {
    final line = CartLine(
      product: product.id.toString(),
      variant: size?.id.toString(),
      quantity: quantity,
      title: product.name,
      thumbnail: product.primaryImageUrl,
      unitPrice: product.effectivePrice,
      regularPrice: product.price,
      vendorName: 'Medivila Pharmacy',
      slug: product.slug,
      variantLabel: size?.size ?? '',
      requiresPrescription: product.requiresPrescription,
    );
    add(line);
  }

  void add(CartLine line) {
    final existing = lines.where((l) => l.key == line.key).firstOrNull;
    if (existing != null) {
      existing.quantity = (existing.quantity + line.quantity).clamp(1, 999);
    } else {
      lines.add(line);
    }
    notifyListeners();
    _save();
  }

  void setQuantity(CartLine line, int q) {
    if (q < 1) return remove(line);
    line.quantity = q.clamp(1, 999);
    notifyListeners();
    _save();
  }

  void remove(CartLine line) {
    lines.remove(line);
    notifyListeners();
    _save();
  }

  void clear() {
    lines.clear();
    notifyListeners();
    _save();
  }
}
