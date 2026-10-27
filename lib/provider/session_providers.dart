import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import '../models/common.dart';
import '../networks/api_services.dart';

class AppState extends ChangeNotifier {
  AppSettings settings = AppSettings.fallback();
  Map<String, dynamic> payment = const {};

  bool get onlineEnabled => payment.isEmpty
      ? settings.onlinePaymentEnabled
      : payment['online_enabled'] == true;

  void setSettings(AppSettings s) {
    settings = s;
    notifyListeners();
  }

  Future<void> loadPaymentSettings() async {
    try {
      payment = await PaymentApi.settings();
      notifyListeners();
    } catch (_) {}
  }
}

/// Heart icons: one Set of ids, optimistic toggles.
class WishlistProvider extends ChangeNotifier {
  final Set<String> ids = {};

  bool contains(String id) => ids.contains(id);

  Future<void> load() async {
    try {
      ids
        ..clear()
        ..addAll(await CustomerApi.wishlistIds());
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    ids.clear();
    notifyListeners();
  }

  /// Returns false if the server rejected the change (UI is rolled back).
  Future<bool> toggle(String id) async {
    final adding = !ids.contains(id);
    adding ? ids.add(id) : ids.remove(id);
    notifyListeners();
    try {
      adding
          ? await CustomerApi.addWishlist(id)
          : await CustomerApi.removeWishlist(id);
      return true;
    } catch (_) {
      adding ? ids.remove(id) : ids.add(id);
      notifyListeners();
      return false;
    }
  }
}

/// Unread badge — polled every 60 s while logged in and the app is open.
class NotificationBadge extends ChangeNotifier {
  int unread = 0;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(AppConfig.unreadPoll, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    unread = 0;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final n = await NotificationApi.unreadCount();
      if (n != unread) {
        unread = n;
        notifyListeners();
      }
    } catch (_) {}
  }

  void set(int n) {
    unread = n;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
