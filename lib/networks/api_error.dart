import 'package:dio/dio.dart';

/// One human-readable message from any of the backend's three error shapes:
/// `{"detail": "..."}`, `{"field": ["..."]}`, `{"field": "..."}`.
String apiError(Object e, [String fallback = 'Something went wrong. Please try again.']) {
  if (e is! DioException) return fallback;
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'No internet connection. Check your network and try again.';
    default:
      break;
  }
  final data = e.response?.data;
  if (data is Map) {
    if (data['detail'] is String) return data['detail'] as String;
    for (final v in data.values) {
      if (v is String && v.isNotEmpty) return v;
      if (v is List && v.isNotEmpty && v.first is String) return v.first as String;
      if (v is Map) {
        for (final inner in v.values) {
          if (inner is List && inner.isNotEmpty) return inner.first.toString();
          if (inner is String) return inner;
        }
      }
    }
  }
  final code = e.response?.statusCode;
  if (code == 404) return 'Not found.';
  if (code != null && code >= 500) return 'Server problem. Please try again shortly.';
  return fallback;
}

/// Per-field errors (key = field name) to show under form inputs.
Map<String, String> fieldErrors(Object e) {
  if (e is! DioException) return {};
  final data = e.response?.data;
  if (data is! Map) return {};
  return {
    for (final entry in data.entries)
      if (entry.value is List && (entry.value as List).isNotEmpty)
        entry.key.toString(): (entry.value as List).first.toString()
      else if (entry.value is String)
        entry.key.toString(): entry.value as String,
  };
}
