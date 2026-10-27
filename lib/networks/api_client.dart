import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_config.dart';

/// Single Dio client. Attaches the bearer token, and on a 401 refreshes the
/// token once (shared across concurrent requests — a refresh token works only
/// once) and retries. If refresh fails, [onSessionExpired] fires.
class ApiClient {
  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _access ??= await _storage.read(key: _kAccess);
        if (token != null && options.extra['noAuth'] != true) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final is401 = e.response?.statusCode == 401;
        final path = e.requestOptions.path;
        final isAuthCall = path.contains('/auth/token/refresh/') || path.contains('/auth/login/');
        final hadToken = e.requestOptions.headers['Authorization'] != null;
        if (is401 && hadToken && !isAuthCall && e.requestOptions.extra['retried'] != true) {
          if (await _refresh()) {
            final req = e.requestOptions..extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer $_access';
            try {
              return handler.resolve(await dio.fetch(req));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
          await clearTokens();
          onSessionExpired?.call();
        }
        handler.next(e);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  static const _kAccess = 'access';
  static const _kRefresh = 'refresh';

  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  String? _access;
  Completer<bool>? _refreshing;

  void Function()? onSessionExpired;

  Future<bool> get hasToken async => (await _storage.read(key: _kAccess)) != null;

  Future<String?> get refreshToken => _storage.read(key: _kRefresh);

  Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccessToken(String access) async {
    _access = access;
    await _storage.write(key: _kAccess, value: access);
    await _storage.delete(key: _kRefresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    var ok = false;
    try {
      final refresh = await _storage.read(key: _kRefresh);
      if (refresh != null) {
        final r = await Dio(BaseOptions(baseUrl: AppConfig.apiUrl))
            .post('/auth/token/refresh/', data: {'refresh': refresh});
        _access = r.data['access'] as String;
        await _storage.write(key: _kAccess, value: _access);
        if (r.data['refresh'] != null) {
          await _storage.write(key: _kRefresh, value: r.data['refresh'] as String);
        }
        ok = true;
      }
    } catch (_) {
      ok = false;
    }
    c.complete(ok);
    _refreshing = null;
    return ok;
  }
}

Dio get api => ApiClient.instance.dio;
