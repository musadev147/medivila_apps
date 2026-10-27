import 'package:dio/dio.dart';
import '../api_client.dart';

Future<Response<T>> getHttp<T>(
  String url, {
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onReceiveProgress,
}) async {
  return await ApiClient.instance.dio.get<T>(
    url,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
  );
}

Future<Response<T>> postHttp<T>(
  String url, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onSendProgress,
  ProgressCallback? onReceiveProgress,
}) async {
  return await ApiClient.instance.dio.post<T>(
    url,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );
}

Future<Response<T>> putHttp<T>(
  String url, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
}) async {
  return await ApiClient.instance.dio.put<T>(
    url,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );
}

Future<Response<T>> deleteHttp<T>(
  String url, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
}) async {
  return await ApiClient.instance.dio.delete<T>(
    url,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );
}

Future<Response<T>> patchHttp<T>(
  String url, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
}) async {
  return await ApiClient.instance.dio.patch<T>(
    url,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );
}
