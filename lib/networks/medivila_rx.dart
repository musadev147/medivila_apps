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
      List<MedicineProduct> data = await api.getProducts(
        categoryId: categoryId,
        search: search,
      );
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

// 3. Categories Rx
class GetCategoriesRx extends RxResponseInt<List<CategoryItem>> {
  final api = CategoriesApi.instance;

  GetCategoriesRx({required super.empty, required super.dataFetcher});

  ValueStream<List<CategoryItem>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchCategories() async {
    try {
      final data = await api.getCategories();
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchCategories Error: $error");
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

// 4. Specialist Doctors Rx
class GetDoctorsRx extends RxResponseInt<List<DoctorModel>> {
  final api = DoctorsApi.instance;

  GetDoctorsRx({required super.empty, required super.dataFetcher});

  ValueStream<List<DoctorModel>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchDoctors({int? departmentId, String? search}) async {
    try {
      List<DoctorModel> data = await api.getDoctors(
        departmentId: departmentId,
        search: search,
      );
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

// 5. Lab Tests Rx
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

// 6. Service Banners Rx
class GetServiceBannersRx extends RxResponseInt<List<ServiceBanner>> {
  final api = ServiceBannersApi.instance;

  GetServiceBannersRx({required super.empty, required super.dataFetcher});

  ValueStream<List<ServiceBanner>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchServiceBanners() async {
    try {
      final data = await api.getServiceBanners();
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchServiceBanners Error: $error");
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

// 6. Offers Rx
class GetOffersRx extends RxResponseInt<List<OfferItem>> {
  final api = OffersApi.instance;

  GetOffersRx({required super.empty, required super.dataFetcher});

  ValueStream<List<OfferItem>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchOffers() async {
    try {
      List<OfferItem> data = await api.getOffers();
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchOffers Error: $error");
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

// 7. Menus Rx
class GetHomePageMenusRx extends RxResponseInt<List<HomePageMenu>> {
  final api = MenusApi.instance;

  GetHomePageMenusRx({required super.empty, required super.dataFetcher});

  ValueStream<List<HomePageMenu>> get valueStreamData => dataFetcher.stream;

  Future<bool> fetchMenus() async {
    try {
      List<HomePageMenu> data = await api.getHomePageMenus();
      return await handleSuccessWithReturn(data);
    } catch (error) {
      log("fetchMenus Error: $error");
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
