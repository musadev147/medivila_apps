import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';
import '../../networks/medivila_api_services.dart';

class LabTestsScreen extends StatefulWidget {
  const LabTestsScreen({super.key});

  @override
  State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (getLabTestsRx.dataFetcher.valueOrNull == null) {
      getLabTestsRx.fetchLabTests();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ডায়াগনস্টিক ল্যাব টেস্ট ও হোম স্যাম্পল',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<LabTestModel>>(
              stream: getLabTestsRx.valueStreamData,
              builder: (context, snapshot) {
                final allTests = snapshot.data ?? [];
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => getLabTestsRx.fetchLabTests(
                        search: _searchQuery.isEmpty ? null : _searchQuery,
                      ),
                      child: const Text(
                        'ল্যাব টেস্ট লোড হয়নি। আবার চেষ্টা করুন।',
                      ),
                    ),
                  );
                }
                if (allTests.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final tests = _searchQuery.isEmpty
                    ? allTests
                    : allTests.where((t) {
                        final q = _searchQuery.toLowerCase();
                        return t.name.toLowerCase().contains(q) ||
                            t.sampleType.toLowerCase().contains(q) ||
                            (t.description?.toLowerCase().contains(q) ??
                                false) ||
                            (t.preparationNotes?.toLowerCase().contains(q) ??
                                false) ||
                            t.reportTime.toLowerCase().contains(q);
                      }).toList();

                if (tests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.biotech_rounded,
                            size: 56.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'কোনো ল্যাব টেস্ট পাওয়া যায়নি',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '"$_searchQuery" সম্পর্কিত কোনো টেস্ট পাওয়া যায়নি।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          OutlinedButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              getLabTestsRx.fetchLabTests();
                            },
                            child: const Text('অনুসন্ধান রিসেট করুন'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(14.w),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final test = tests[index];
                    return _buildLabTestCard(test);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 8.h),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                  getLabTestsRx.fetchLabTests(search: val.trim());
                },
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'ল্যাব টেস্টের নাম বা স্যাম্পলের ধরন খুঁজুন...',
                  hintStyle: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16.sp,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                  getLabTestsRx.fetchLabTests();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabTestCard(LabTestModel test) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  color: const Color(0xFFF1F5F9),
                  child: Image.network(
                    test.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8F5E9),
                      child: Center(
                        child: Icon(
                          Icons.biotech_rounded,
                          color: AppColors.primary,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _buildInfoTag(
                          Icons.water_drop_outlined,
                          test.sampleType,
                        ),
                        SizedBox(width: 6.w),
                        _buildInfoTag(Icons.timer_outlined, test.reportTime),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (test.preparationNotes != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      test.preparationNotes!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '৳ ${test.discountedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF009640),
                    ),
                  ),
                  if (test.originalPrice > test.discountedPrice) ...[
                    SizedBox(width: 6.w),
                    Text(
                      '৳${test.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        decoration: TextDecoration.lineThrough,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
              if (test.isHomeCollection)
                ElevatedButton.icon(
                  onPressed: () => _openHomeCollectionModal(test),
                  icon: Icon(Icons.home_work_outlined, size: 15.sp),
                  label: Text(
                    'হোম স্যাম্পল বুক করুন',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: AppColors.textMuted),
          SizedBox(width: 3.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5.sp,
              color: AppColors.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openHomeCollectionModal(LabTestModel test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _LabBookingSheet(test: test),
    );
  }
}

class _LabBookingSheet extends StatefulWidget {
  const _LabBookingSheet({required this.test});
  final LabTestModel test;

  @override
  State<_LabBookingSheet> createState() => _LabBookingSheetState();
}

class _LabBookingSheetState extends State<_LabBookingSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _timeSlot = 'সকাল (8 AM - 11 AM)';
  bool _submitting = false;

  Future<void> _submitBooking() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.error('রোগীর নাম লিখুন');
      return;
    }
    if (!AppConfig.isValidBdPhone(_phoneCtrl.text.trim())) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন');
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      AppToast.error('স্যাম্পল সংগ্রহের ঠিকানা লিখুন');
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = {
        'patient_name': _nameCtrl.text.trim(),
        'patient_phone': AppConfig.cleanBdPhone(_phoneCtrl.text.trim()),
        'patient_address': _addressCtrl.text.trim(),
        'time_slot': _timeSlot,
        'lab_test_id': widget.test.id,
        'lab_test_name': widget.test.name,
      };

      final res = await LabTestsApi.instance.bookHomeLab(payload);
      setState(() => _submitting = false);

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'বুকিং সফল হয়েছে!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              res['message'] ?? 'আমাদের মেডিকেল টেকনোলজিস্ট নির্দিষ্ট সময়ে স্যাম্পল সংগ্রহ করতে উপস্থিত হবেন।',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ঠিক আছে'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'হোম স্যাম্পল কালেকশন রিকোয়েস্ট',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              widget.test.name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12.h),

            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'রোগীর নাম',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'মোবাইল নম্বর',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: 'স্যাম্পল সংগ্রহের বিস্তারিত ঠিকানা',
                hintText: 'বাসা নং, রোড, এরিয়া, ঢাকা',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Pricing Summary
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'টেস্ট ফি + হোম কালেকশন ফি (৳১০০):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '৳ ${(widget.test.discountedPrice + 100).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'বুকিং সম্পন্ন করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
