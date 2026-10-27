import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:rxdart/subjects.dart';

import '../common_wigdets/app_toast.dart';
import 'exception_handler/data_source.dart';

abstract class RxResponseInt<T> {
  T empty;
  BehaviorSubject<T> dataFetcher;
  Map? map;
  BehaviorSubject? dataFetcher2;

  RxResponseInt({
    required this.empty,
    required this.dataFetcher,
    this.map,
    this.dataFetcher2,
  });

  dynamic handleSuccessWithReturn(T data) {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(data);
    }
    return data;
  }

  dynamic handleErrorWithReturn(dynamic error) {
    log("RxResponse Error: $error");

    // Always dismiss loading spinner first so toast is visible
    EasyLoading.dismiss();

    String errorMessage = "Something went wrong. Please try again.";

    if (error is DioException) {
      final failure = ErrorHandler.handle(error).failure;
      errorMessage = failure.responseMessage;
    } else if (error is Failure) {
      errorMessage = error.responseMessage;
    } else if (error is Exception) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    AppToast.error(errorMessage);

    if (!dataFetcher.isClosed) {
      dataFetcher.sink.addError(error);
    }
    throw error;
  }

  void clean() {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(empty);
    }
  }

  void dispose() {
    dataFetcher.close();
  }
}