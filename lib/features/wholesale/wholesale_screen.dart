import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../models/medivila_models.dart';
import '../../networks/medivila_api_services.dart';

class WholesaleScreen extends StatefulWidget {
  const WholesaleScreen({super.key});

  @override
  State<WholesaleScreen> createState() => _WholesaleScreenState();
}

class _WholesaleScreenState extends State<WholesaleScreen> {
  List<WholesaleProduct> _products = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadWholesale();
  }

  Future<void> _loadWholesale() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final list = await WholesaleApi.instance.getWholesaleProducts();
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = [];
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'পাইকারি (B2B) ঔষধ সরবরাহ',
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _loadFailed
          ? Center(
              child: TextButton(
                onPressed: _loadWholesale,
                child: const Text('পণ্য লোড হয়নি। আবার চেষ্টা করুন।'),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // B2B Wholesale Banner Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF132B45), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'ফার্মেসি ও ক্লিনিক হোলসেল সাপ্লাই',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'ড্রাগ লাইসেন্সধারী ফার্মেসির জন্য সরাসরি প্রস্তুতকারকের রেটে ওষুধ সরবরাহ। বিশেষ ক্যাশব্যাক ও ক্রেডিট সুবিধা।',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () => _openApplicationModal(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: const Text(
                            'হোলসেল একাউন্টের আবেদন করুন',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),

                  Text(
                    'হোলসেল মেডিসিন রেট চার্ট:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'সর্বনিম্ন পরিমাণ: ${p.minQty} বক্স',
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'মুনাফা মার্জিন: ${p.marginPct}%',
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'পাইকারি দর:',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '৳ ${p.calculatedWholesalePrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'এমআরপি: ৳${p.mrp.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void _openApplicationModal() {
    final businessCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final drugLicenseCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
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
                    'হোলসেল পার্টনারশিপ আবেদন',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: businessCtrl,
                decoration: InputDecoration(
                  labelText: 'ফার্মেসি / প্রতিষ্ঠানের নাম',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: ownerCtrl,
                decoration: InputDecoration(
                  labelText: 'মালিকের নাম',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'যোগাযোগ নম্বর',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: drugLicenseCtrl,
                decoration: InputDecoration(
                  labelText: 'ড্রাগ লাইসেন্স নম্বর (DGDA)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () async {
                    if (businessCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      AppToast.error('প্রতিষ্ঠানের নাম এবং ফোন নম্বর আবশ্যক');
                      return;
                    }
                    final res = await WholesaleApi.instance.submitApplication({
                      'business_name': businessCtrl.text.trim(),
                      'owner_name': ownerCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'drug_license': drugLicenseCtrl.text.trim(),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      AppToast.success(res['message'] ?? 'আবেদন গৃহীত হয়েছে!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: const Text(
                    'আবেদন জমা দিন',
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
      ),
    );
  }
}
