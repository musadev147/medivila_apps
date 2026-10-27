import 'package:intl/intl.dart';

import '../constants/app_config.dart';

/// Some image fields come as full URLs, others (order items, returns,
/// wholesale catalogue) only as `/media/...` paths. Run every image through this.
String? mediaUrl(dynamic path) {
  if (path == null) return null;
  final p = path.toString();
  if (p.isEmpty) return null;
  if (p.startsWith('http')) return p;
  return '${AppConfig.baseUrl}${p.startsWith('/') ? '' : '/'}$p';
}

/// Money arrives as a string ("1360.00") on most endpoints and as a number on
/// a few (search-suggest, shipping-quote). Accept both.
double toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String str(dynamic v) => v == null ? '' : v.toString();

DateTime? toDate(dynamic v) {
  if (v == null || v.toString().isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

final _money = NumberFormat('#,##0.##', 'en_US');
final _money2 = NumberFormat('#,##0.00', 'en_US');

/// ৳1,360
String money(dynamic v, {bool decimals = false}) {
  final d = toDouble(v);
  return '৳${decimals ? _money2.format(d) : _money.format(d)}';
}

String fmtDate(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d);

String fmtDateTime(DateTime? d) =>
    d == null ? '—' : DateFormat('d MMM yyyy, h:mm a').format(d);

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return fmtDate(d);
}

int discountPercent(double effective, double regular) {
  if (regular <= 0 || effective >= regular) return 0;
  return ((1 - effective / regular) * 100).round();
}

/// Descriptions may contain HTML; render them as readable plain text.
String stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

final _bdPhone = RegExp(r'^01[3-9]\d{8}$');
bool isBdPhone(String s) => _bdPhone.hasMatch(s.trim());

bool isEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());
