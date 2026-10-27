import '../helpers/format_utils.dart';

class WholesaleAccount {
  WholesaleAccount(this.raw);
  final Map<String, dynamic> raw;
  String get businessName => str(raw['business_name']);
  String get businessType => str(raw['business_type']);
  String get contactName => str(raw['contact_name']);
  String get phone => str(raw['phone']);
  String get address => str(raw['address']);
  String get city => str(raw['city']);
  String get tradeLicense => str(raw['trade_license']);
  String get tin => str(raw['tin']);
  String get note => str(raw['note']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get adminNote => str(raw['admin_note']);
  WholesaleCredit get credit => WholesaleCredit(Map<String, dynamic>.from(raw['credit'] ?? const {}));
  bool get canUseCredit => credit.limit > 0;
}

class WholesaleCredit {
  WholesaleCredit(this.raw);
  final Map<String, dynamic> raw;
  double get limit => toDouble(raw['credit_limit']);
  int get days => toInt(raw['credit_days']);
  double get billed => toDouble(raw['billed']);
  double get paid => toDouble(raw['paid']);
  double get outstanding => toDouble(raw['outstanding']);
  double get pendingOrders => toDouble(raw['pending_orders']);
  double get available => toDouble(raw['available_credit']);
  double get overdue => toDouble(raw['overdue']);
}

class WholesaleProduct {
  WholesaleProduct(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['product']);
  String get title => str(raw['title']);
  String get sku => str(raw['sku']);
  String get unit => str(raw['unit']);
  String get category => str(raw['category']);
  String? get thumbnail => mediaUrl(raw['thumbnail']);
  double get retailPrice => toDouble(raw['retail_price']);
  double get price => toDouble(raw['price']);
  int get moq => toInt(raw['moq']) < 1 ? 1 : toInt(raw['moq']);
  bool get specialPrice => raw['special_price'] == true;
  int get stock => toInt(raw['stock']);
  List<WholesaleVariant> get variants => (raw['variants'] as List? ?? const [])
      .map((e) => WholesaleVariant(Map<String, dynamic>.from(e)))
      .toList();
}

class WholesaleVariant {
  WholesaleVariant(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get label => str(raw['label']);
  String get value => str(raw['value']);
  int get stock => toInt(raw['stock']);
}

class WholesaleOrder {
  WholesaleOrder(this.raw);
  final Map<String, dynamic> raw;
  String get number => str(raw['order_number']);
  String get status => str(raw['status']);
  String get statusDisplay => str(raw['status_display']);
  String get paymentTerms => str(raw['payment_terms']);
  double get subtotal => toDouble(raw['subtotal']);
  double get discount => toDouble(raw['discount']);
  double get deliveryCharge => toDouble(raw['delivery_charge']);
  double get total => toDouble(raw['total']);
  double get paid => toDouble(raw['paid']);
  double get balance => toDouble(raw['balance']);
  bool get overdue => raw['overdue'] == true;
  DateTime? get dueDate => toDate(raw['due_date']);
  String get tracking => str(raw['tracking']);
  int get units => toInt(raw['units']);
  DateTime? get createdAt => toDate(raw['created_at'] ?? raw['placed_at']);
  List<Map<String, dynamic>> get items =>
      (raw['items'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e)).toList();
  List<Map<String, dynamic>> get logs =>
      (raw['logs'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e)).toList();
}
