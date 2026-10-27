import 'package:dio/dio.dart';

enum DataSource {
  SUCCESS,
  NO_CONTENT,
  BAD_REQUEST,
  FORBIDDEN,
  UNAUTHORIZED,
  NOT_FOUND,
  INTERNAL_SERVER_ERROR,
  CONNECT_TIMEOUT,
  CANCEL,
  RECEIVE_TIMEOUT,
  SEND_TIMEOUT,
  CACHE_ERROR,
  NO_INTERNET_CONNECTION,
  DEFAULT,
}

class Failure {
  final int responseCode;
  final String responseMessage;

  Failure(this.responseCode, this.responseMessage);

  @override
  String toString() => '$responseMessage ($responseCode)';
}

extension DataSourceExtension on DataSource {
  Failure getFailure() {
    switch (this) {
      case DataSource.BAD_REQUEST:
        return Failure(400, "Bad request. Please check your data.");
      case DataSource.FORBIDDEN:
        return Failure(403, "Access forbidden.");
      case DataSource.UNAUTHORIZED:
        return Failure(401, "Unauthorized. Please sign in again.");
      case DataSource.NOT_FOUND:
        return Failure(404, "Requested resource not found.");
      case DataSource.INTERNAL_SERVER_ERROR:
        return Failure(500, "Internal server error. Please try again later.");
      case DataSource.CONNECT_TIMEOUT:
        return Failure(-1, "Connection timeout with server.");
      case DataSource.CANCEL:
        return Failure(-2, "Request was cancelled.");
      case DataSource.RECEIVE_TIMEOUT:
        return Failure(-3, "Receive timeout in connection with server.");
      case DataSource.SEND_TIMEOUT:
        return Failure(-4, "Send timeout in connection with server.");
      case DataSource.CACHE_ERROR:
        return Failure(-5, "Cache error occurred.");
      case DataSource.NO_INTERNET_CONNECTION:
        return Failure(-6, "No internet connection. Please check your network.");
      case DataSource.DEFAULT:
      default:
        return Failure(-7, "Something went wrong. Please try again.");
    }
  }
}

class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      failure = _handleDioError(error);
    } else if (error is Failure) {
      failure = error;
    } else {
      failure = DataSource.DEFAULT.getFailure();
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return DataSource.CONNECT_TIMEOUT.getFailure();
      case DioExceptionType.sendTimeout:
        return DataSource.SEND_TIMEOUT.getFailure();
      case DioExceptionType.receiveTimeout:
        return DataSource.RECEIVE_TIMEOUT.getFailure();
      case DioExceptionType.cancel:
        return DataSource.CANCEL.getFailure();
      case DioExceptionType.connectionError:
        return DataSource.NO_INTERNET_CONNECTION.getFailure();
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 500;
        final data = error.response?.data;
        String message = "Server responded with error ($code)";
        if (data is Map) {
          if (data['message'] != null) {
            message = data['message'].toString();
          } else if (data['detail'] != null) {
            message = data['detail'].toString();
          } else if (data['error'] != null) {
            message = data['error'].toString();
          }
        }
        return Failure(code, message);
      default:
        return DataSource.DEFAULT.getFailure();
    }
  }
}
