import '../helpers/format_utils.dart';

class User {
  User(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get email => str(raw['email']);
  String get firstName => str(raw['first_name']);
  String get lastName => str(raw['last_name']);
  String get fullName => '$firstName $lastName'.trim().isEmpty ? email : '$firstName $lastName'.trim();
  String get phone => str(raw['phone_number']);
  String get role => str(raw['role']);
  bool get isCustomer => role == 'customer';
  bool get isVendor => role == 'vendor';

  /// Roles this app supports; staff / admin accounts use the web panel.
  bool get isAppRole => isCustomer || isVendor;
  Map<String, dynamic>? get vendorProfile =>
      raw['vendor_profile'] is Map ? Map<String, dynamic>.from(raw['vendor_profile']) : null;
  bool get storeApproved => vendorProfile?['is_approved'] == true;
  String get storeName => str(vendorProfile?['store_name']);
  bool get verified => raw['is_verified'] == true;
  Map<String, dynamic> get profile => Map<String, dynamic>.from(raw['profile'] ?? const {});
  String? get avatar => mediaUrl(profile['avatar']);
  DateTime? get joined => toDate(raw['date_joined']);
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : (email.isNotEmpty ? email[0] : '?');
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }
}

class Address {
  Address(this.raw);
  final Map<String, dynamic> raw;

  String get id => str(raw['id']);
  String get label => str(raw['label']).isEmpty ? 'home' : str(raw['label']);
  String get labelDisplay => str(raw['label_display']).isEmpty ? label : str(raw['label_display']);
  String get fullName => str(raw['full_name']);
  String get phone => str(raw['phone']);
  String get line1 => str(raw['address_line_1']);
  String get line2 => str(raw['address_line_2']);
  String get city => str(raw['city']);
  String get state => str(raw['state']);
  String get postalCode => str(raw['postal_code']);
  String get country => str(raw['country']).isEmpty ? 'Bangladesh' : str(raw['country']);
  bool get isDefault => raw['is_default'] == true;
  bool get insideDhaka => city.toLowerCase().contains('dhaka');

  String get oneLine =>
      [line1, line2, city, state, postalCode].where((s) => s.trim().isNotEmpty).join(', ');
}

class AppNotification {
  AppNotification(this.raw);
  final Map<String, dynamic> raw;
  String get id => str(raw['id']);
  String get kind => str(raw['kind']);
  String get title => str(raw['title']);
  String get message => str(raw['message']);
  String get link => str(raw['link']);
  bool get isRead => raw['is_read'] == true;
  set isRead(bool v) => raw['is_read'] = v;
  DateTime? get createdAt => toDate(raw['created_at']);
}
