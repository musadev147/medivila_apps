import '../helpers/format_utils.dart';

/// Wrapper for the backend's paginated list shape.
class Paged<T> {
  Paged({required this.results, required this.count, required this.next, this.extra = const {}});

  final List<T> results;
  final int count;
  final String? next;
  final Map<String, dynamic> extra;

  bool get hasMore => next != null;

  factory Paged.fromJson(dynamic json, T Function(Map<String, dynamic>) parse) {
    if (json is List) {
      return Paged(results: json.map((e) => parse(Map<String, dynamic>.from(e))).toList(), count: json.length, next: null);
    }
    final m = Map<String, dynamic>.from(json as Map);
    final list = (m['results'] as List? ?? const []);
    return Paged(
      results: list.map((e) => parse(Map<String, dynamic>.from(e))).toList(),
      count: toInt(m['count']),
      next: m['next'] as String?,
      extra: m,
    );
  }
}

class AppSettings {
  AppSettings(this.raw);
  final Map<String, dynamic> raw;

  Map<String, dynamic> get _maint => Map<String, dynamic>.from(raw['maintenance'] ?? const {});
  Map<String, dynamic> get _support => Map<String, dynamic>.from(raw['support'] ?? const {});
  Map<String, dynamic> get _shop => Map<String, dynamic>.from(raw['shop'] ?? const {});

  bool get maintenance => _maint['enabled'] == true;
  String get maintenanceMessage => str(_maint['message']);
  bool get updateRequired => raw['update_required'] == true;
  bool get updateAvailable => raw['update_available'] == true;
  String get updateMessage => str(raw['update_message']);
  String get storeUrl => str(raw['store_url']);
  String get latestVersion => str(raw['latest_version']);

  String get supportPhone => str(_support['phone']);
  String get supportEmail => str(_support['email']);
  String get supportWhatsapp => str(_support['whatsapp']);

  int get returnWindowDays => toInt(_shop['return_window_days'] ?? 7);
  double get feeInsideDhaka => toDouble(_shop['delivery_fee_inside_dhaka']);
  double get feeOutsideDhaka => toDouble(_shop['delivery_fee_outside_dhaka']);
  bool get onlinePaymentEnabled => _shop['online_payment_enabled'] != false;
  bool get cashOnDelivery => _shop['cash_on_delivery'] != false;

  static AppSettings fallback() => AppSettings(const {});
}
