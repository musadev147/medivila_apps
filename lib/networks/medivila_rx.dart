import 'dart:developer';
import 'package:rxdart/rxdart.dart';

import '../models/medivila_models.dart';
import 'medivila_api_services.dart';
import 'rx_base.dart';

// 1. Bootstrap Rx
class GetBootstrapRx extends RxResponseInt<BootstrapData> {
  final api = BootstrapApi.instance;

  GetBootstrapRx({required super.empty, required super.dataFetcher});

  ValueStream<BootstrapData> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchBootstrap() async {
    try {
      BootstrapData data = await api.getBootstrap();
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchBootstrap Error: $error");
      return await handleErrorWithReturn(error);
    }
  }

  @override
  handleSuccessWithReturn(data) async {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(data);
    }
    return true;
  }
}

// 2. Products Rx
class GetProductsRx extends RxResponseInt<List<MedicineProduct>> {
  final api = ProductsApi.instance;

  GetProductsRx({required super.empty, required super.dataFetcher});

  ValueStream<List<MedicineProduct>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchProducts({int? categoryId, String? search}) async {
    try {
      List<MedicineProduct> data = await api.getProducts(categoryId: categoryId, search: search);
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchProducts Error: $error");
      return await handleErrorWithReturn(error);
    }
  }

  @override
  handleSuccessWithReturn(data) async {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(data);
    }
    return true;
  }
}

// 3. Specialist Doctors Rx
class GetDoctorsRx extends RxResponseInt<List<DoctorModel>> {
  final api = DoctorsApi.instance;

  GetDoctorsRx({required super.empty, required super.dataFetcher});

  ValueStream<List<DoctorModel>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchDoctors({int? departmentId, String? search}) async {
    try {
      List<DoctorModel> data = await api.getDoctors(departmentId: departmentId, search: search);
      return await handleSuccessWithReturn(data);
    } catch (error) {
      return await handleErrorWithReturn(error);
    }
  }

  @override
  handleSuccessWithReturn(data) async {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(data);
    }
    return true;
  }
}

// 4. Lab Tests Rx
class GetLabTestsRx extends RxResponseInt<List<LabTestModel>> {
  final api = LabTestsApi.instance;

  GetLabTestsRx({required super.empty, required super.dataFetcher});

  ValueStream<List<LabTestModel>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchLabTests({String? search}) async {
    try {
      List<LabTestModel> data = await api.getLabTests(search: search);
      return await handleSuccessWithReturn(data);
    } catch (error) {
      return await handleErrorWithReturn(error);
    }
  }

  @override
  handleSuccessWithReturn(data) async {
    if (!dataFetcher.isClosed) {
      dataFetcher.sink.add(data);
    }
    return true;
  }
}
