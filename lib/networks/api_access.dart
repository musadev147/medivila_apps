import 'package:rxdart/subjects.dart';
import '../models/medivila_models.dart';
import 'medivila_rx.dart';

final GetBootstrapRx getBootstrapRx = GetBootstrapRx(
  empty: BootstrapData(),
  dataFetcher: BehaviorSubject<BootstrapData>(),
);

final GetProductsRx getProductsRx = GetProductsRx(
  empty: [],
  dataFetcher: BehaviorSubject<List<MedicineProduct>>(),
);

final GetDoctorsRx getDoctorsRx = GetDoctorsRx(
  empty: [],
  dataFetcher: BehaviorSubject<List<DoctorModel>>(),
);

final GetLabTestsRx getLabTestsRx = GetLabTestsRx(
  empty: [],
  dataFetcher: BehaviorSubject<List<LabTestModel>>(),
);
