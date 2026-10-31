import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common_wigdets/medivila_product_card.dart';
import '../../constants/app_colors.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';
import '../doctors/doctor_booking_screen.dart';
import '../doctors/doctors_screen.dart';
import '../lab_tests/lab_tests_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedFilter = 0; // 0 = Products, 1 = Lab Tests, 2 = Doctors

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _executeSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    final q = query.trim();
    getProductsRx.fetchProducts(search: q);
    getLabTestsRx.fetchLabTests(search: q);
    getDoctorsRx.fetchDoctors(search: q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'অনুসন্ধান (Search)',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Magenta Search Bar (Exact match to Image 1 & 3)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFFD81B60), // Magenta border
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  Icon(
                    Icons.search_rounded,
                    color: const Color(0xFFD81B60),
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: widget.initialQuery.isEmpty,
                      onSubmitted: _executeSearch,
                      onChanged: (val) {
                        setState(() {});
                        if (val.trim().isEmpty) {
                          _executeSearch('');
                        }
                      },
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'পণ্য কোড বা নাম লিখুন',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF757575),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _executeSearch('');
                      },
                    ),
                  InkWell(
                    onTap: () => _executeSearch(_searchCtrl.text),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6.5.r),
                    ),
                    child: Container(
                      width: 48.w,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD81B60),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(6.5.r),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Segmented Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Row(
              children: [
                _buildFilterChip(0, 'ওষুধ ও পণ্য'),
                SizedBox(width: 8.w),
                _buildFilterChip(1, 'ল্যাব টেস্ট'),
                SizedBox(width: 8.w),
                _buildFilterChip(2, 'ডাক্তার'),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Results View
          Expanded(
            child: _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = index),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_selectedFilter == 0) {
      // Products
      return StreamBuilder<List<MedicineProduct>>(
        stream: getProductsRx.valueStreamData,
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (products.isEmpty) {
            return _buildEmptyState('কোনো পণ্য পাওয়া যায়নি');
          }

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return MedivilaProductCard(product: products[index]);
            },
          );
        },
      );
    } else if (_selectedFilter == 1) {
      // Lab Tests
      return StreamBuilder<List<LabTestModel>>(
        stream: getLabTestsRx.valueStreamData,
        builder: (context, snapshot) {
          final tests = snapshot.data ?? [];
          if (tests.isEmpty) {
            return _buildEmptyState('কোনো ল্যাব টেস্ট পাওয়া যায়নি');
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            itemCount: tests.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final t = tests[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: const Icon(Icons.biotech_rounded, color: AppColors.primary),
                title: Text(t.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                subtitle: Text('৳${t.discountedPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsScreen()),
                  );
                },
              );
            },
          );
        },
      );
    } else {
      // Doctors
      return StreamBuilder<List<DoctorModel>>(
        stream: getDoctorsRx.valueStreamData,
        builder: (context, snapshot) {
          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return _buildEmptyState('কোনো ডাক্তার পাওয়া যায়নি');
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            itemCount: doctors.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final d = doctors[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                title: Text(d.name, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold)),
                subtitle: Text(d.specialityTitle, style: const TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorBookingScreen(doctor: d),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48.sp, color: const Color(0xFF94A3B8)),
          SizedBox(height: 10.h),
          Text(
            msg,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
