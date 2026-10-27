import 'package:flutter/foundation.dart';

import '../networks/api_client.dart';
import '../models/account.dart';
import '../models/medivila_models.dart';
import '../networks/medivila_api_services.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  MedivilaUser? phoneUser;
  bool get loggedIn => user != null || phoneUser != null;
  bool get isSeller => user?.isVendor == true;

  /// Called on app start: if a token is stored, refresh the user.
  Future<void> restore() async {
    if (!await ApiClient.instance.hasToken) return;
    try {
      phoneUser = await UserAuthApi.instance.currentUser();
      notifyListeners();
    } catch (_) {
      // Keep the stored session when the profile is temporarily unreachable.
    }
  }

  Future<void> loginWithPhone(String phone) async {
    final loggedInUser = await UserAuthApi.instance.fastPhoneLogin(phone);
    final token = loggedInUser.token;
    if (token == null || token.isEmpty) {
      throw const FormatException('Login response is missing token');
    }
    await ApiClient.instance.saveAccessToken(token);
    phoneUser = loggedInUser;
    user = null;
    notifyListeners();
  }

  Future<void> registerWithPhone({
    required String name,
    required String phone,
    required String password,
  }) async {
    final loggedInUser = await UserAuthApi.instance.register(
      name: name,
      phone: phone,
      password: password,
    );
    final token = loggedInUser.token;
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Registration succeeded but session token is missing',
      );
    }
    await ApiClient.instance.saveAccessToken(token);
    phoneUser = loggedInUser;
    user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      phoneUser = await UserAuthApi.instance.currentUser();
      notifyListeners();
    } catch (_) {}
  }

  void setUser(User u) {
    user = u;
    notifyListeners();
  }

  /// Server logout + always wipe local tokens (even offline).
  Future<void> logout({bool allDevices = false}) async {
    await ApiClient.instance.clearTokens();
    user = null;
    phoneUser = null;
    notifyListeners();
  }

  /// Session expired (refresh failed) — drop local state.
  void expire() {
    if (!loggedIn) return;
    user = null;
    phoneUser = null;
    notifyListeners();
  }
}
