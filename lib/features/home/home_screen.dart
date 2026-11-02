import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_wigdets/app_toast.dart';
import '../../common_wigdets/auth_bottom_sheet.dart';
import '../../common_wigdets/brand_logo.dart';
import '../../common_wigdets/medivila_drawer.dart';
import '../../common_wigdets/medivila_product_card.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';
import '../../provider/auth_provider.dart';
import '../lab_tests/lab_tests_screen.dart';
import '../prescription/prescription_screen.dart';
import '../profile/profile_screen.dart';

class MedivilaHomeScreen extends StatefulWidget {
  const MedivilaHomeScreen({super.key});

  @override
  State<MedivilaHomeScreen> createState() => _MedivilaHomeScreenState();
}

class _MedivilaHomeScreenState extends State<MedivilaHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _bannerPageController = PageController();

  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  int? _selectedCategoryId;
  int? _selectedRootCategoryId;
  String _selectedCategoryName = 'Sergical & Ortho Care';

  int _productsVisibleLimit = 10;

  @override
  void initState() {
    super.initState();
    if (getBootstrapRx.dataFetcher.valueOrNull == null) {
      getBootstrapRx.fetchBootstrap();
    }
    if (getCategoriesRx.dataFetcher.valueOrNull == null) {
      getCategoriesRx.fetchCategories();
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

    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_bannerPageController.hasClients) return;
      final banners = getBootstrapRx.dataFetcher.valueOrNull?.banners ?? [];
      final count = banners.isEmpty ? 3 : banners.length;
      final nextPage = (_currentBannerIndex + 1) % count;
      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim();
    getProductsRx.fetchProducts(
      categoryId: _selectedCategoryId,
      search: q.isNotEmpty ? q : null,
    );
  }

  void _onCategorySelected(CategoryItem? cat, String? title) {
    setState(() {
      _selectedCategoryId = cat?.id;
      _selectedRootCategoryId = cat == null ? null : cat.parentId ?? cat.id;
      _selectedCategoryName = title ?? cat?.displayName ?? 'All Products';
      _productsVisibleLimit = 10;
    });
    getProductsRx.fetchProducts(
      categoryId: cat?.id,
      search: _searchCtrl.text.trim().isNotEmpty
          ? _searchCtrl.text.trim()
          : null,
    );
  }

  List<CategoryItem> _subcategoriesFor(
    CategoryItem category,
    List<CategoryItem> categories,
  ) {
    final subcategories = <int, CategoryItem>{
      for (final child in category.children) child.id: child,
      for (final child in categories)
        if (child.parentId == category.id) child.id: child,
    };
    return subcategories.values.toList();
  }

  void _selectCategoryFilter(CategoryItem category) {
    setState(() {
      _selectedCategoryId = category.id;
      _selectedCategoryName = category.displayName;
      _productsVisibleLimit = 10;
    });
    getProductsRx.fetchProducts(
      categoryId: category.id,
      search: _searchCtrl.text.trim().isNotEmpty
          ? _searchCtrl.text.trim()
          : null,
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppToast.info('কল করা যাচ্ছে না: $phone');
    }
  }

  Future<void> _openWhatsApp() async {
    final cleanPhone = AppConfig.cleanBdPhone(AppConfig.helplinePhone);
    final rawNumber =
        cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone;
    final uri = Uri.parse(
      'https://wa.me/880$rawNumber?text=${Uri.encodeComponent('হ্যালো মেডিভিলা, আমার কিছু তথ্য প্রয়োজন।')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppToast.error('WhatsApp ওপেন করা যাচ্ছে না');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: MedivilaDrawer(onSelectCategory: _onCategorySelected),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar (Hamburger menu, Medivila Bengali Logo, User Profile)
            _buildTopAppBar(),

            // 2. Magenta Search Bar (Pinned at top - Image 1 & 3)
            _buildMagentaSearchBar(),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    getBootstrapRx.fetchBootstrap(),
                    getCategoriesRx.fetchCategories(),
                    getProductsRx.fetchProducts(
                      categoryId: _selectedCategoryId,
                    ),
                    getLabTestsRx.fetchLabTests(),
                    getDoctorsRx.fetchDoctors(),
                  ]);
                },
                child: CustomScrollView(
                  slivers: [
                    // 3. Banner Carousel Slider (Winter Sale / Promos)
                    SliverToBoxAdapter(child: _buildBannerCarousel()),

                    SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                    // 4. Diagnostic Lab Tests Horizontal Cards (Exact Match to Image 3)
                    SliverToBoxAdapter(
                      child: _buildDiagnosticLabTestsSection(),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                    // 5. "Especially For You" Section (Image 3)
                    SliverToBoxAdapter(child: _buildEspeciallyForYouSection()),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // 6. "Shop by Category" Section (Image 3)
                    SliverToBoxAdapter(child: _buildShopByCategorySection()),

                    SliverToBoxAdapter(child: _buildSubcategorySelector()),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // 7. Category Products Header (Image 1: Green underline + count)
                    SliverToBoxAdapter(child: _buildCategorySectionHeader()),

                    // 8. 2-Column Product Grid (Image 1)
                    _buildProductGridSliver(),

                    // 9. Load More Button (Image 1: "Load More (10 of 22)")
                    SliverToBoxAdapter(child: _buildLoadMoreButton()),

                    // Space for bottom clearance above navigation bar
                    SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 1. Top App Bar
  Widget _buildTopAppBar() {
    final auth = context.watch<AuthProvider>();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger Menu Icon Button (Image 1, 2, 3)
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            borderRadius: BorderRadius.circular(22.r),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),

          // Center: Medivila Bengali Logo (Image 1, 2, 3)
          const BrandLogo(height: 36),

          // Right: User Profile Icon Button (Image 1, 3)
          InkWell(
            onTap: () {
              if (auth.loggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else {
                showAuthModal(context);
              }
            },
            borderRadius: BorderRadius.circular(22.r),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 2. Magenta Search Bar
  Widget _buildMagentaSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 8.h),
      child: Container(
        height: 46.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFFD81B60), // Magenta border (Image 1, 3)
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),
            // Left Magenta Search Icon
            Icon(
              Icons.search_rounded,
              color: const Color(0xFFD81B60),
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            // Search Input
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
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearch('');
                },
              ),
            // Right Solid Magenta Button with White Search Icon (Image 1, 3)
            InkWell(
              onTap: () => _onSearch(_searchCtrl.text),
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
    );
  }

  // ───────────────────────────────────────────────────────── 3. Banner Carousel Slider
  Widget _buildBannerCarousel() {
    return StreamBuilder<BootstrapData>(
      stream: getBootstrapRx.valueStreamData,
      builder: (context, snapshot) {
        final banners = snapshot.data?.banners ?? [];
        final bannerList = banners.isNotEmpty
            ? banners.map((b) => b.imageUrl).toList()
            : [
                'https://api.medivila.com/storage/banners/winter-sale.jpg',
                'https://api.medivila.com/storage/banners/promo-2.jpg',
              ];

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w),
          height: 150.h,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: PageView.builder(
                  controller: _bannerPageController,
                  onPageChanged: (idx) {
                    setState(() => _currentBannerIndex = idx);
                  },
                  itemCount: bannerList.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      bannerList[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _buildFallbackBanner(),
                    );
                  },
                ),
              ),

              // Left Arrow Button (<)
              Positioned(
                left: 8.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      final prevPage = _currentBannerIndex > 0
                          ? _currentBannerIndex - 1
                          : bannerList.length - 1;
                      _bannerPageController.animateToPage(
                        prevPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right Arrow Button (>)
              Positioned(
                right: 8.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      final nextPage =
                          (_currentBannerIndex + 1) % bannerList.length;
                      _bannerPageController.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Dots Indicator (Image 3)
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    bannerList.length,
                    (i) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      width: _currentBannerIndex == i ? 14.w : 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == i
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'কোমল, নরম এবং উজ্জ্বল...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF854D0E),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Winter SALE',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.spa_rounded,
            size: 50.sp,
            color: const Color(0xFF0F766E).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 4. Diagnostic Lab Tests Section (Exact match to Image 3)
  Widget _buildDiagnosticLabTestsSection() {
    return StreamBuilder<List<LabTestModel>>(
      stream: getLabTestsRx.valueStreamData,
      builder: (context, snapshot) {
        final tests = snapshot.data ?? _fallbackLabTests;
        if (tests.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 124.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
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
    );
  }

  Widget _buildLabTestCard(LabTestModel test) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LabTestsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 220.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBF7), // Mint background (Image 3)
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: "HOME" tag and Price Box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HOME',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '৳ ${test.discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (test.originalPrice > test.discountedPrice) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '৳${test.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFFEF4444),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Middle: Test Name
            Text(
              test.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),

            // Bottom: "Book Now ↗" button and kit thumbnail
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.north_east_rounded,
                        size: 11.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Image.network(
                    test.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.biotech_rounded,
                      color: Color(0xFF009640),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 5. "Especially For You" Section
  Widget _buildEspeciallyForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Especially For You',
            style: TextStyle(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<List<CategoryItem>>(
          stream: getCategoriesRx.valueStreamData,
          builder: (context, snapshot) {
            final rawCategories = (snapshot.data ?? _defaultCategories)
                .where((category) => category.parentId == null)
                .toList();

            // Find HealthCare category or fallback to default
            CategoryItem? healthCareCat;
            for (final c in rawCategories) {
              final n = c.name.toLowerCase();
              final s = c.slug.toLowerCase();
              if (n.contains('health') || s.contains('health')) {
                healthCareCat = c;
                break;
              }
            }
            healthCareCat ??= (rawCategories.isNotEmpty
                ? rawCategories.first
                : _defaultCategories.first);

            // Remaining categories (excluding HealthCare to avoid duplicate)
            final otherCategories = rawCategories
                .where((c) =>
                    c.id != healthCareCat!.id && c.slug != healthCareCat.slug)
                .toList();

            // Order matching design:
            // 0: Whats App
            // 1: Call Now
            // 2: HealthCare
            // 3: Upload Prescription
            // 4+: Other categories
            final totalCount = 4 + otherCategories.length;

            return SizedBox(
              height: 185.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                scrollDirection: Axis.horizontal,
                itemCount: totalCount,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  // 1. Whats App
                  if (index == 0) {
                    return _buildSpecialCard(
                      title: 'Whats App',
                      subtitle: '5% Discount',
                      buttonText: 'Call Now',
                      themeColor: const Color(0xFFD68A2E),
                      badgeBgColor: const Color(0xFF25D366),
                      iconWidget: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 19.sp,
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: Icon(
                              Icons.phone_rounded,
                              color: const Color(0xFF25D366),
                              size: 9.sp,
                            ),
                          ),
                        ],
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFAF1E4), Color(0xFFD98E32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: _openWhatsApp,
                    );
                  }

                  // 2. Call Now
                  if (index == 1) {
                    return _buildSpecialCard(
                      title: 'Call Now',
                      subtitle: '2% Discount',
                      extraLine: AppConfig.helplinePhone,
                      buttonText: 'Call Now',
                      themeColor: const Color(0xFFE8751A),
                      badgeBgColor: Colors.white,
                      iconWidget: Icon(
                        Icons.phone_rounded,
                        color: const Color(0xFF10B981),
                        size: 19.sp,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDF0E2), Color(0xFFE8751A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _makeCall(AppConfig.helplinePhone),
                    );
                  }

                  // 3. HealthCare
                  if (index == 2) {
                    return _buildSpecialCard(
                      title: healthCareCat!.displayName,
                      subtitle: 'Upto 60% Discount',
                      buttonText: 'Click Here',
                      themeColor: const Color(0xFF0891B2),
                      badgeBgColor: const Color(0xFF0891B2),
                      iconWidget: Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.white,
                        size: 19.sp,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F7F8), Color(0xFF26B6C6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _onCategorySelected(
                        healthCareCat,
                        healthCareCat!.displayName,
                      ),
                    );
                  }

                  // 4. Upload Prescription
                  if (index == 3) {
                    return _buildSpecialCard(
                      title: 'Upload Prescription',
                      subtitle: '7% Discount',
                      buttonText: 'Upload',
                      themeColor: const Color(0xFF0891B2),
                      badgeBgColor: const Color(0xFF0891B2),
                      iconWidget: Icon(
                        Icons.assignment_rounded,
                        color: Colors.white,
                        size: 19.sp,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F7F8), Color(0xFF26B6C6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrescriptionScreen(),
                          ),
                        );
                      },
                    );
                  }

                  // 5+. Other Categories
                  final category = otherCategories[index - 4];
                  return _buildSpecialCard(
                    title: category.displayName,
                    subtitle: 'Upto 60% Discount',
                    buttonText: 'Click Here',
                    themeColor: const Color(0xFF0891B2),
                    badgeBgColor: const Color(0xFF0891B2),
                    iconWidget: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 19.sp,
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6F7F8), Color(0xFF26B6C6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () =>
                        _onCategorySelected(category, category.displayName),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpecialCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required Color themeColor,
    required Color badgeBgColor,
    required Widget iconWidget,
    required LinearGradient gradient,
    required VoidCallback onTap,
    String? extraLine,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: 230.w,
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Title + Circular Icon Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h, right: 6.w),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: iconWidget,
                  ),
                ),
              ],
            ),

            // Middle Subtitle & Extra Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.25,
                  ),
                ),
                if (extraLine != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    extraLine,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ],
            ),

            // Bottom White Pill Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 6. "Shop by Category" Section (Image 3)
  Widget _buildShopByCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        StreamBuilder<List<CategoryItem>>(
          stream: getCategoriesRx.valueStreamData,
          builder: (context, snapshot) {
            final categories = (snapshot.data ?? _defaultCategories)
                .where((category) => category.parentId == null)
                .toList();
            return SizedBox(
              height: 112.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedRootCategoryId == cat.id;

                  return InkWell(
                    onTap: () => _onCategorySelected(cat, cat.displayName),
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 78.w,
                      child: Column(
                        children: [
                          Container(
                            width: 68.w,
                            height: 68.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13.r),
                              child: Image.network(
                                cat.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    color: AppColors.primary,
                                    size: 28.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            cat.displayName,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF1E293B),
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSubcategorySelector() {
    return StreamBuilder<List<CategoryItem>>(
      stream: getCategoriesRx.valueStreamData,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? _defaultCategories;
        CategoryItem? selectedRoot;
        for (final category in categories) {
          if (category.id == _selectedRootCategoryId) {
            selectedRoot = category;
            break;
          }
        }
        if (selectedRoot == null) return const SizedBox.shrink();

        final subcategories = _subcategoriesFor(selectedRoot, categories);
        if (subcategories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 48.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            scrollDirection: Axis.horizontal,
            itemCount: subcategories.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final category = index == 0
                  ? selectedRoot!
                  : subcategories[index - 1];
              final isSelected = _selectedCategoryId == category.id;
              return ChoiceChip(
                label: Text(category.displayName),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => _selectCategoryFilter(category),
              );
            },
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── 7. Category Products Header (Image 1)
  Widget _buildCategorySectionHeader() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final count = products.length;

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Category Title with Green underline accent bar (Exact Match to Image 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategoryName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 38.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF009640),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),

              // Product count in green text (e.g., "26 products" in Image 1)
              Text(
                '$count products',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF009640),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── 8. 2-Column Product Grid (Image 1)
  Widget _buildProductGridSliver() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? _fallbackProducts;

        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (allProducts.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 30.h),
              alignment: Alignment.center,
              child: Text(
                'কোনো পণ্য পাওয়া যায়নি',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
              ),
            ),
          );
        }

        final visibleCount = allProducts.length < _productsVisibleLimit
            ? allProducts.length
            : _productsVisibleLimit;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = allProducts[index];
              return MedivilaProductCard(product: product);
            }, childCount: visibleCount),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── 9. Load More Button (Image 1)
  Widget _buildLoadMoreButton() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final total = (snapshot.data ?? _fallbackProducts).length;
        if (total <= _productsVisibleLimit) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _productsVisibleLimit += 10;
                });
              },
              borderRadius: BorderRadius.circular(25.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF009640), // Green pill (Image 1)
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF009640).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Load More ($_productsVisibleLimit of $total)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Fallback diagnostic lab tests matching Image 3
  static final List<LabTestModel> _fallbackLabTests = [
    LabTestModel(
      id: 1,
      slug: 'pbf-peripheral-blood-film',
      name: 'PBF (Peripheral Blood Film)',
      originalPrice: 500.0,
      discountedPrice: 300.0,
      image: 'https://api.medivila.com/storage/lab/pbf.jpg',
    ),
    LabTestModel(
      id: 2,
      slug: 'hb-hemoglobin',
      name: '(HB%) Hemoglobin',
      originalPrice: 300.0,
      discountedPrice: 200.0,
      image: 'https://api.medivila.com/storage/lab/hb.jpg',
    ),
  ];

  // Fallback default categories matching Image 3
  static final List<CategoryItem> _defaultCategories = [
    CategoryItem(
      id: 1,
      name: 'HealthCare',
      bnName: 'HealthCare',
      slug: 'healthcare',
      image:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
    ),
    CategoryItem(
      id: 2,
      name: 'Baby & Mom Care',
      bnName: 'Baby & Mom Care',
      slug: 'baby-mom-care',
      image: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=200',
    ),
    CategoryItem(
      id: 3,
      name: 'Sergical & Ortho Care',
      bnName: 'Sergical & Ortho Care',
      slug: 'sergical-ortho-care',
      image:
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=200',
    ),
    CategoryItem(
      id: 4,
      name: 'Lab Test',
      bnName: 'Lab Test',
      slug: 'lab-test',
      image:
          'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=200',
    ),
    CategoryItem(
      id: 5,
      name: 'Natural & Nutritional',
      bnName: 'Natural & Nutritional',
      slug: 'natural-nutritional',
      image:
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=200',
    ),
  ];

  // Fallback products matching Image 1
  static final List<MedicineProduct> _fallbackProducts = [
    MedicineProduct(
      id: 101,
      slug: 'mesh-nebulizer-portable-with-battery',
      name: 'Mesh Nebulizer Portable With Battery',
      price: 1050.0,
      discountPrice: 600.0,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
      ],
    ),
    MedicineProduct(
      id: 102,
      slug: 'th-compressor-nebulizer-hs-308',
      name: 'T&H Compressor Nebulizer(HS-308)',
      price: 4680.0,
      discountPrice: 2500.0,
      images: [
        'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=300',
      ],
    ),
  ];
}
