import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';
import '../../provider/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../doctors/doctors_screen.dart';
import '../lab_tests/lab_tests_screen.dart';
import '../prescription/prescription_screen.dart';
import '../product/product_detail_screen.dart';
import '../wholesale/wholesale_screen.dart';

class MedivilaHomeScreen extends StatefulWidget {
  const MedivilaHomeScreen({super.key});

  @override
  State<MedivilaHomeScreen> createState() => _MedivilaHomeScreenState();
}

class _MedivilaHomeScreenState extends State<MedivilaHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (getBootstrapRx.dataFetcher.valueOrNull == null) {
      getBootstrapRx.fetchBootstrap();
    }
    if (getProductsRx.dataFetcher.valueOrNull == null) {
      getProductsRx.fetchProducts();
    }
    if (getLabTestsRx.dataFetcher.valueOrNull == null) {
      getLabTestsRx.fetchLabTests();
    }
    if (getDoctorsRx.dataFetcher.valueOrNull == null) {
      getDoctorsRx.fetchDoctors();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim();
    getProductsRx.fetchProducts(search: q);
    getDoctorsRx.fetchDoctors(search: q);
    getLabTestsRx.fetchLabTests(search: q);
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppToast.info('কল করা যাচ্ছে না: $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  getBootstrapRx.fetchBootstrap(),
                  getProductsRx.fetchProducts(),
                  getLabTestsRx.fetchLabTests(),
                  getDoctorsRx.fetchDoctors(),
                ]);
              },
              child: CustomScrollView(
                slivers: [
                  // 1. Top Green Hotline & Email Header Bar (From Reference Design)
                  SliverToBoxAdapter(child: _buildTopGreenInfoBar()),

                  // 2. Medivila Brand Header & Search Bar
                  SliverToBoxAdapter(child: _buildBrandSearchHeader()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedSearchBarDelegate(
                      height: 60.h,
                      child: _buildSearchBar(),
                    ),
                  ),

                  // 3. Easy Prescription Upload Banner Card
                  SliverToBoxAdapter(child: _buildPrescriptionUploadCard()),

                  // 4. Quick Services Categories (Flash Sale, Doctor, Lab, Wholesale)
                  SliverToBoxAdapter(child: _buildQuickServicesGrid()),

                  // 5. Hero Promo Banner Slider
                  SliverToBoxAdapter(child: _buildHeroBanner()),

                  // 6. Diagnostic Lab Tests Section (Exact Match to User Reference Screenshot)
                  SliverToBoxAdapter(child: _buildLabTestsSection()),

                  // 7. Specialist Doctors Section
                  SliverToBoxAdapter(child: _buildSpecialistDoctorsSection()),

                  // 8. Essential Medicines Grid
                  SliverToBoxAdapter(child: _buildMedicinesSectionTitle()),

                  _buildMedicinesGrid(),

                  // Bottom padding for scroll clearance
                  SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              ),
            ),
          ),

          // 9. Floating Cart Button (Exact Match to Reference Screenshot)
          Positioned(
            right: 0,
            top: 280.h,
            child: _buildFloatingCartButton(cart),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 1. Top Green Info Bar
  Widget _buildTopGreenInfoBar() {
    return Container(
      color: const Color(0xFF009640),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'অনলাইন ফার্মেসি ও স্বাস্থ্যসেবা',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: () => _makeCall(AppConfig.helplinePhone),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.white,
                  size: 13.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  AppConfig.helplinePhone,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 2. Brand & Search Header
  Widget _buildBrandSearchHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(4.w),
                child: Image.asset(
                  AppConfig.logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'মেডিভিলা',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF132B45),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'MEDIVILA PHARMACY',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Support action
          InkWell(
            onTap: () => _makeCall(AppConfig.helplinePhone),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.headset_mic_rounded,
                    size: 14.sp,
                    color: const Color(0xFF132B45),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'সাপোর্ট',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF132B45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: const Color(0xFF9333EA).withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 14.w),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _onSearch,
                onChanged: (val) {
                  setState(() {});
                  if (val.trim().isEmpty) {
                    _onSearch('');
                  }
                },
                style: TextStyle(fontSize: 13.sp, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'ওষুধ, ডাক্তার বা ল্যাব টেস্ট খুঁজুন...',
                  hintStyle: TextStyle(
                    fontSize: 12.5.sp,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16.sp,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearch('');
                },
              ),
            InkWell(
              onTap: () => _onSearch(_searchCtrl.text),
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(24.r),
              ),
              child: Container(
                width: 44.h,
                height: 44.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(22.r),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 3. Prescription Upload Card
  Widget _buildPrescriptionUploadCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007E36), Color(0xFF009640)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009640).withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'প্রেসক্রিপশন দিয়ে অর্ডার করুন',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'ছবি আপলোড করুন, ফার্মাসিস্ট ওষুধ পাঠিয়ে দেবে',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF009640),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              'আপলোড',
              style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 4. Quick Services Grid
  Widget _buildQuickServicesGrid() {
    final services = [
      {
        'title': 'Appointment',
        'sub': 'ডাক্তার বুকিং',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF10B981),
        'route': 'doctor',
      },
      {
        'title': 'Lab Test',
        'sub': 'হোম স্যাম্পল',
        'icon': Icons.science_rounded,
        'color': const Color(0xFF06B6D4),
        'route': 'lab',
      },
      {
        'title': 'Wholesale',
        'sub': 'পাইকারি সাপ্লাই',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': 'wholesale',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: services.map((s) {
          return Expanded(
            child: InkWell(
              onTap: () {
                if (s['route'] == 'doctor') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorsScreen()),
                  );
                } else if (s['route'] == 'lab') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsScreen()),
                  );
                } else if (s['route'] == 'wholesale') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WholesaleScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 24.sp,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      s['title'] as String,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      s['sub'] as String,
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 5. Hero Promo Banner
  Widget _buildHeroBanner() {
    return StreamBuilder<BootstrapData>(
      stream: getBootstrapRx.valueStreamData,
      builder: (context, snapshot) {
        final banners = snapshot.data?.banners ?? const <BannerItem>[];
        if (banners.isEmpty) return const SizedBox.shrink();
        final banner = banners.first;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          height: 140.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFE8F5E9)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF132B45).withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                if (banner.title.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        banner.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── 6. Lab Tests Section (Matching Reference Image)
  Widget _buildLabTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.biotech_rounded,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'জনপ্রিয় ডায়াগনস্টিক ল্যাব টেস্ট',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsScreen()),
                  );
                },
                child: Text(
                  'সবগুলো >',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // StreamBuilder for Lab Tests
        StreamBuilder<List<LabTestModel>>(
          stream: getLabTestsRx.valueStreamData,
          builder: (context, snapshot) {
            final tests = snapshot.data ?? [];
            if (snapshot.hasError) {
              return SizedBox(
                height: 110.h,
                child: TextButton(
                  onPressed: () => getLabTestsRx.fetchLabTests(),
                  child: const Text('ল্যাব টেস্ট লোড হয়নি। আবার চেষ্টা করুন।'),
                ),
              );
            }
            if (tests.isEmpty) {
              if (snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: Text('কোনো ল্যাব টেস্ট পাওয়া যায়নি')),
                );
              }
              return SizedBox(
                height: 110.h,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            return SizedBox(
              height: 142.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                scrollDirection: Axis.horizontal,
                itemCount: tests.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final t = tests[index];
                  return _buildLabTestCard(t);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabTestCard(LabTestModel test) {
    return Container(
      width: 185.w,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        color: const Color(0xFFF1F5F9),
                        child: Image.network(
                          test.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.biotech_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '৳ ${test.discountedPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (test.originalPrice >
                                    test.discountedPrice) ...[
                                  SizedBox(width: 3.w),
                                  Text(
                                    '৳${test.originalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 8.5.sp,
                                      decoration: TextDecoration.lineThrough,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  test.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF132B45),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LabTestsScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Book',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.north_east_rounded,
                    size: 10.sp,
                    color: const Color(0xFF0F172A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 7. Specialist Doctors Section
  Widget _buildSpecialistDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.video_call_rounded,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'বিশেষজ্ঞ ডাক্তারদের সাথে ভিডিও পরামর্শ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorsScreen()),
                  );
                },
                child: Text(
                  'সব ডাক্তার >',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        StreamBuilder<List<DoctorModel>>(
          stream: getDoctorsRx.valueStreamData,
          builder: (context, snapshot) {
            final docs = snapshot.data ?? [];
            if (snapshot.hasError) {
              return TextButton(
                onPressed: () => getDoctorsRx.fetchDoctors(),
                child: const Text('ডাক্তার লোড হয়নি। আবার চেষ্টা করুন।'),
              );
            }
            if (docs.isEmpty) return const SizedBox();

            return SizedBox(
              height: 130.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Container(
                    width: 220.w,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child:
                              (doc.avatar != null &&
                                  doc.avatar!.trim().isNotEmpty &&
                                  !doc.avatar!.contains('placeholder') &&
                                  !doc.avatar!.contains('medivila_logo'))
                              ? Image.network(
                                  doc.avatarUrl,
                                  width: 54.w,
                                  height: 64.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildHomeDoctorPlaceholder(),
                                )
                              : _buildHomeDoctorPlaceholder(),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                doc.formattedName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                doc.displaySpeciality,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                doc.displayExperience,
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'ফি: ৳ ${doc.effectiveFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF009640),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeDoctorPlaceholder() {
    return Container(
      width: 54.w,
      height: 64.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.medical_services_rounded,
          color: AppColors.primary,
          size: 28.sp,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 8. Medicines Section
  Widget _buildMedicinesSectionTitle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.medication_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'প্রয়োজনীয় মেডিসিন ও হেলথকেয়ার',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '১০০% জেনুইন',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesGrid() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 180.h,
              child: Center(
                child: TextButton(
                  onPressed: () => getProductsRx.fetchProducts(),
                  child: const Text('পণ্য লোড হয়নি। আবার চেষ্টা করুন।'),
                ),
              ),
            ),
          );
        }
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 180.h,
              child: Center(
                child: snapshot.hasData
                    ? const Text('কোনো পণ্য পাওয়া যায়নি')
                    : const CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final p = products[index];
              return _buildMedicineCard(p);
            }, childCount: products.length),
          ),
        );
      },
    );
  }

  Widget _buildMedicineCard(MedicineProduct p) {
    final cart = context.read<CartProvider>();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14.r),
                  ),
                  child: Container(
                    height: 115.h,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    child: Image.network(
                      p.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.medication_liquid_rounded,
                          size: 40.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (p.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${p.discountPercentage}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (p.requiresPrescription)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF132B45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 10.sp,
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  if (p.genericName != null)
                    Text(
                      p.genericName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  SizedBox(height: 6.h),

                  // Price
                  Row(
                    children: [
                      Text(
                        '৳ ${p.effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF009640),
                        ),
                      ),
                      if (p.hasDiscount) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '৳${p.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 32.h,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.addMedicine(p);
                        AppToast.success('কার্টে যোগ করা হয়েছে: ${p.name}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009640),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 13.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'অর্ডার করুন',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 9. Floating Cart Button (Exact Reference Match)
  Widget _buildFloatingCartButton(CartProvider cart) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF009640),
          borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF009640).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(-2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Green Half
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${cart.count} items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Black/Dark Half
            Container(
              width: 52.w,
              padding: EdgeInsets.symmetric(vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.r),
                ),
              ),
              child: Center(
                child: Text(
                  '৳${cart.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5.sp,
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

class _PinnedSearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedSearchBarDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_PinnedSearchBarDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}
