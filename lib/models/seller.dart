import '../helpers/format_utils.dart';
import 'order.dart';

List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List ? v : const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

/// `/auth/vendor-profile/` — the seller's own store settings.
class VendorProfile {
  VendorProfile(this.raw);
  final Map<String, dynamic> raw;

  int get id => toInt(raw['id']);
  String get storeName => str(raw['store_name']);
  String get storeSlug => str(raw['store_slug']);
  String get description => str(raw['description']);
  String? get logo => mediaUrl(raw['logo']);
  String? get banner => mediaUrl(raw['banner']);
  String get businessEmail => str(raw['business_email']);
  String get businessPhone => str(raw['business_phone']);
  String get address => str(raw['address']);
  String get taxNumber => str(raw['tax_number']);
  String get shippingPolicy => str(raw['shipping_policy']);
  String get returnPolicy => str(raw['return_policy']);
  String get payoutMethod => str(raw['payout_method']);
  Map<String, dynamic> get payoutAccount =>
      raw['payout_account'] is Map ? Map<String, dynamic>.from(raw['payout_account']) : {};
  bool get isApproved => raw['is_approved'] == true;
  double get commissionRate => toDouble(raw['commission_rate']);
}

/// A seller's package (one vendor's part of a customer order).
class VendorOrder {
  VendorOrder(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get number => str(raw['vendor_order_number']);
  String get orderNumber => str(raw['order_number']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get paymentMethod => str(raw['payment_method']);
  String get paymentMethodDisplay =>
      str(raw['payment_method_display']).isEmpty ? (paymentMethod == 'cod' ? 'Cash on delivery' : 'Online') : str(raw['payment_method_display']);
  String get paymentStatus => str(raw['payment_status']);
  String get customerName => str(raw['customer_name']).isEmpty ? shippingName : str(raw['customer_name']);
  String get shippingName => str(raw['shipping_name']);
  String get shippingPhone => str(raw['shipping_phone']);
  String get shippingAddress => str(raw['shipping_address']);
  String get customerNote => str(raw['customer_note']);
  double get subtotal => toDouble(raw['subtotal']);
  double get discount => toDouble(raw['discount_amount']);
  double get vendorDiscount => toDouble(raw['vendor_discount']);
  double get shippingFee => toDouble(raw['shipping_fee']);
  double get total => toDouble(raw['total']);
  double get commission => toDouble(raw['commission_amount']);
  double get earnings => toDouble(raw['vendor_earnings']);
  String get courierName => str(raw['courier_name']);
  String get trackingNumber => str(raw['tracking_number']);
  String get cancelReason => str(raw['cancel_reason']);
  DateTime? get placedAt => toDate(raw['placed_at']);
  DateTime? get confirmedAt => toDate(raw['confirmed_at']);
  DateTime? get shippedAt => toDate(raw['shipped_at']);
  DateTime? get deliveredAt => toDate(raw['delivered_at']);
  int get itemCount => toInt(raw['item_count']);
  List<OrderItem> get items => _maps(raw['items']).map(OrderItem.new).toList();
  List<Map<String, dynamic>> get logs => _maps(raw['status_logs']);
  Shipment? get shipment => raw['shipment'] is Map ? Shipment(Map<String, dynamic>.from(raw['shipment'])) : null;
  bool get canBookCourier => raw['can_book_courier'] == true;

  /// Statuses the seller may move this package to next (server decides).
  List<String> get allowedTransitions {
    final t = raw['allowed_transitions'];
    if (t is List) return t.map((e) => e is Map ? str(e['value'] ?? e['status']) : e.toString()).where((s) => s.isNotEmpty).toList();
    if (t is String && t.isNotEmpty) return t.split(',').map((s) => s.trim()).toList();
    return const [];
  }
}

class Payout {
  Payout(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get number => str(raw['payout_number']);
  double get amount => toDouble(raw['amount']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get method => str(raw['payment_method']);
  String get methodDisplay => str(raw['payment_method_display']).isEmpty ? method : str(raw['payment_method_display']);
  String get reference => str(raw['transaction_reference']);
  String get adminNote => str(raw['admin_note']);
  Map<String, dynamic> get account =>
      raw['account_details'] is Map ? Map<String, dynamic>.from(raw['account_details']) : {};
  DateTime? get createdAt => toDate(raw['created_at']);
  DateTime? get processedAt => toDate(raw['processed_at']);
}

class Coupon {
  Coupon(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get code => str(raw['code']);
  String get title => str(raw['title']);
  String get discountType => str(raw['discount_type']).isEmpty ? 'percent' : str(raw['discount_type']);
  double get value => toDouble(raw['value']);
  double? get maxDiscount => toDoubleOrNull(raw['max_discount']);
  double? get minOrder => toDoubleOrNull(raw['min_order_amount']);
  int? get usageLimit => raw['usage_limit'] == null ? null : toInt(raw['usage_limit']);
  int? get perCustomer => raw['per_customer_limit'] == null ? null : toInt(raw['per_customer_limit']);
  DateTime? get startsAt => toDate(raw['starts_at']);
  DateTime? get endsAt => toDate(raw['ends_at']);
  bool get isActive => raw['is_active'] != false;
  int get uses => toInt(raw['uses']);
  String get valueLabel => discountType == 'percent' ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}% off' : '${money(value)} off';
  bool get expired => endsAt != null && endsAt!.isBefore(DateTime.now());
}

class FlashCampaign {
  FlashCampaign(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get title => str(raw['title']);
  String get description => str(raw['description']);
  DateTime? get startsAt => toDate(raw['starts_at']);
  DateTime? get endsAt => toDate(raw['ends_at']);
  String get phase => str(raw['phase']);
  int get minDiscount => toInt(raw['min_discount_percent']);
  int get approved => toInt(raw['approved_count']);
  int get pending => toInt(raw['pending_count']);
  bool get open => phase != 'ended' && (endsAt == null || endsAt!.isAfter(DateTime.now()));
}

class FlashItem {
  FlashItem(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get productTitle => str(raw['product_title']);
  String? get thumbnail => mediaUrl(raw['product_thumbnail']);
  double get normalPrice => toDouble(raw['normal_price']);
  double get flashPrice => toDouble(raw['flash_price']);
  double get discountPercent => toDouble(raw['discount_percent']);
  int get quantityLimit => toInt(raw['quantity_limit']);
  int get sold => toInt(raw['sold_count']);
  int get remaining => toInt(raw['remaining']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get rejectionReason => str(raw['rejection_reason']);
}

const payoutMethods = {'bkash': 'bKash', 'nagad': 'Nagad', 'rocket': 'Rocket', 'bank': 'Bank transfer'};

const productStatuses = {
  'published': 'Live',
  'pending_approval': 'In review',
  'draft': 'Draft',
  'rejected': 'Rejected',
};
