import '../helpers/format_utils.dart';

List<Map<String, dynamic>> _maps(dynamic v) =>
    (v as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

class Order {
  Order(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get number => str(raw['order_number']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get paymentMethod => str(raw['payment_method']);
  String get paymentMethodDisplay => str(raw['payment_method_display']).isNotEmpty
      ? str(raw['payment_method_display'])
      : (paymentMethod == 'cod' ? 'Cash on delivery' : 'Online payment');
  String get paymentStatus => str(raw['payment_status']);
  String get paymentStatusDisplay => str(raw['payment_status_display']);
  bool get isPaid => paymentStatus == 'paid';
  bool get canPayOnline => raw['can_pay_online'] == true;
  bool get canCancel => raw['can_cancel'] == true;
  double get subtotal => toDouble(raw['subtotal']);
  double get discountTotal => toDouble(raw['discount_total']);
  double get shippingTotal => toDouble(raw['shipping_total']);
  double get grandTotal => toDouble(raw['grand_total']);
  int get itemCount => toInt(raw['item_count']);
  String get couponCode => str(raw['coupon_code']);
  DateTime? get placedAt => toDate(raw['placed_at']);
  String get shippingName => str(raw['shipping_name']);
  String get shippingPhone => str(raw['shipping_phone']);
  String get shippingAddress => str(raw['shipping_address']);
  String get customerNote => str(raw['customer_note']);
  List<Package> get packages => _maps(raw['vendor_orders']).map(Package.new).toList();
}

class Package {
  Package(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get number => str(raw['vendor_order_number']);
  String get vendorName => str(raw['vendor_name']).isEmpty ? 'Brand Source' : str(raw['vendor_name']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  double get subtotal => toDouble(raw['subtotal']);
  double get discount => toDouble(raw['discount_amount']);
  double get shippingFee => toDouble(raw['shipping_fee']);
  double get total => toDouble(raw['total']);
  double get refunded => toDouble(raw['refunded_amount']);
  String get courierName => str(raw['courier_name']);
  String get trackingNumber => str(raw['tracking_number']);
  String get cancelReason => str(raw['cancel_reason']);
  DateTime? get confirmedAt => toDate(raw['confirmed_at']);
  DateTime? get shippedAt => toDate(raw['shipped_at']);
  DateTime? get deliveredAt => toDate(raw['delivered_at']);
  DateTime? get cancelledAt => toDate(raw['cancelled_at']);
  bool get canRequestReturn => raw['can_request_return'] == true;
  DateTime? get returnDeadline => toDate(raw['return_deadline']);
  bool get canRateSeller => raw['can_rate_seller'] == true;
  Map<String, dynamic>? get sellerRating =>
      raw['seller_rating'] == null ? null : Map<String, dynamic>.from(raw['seller_rating']);
  Shipment? get shipment =>
      raw['shipment'] == null ? null : Shipment(Map<String, dynamic>.from(raw['shipment']));
  List<OrderItem> get items => _maps(raw['items']).map(OrderItem.new).toList();
  List<Map<String, dynamic>> get returnRequests => _maps(raw['return_requests']);
  bool get isDelivered => status == 'delivered';
}

class OrderItem {
  OrderItem(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get productId => str(raw['product']);
  String get slug => str(raw['product_slug']);
  String get title => str(raw['product_title'] ?? raw['title']);
  String get variantLabel => str(raw['variant_label']);
  String? get thumbnail => mediaUrl(raw['thumbnail']);
  double get unitPrice => toDouble(raw['unit_price']);
  int get quantity => toInt(raw['quantity']);
  double get lineTotal => toDouble(raw['line_total'] ?? raw['line_value']);
  int get returnable => toInt(raw['returnable_quantity']);
  int get returned => toInt(raw['returned_quantity']);
}

class Shipment {
  Shipment(this.raw);
  final Map<String, dynamic> raw;
  String get provider => str(raw['provider_label']).isEmpty ? str(raw['provider']) : str(raw['provider_label']);
  String get trackingCode => str(raw['tracking_code'] ?? raw['consignment_id']);
  String get trackingUrl => str(raw['tracking_url']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  List<Map<String, dynamic>> get events => _maps(raw['events']);
}

class ReturnRequest {
  ReturnRequest(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get number => str(raw['return_number']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get reasonDisplay => str(raw['reason_display']).isEmpty ? str(raw['reason']) : str(raw['reason_display']);
  String get description => str(raw['description']);
  String get orderNumber => str(raw['order_number']);
  String get packageNumber => str(raw['vendor_order_number']);
  String get vendorName => str(raw['vendor_name']);
  double get requestedAmount => toDouble(raw['requested_amount']);
  double get refundAmount => toDouble(raw['refund_amount']);
  String get refundMethod => str(raw['refund_method']);
  String get refundTxn => str(raw['refund_transaction_id']);
  DateTime? get refundedAt => toDate(raw['refunded_at']);
  DateTime? get requestedAt => toDate(raw['requested_at']);
  DateTime? get respondBy => toDate(raw['respond_by']);
  String get returnCourier => str(raw['return_courier']);
  String get returnTracking => str(raw['return_tracking']);
  List<String> get allowedActions =>
      (raw['allowed_actions'] as List? ?? const []).map((e) => e.toString()).toList();
  List<OrderItem> get items => _maps(raw['items']).map(OrderItem.new).toList();
  List<String> get images => (raw['images'] as List? ?? const [])
      .map((e) => mediaUrl(e is Map ? e['image'] : e))
      .whereType<String>()
      .toList();
  List<Map<String, dynamic>> get logs => _maps(raw['status_logs']);
}

const returnReasons = <String, String>{
  'wrong_item': 'Wrong item received',
  'damaged': 'Damaged / defective',
  'not_as_described': 'Not as described',
  'size_issue': 'Size / fit issue',
  'changed_mind': 'Changed my mind',
  'other': 'Other',
};
