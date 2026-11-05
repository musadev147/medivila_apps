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
import '../../networks/medivila_api_services.dart';
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

  // Search placeholder cycling animation (matches HeaderSearchBar.jsx)
  final List<String> _searchPlaceholders = const [
    'আপনি কি খুঁজতে চান?',
    'পণ্যের নাম লিখুন...',
    'ব্র্যান্ড বা ক্যাটাগরি সার্চ করুন',
    'সেরা অফার খুঁজুন...',
    'পণ্য কোড বা নাম লিখুন',
  ];
  int _currentPlaceholderIndex = 0;
  Timer? _placeholderTimer;

  int? _selectedCategoryId;
  int? _selectedRootCategoryId;
  String _selectedCategoryName = '';

  int _productsVisibleLimit = 10;

  @override
  void initState() {
    super.initState();

    // Bootstrap app data
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
    if (getOffersRx.dataFetcher.valueOrNull == null) {
      getOffersRx.fetchOffers();
    }
    if (getHomePageMenusRx.dataFetcher.valueOrNull == null) {
      getHomePageMenusRx.fetchMenus();
    }

    _startBannerTimer();
    _startPlaceholderTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerPageController.hasClients) return;
      final banners = getBootstrapRx.dataFetcher.valueOrNull?.banners ?? [];
      final count = banners.isEmpty ? 2 : banners.length;
      final nextPage = (_currentBannerIndex + 1) % count;
      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _startPlaceholderTimer() {
    _placeholderTimer?.cancel();
    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentPlaceholderIndex =
              (_currentPlaceholderIndex + 1) % _searchPlaceholders.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    _placeholderTimer?.cancel();
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
      search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
    );
  }

  void _clearCategorySelection() {
    setState(() {
      _selectedCategoryId = null;
      _selectedRootCategoryId = null;
      _selectedCategoryName = '';
      _productsVisibleLimit = 10;
    });
    getProductsRx.fetchProducts(
      categoryId: null,
      search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
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
      search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
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

  Future<void> _openWhatsApp(String? targetUrl) async {
    final cleanPhone = AppConfig.cleanBdPhone(AppConfig.helplinePhone);
    final rawNumber =
        cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone;
    final fallbackUrl =
        'https://wa.me/880$rawNumber?text=${Uri.encodeComponent('হ্যালো মেডিভিলা, আমার কিছু তথ্য প্রয়োজন।')}';
    final url = (targetUrl != null && targetUrl.isNotEmpty) ? targetUrl : fallbackUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppToast.error('WhatsApp ওপেন করা যাচ্ছে না');
    }
  }

  void _handleOfferClick(OfferItem offer) {
    final link = (offer.buttonLink ?? '').trim();
    if (link == 'prescription' || link.contains('prescription')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
      );
      return;
    }
    if (link.startsWith('http://') || link.startsWith('https://')) {
      if (link.contains('wa.me') || link.contains('whatsapp')) {
        _openWhatsApp(link);
      } else {
        final uri = Uri.parse(link);
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    if (link.startsWith('tel:')) {
      _makeCall(link.replaceFirst('tel:', ''));
      return;
    }
    // Check if category link
    if (link.contains('category/')) {
      final slug = link.split('category/').last.replaceAll('/', '');
      final categories = getCategoriesRx.dataFetcher.valueOrNull ?? [];
      CategoryItem? matched;
      for (final c in categories) {
        if (c.slug == slug || '${c.id}' == slug) {
          matched = c;
          break;
        }
      }
      if (matched != null) {
        _onCategorySelected(matched, matched.displayName);
      }
      return;
    }

    // Default by title
    final lower = offer.title.toLowerCase();
    if (lower.contains('prescription')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
      );
    } else if (lower.contains('whatsapp')) {
      _openWhatsApp(null);
    } else if (lower.contains('call')) {
      _makeCall(AppConfig.helplinePhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCategorySelected = _selectedCategoryId != null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: MedivilaDrawer(onSelectCategory: _onCategorySelected),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Hamburger menu, Medivila Bengali Logo, User Profile
            _buildTopAppBar(),

            // 2. Animated Emerald Search Bar (matches HeaderSearchBar.jsx)
            _buildEmeraldSearchBar(),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    getBootstrapRx.fetchBootstrap(),
                    getCategoriesRx.fetchCategories(),
                    getProductsRx.fetchProducts(categoryId: _selectedCategoryId),
                    getLabTestsRx.fetchLabTests(),
                    getDoctorsRx.fetchDoctors(),
                    getOffersRx.fetchOffers(),
                    getHomePageMenusRx.fetchMenus(),
                  ]);
                },
                child: CustomScrollView(
                  slivers: [
                    // When category is selected: Breadcrumb Navigation
                    if (isCategorySelected)
                      SliverToBoxAdapter(child: _buildCategoryBreadcrumb()),

                    // Home View: Banner Carousel Slider
                    if (!isCategorySelected) ...[
                      SliverToBoxAdapter(child: _buildBannerCarousel()),
                      SliverToBoxAdapter(child: SizedBox(height: 14.h)),

                      // Diagnostic Lab Tests Horizontal Cards (matches LabTest.jsx)
                      SliverToBoxAdapter(child: _buildDiagnosticLabTestsSection()),
                      SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                      // "Especially For You" Dynamic Offers (matches SpecialForYou.jsx)
                      SliverToBoxAdapter(child: _buildEspeciallyForYouSection()),
                      SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                      // "Shop by Category" Section (matches CategoryShowcase.jsx)
                      SliverToBoxAdapter(child: _buildShopByCategorySection()),
                      SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                      // Dynamic Homepage Category Sections (matches HomeCategorySections.jsx)
                      _buildHomePageCategorySectionsSliver(),
                    ],

                    // Category Selected View: Subcategories + Products Grid
                    if (isCategorySelected) ...[
                      SliverToBoxAdapter(child: _buildSubcategorySelector()),
                      SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                      SliverToBoxAdapter(child: _buildCategorySectionHeader()),
                      _buildProductGridSliver(),
                      SliverToBoxAdapter(child: _buildLoadMoreButton()),
                    ],

                    // Bottom clearance
                    SliverToBoxAdapter(child: SizedBox(height: 30.h)),
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
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger Menu Icon Button
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

          // Center: Medivila Bengali Logo
          InkWell(
            onTap: _clearCategorySelection,
            child: BrandLogo(
              height: 42.h,
              width: 145.w,
            ),
          ),

          // Right: User Profile Icon Button
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
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: auth.loggedIn ? AppColors.primary : const Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 2. Emerald Search Bar (matches HeaderSearchBar.jsx)
  Widget _buildEmeraldSearchBar() {
    final currentPlaceholder = _searchPlaceholders[_currentPlaceholderIndex];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 10.h),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF86EFAC), // emerald-300 soft border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            // Left Search Icon in Emerald Green
            Icon(
              Icons.search_rounded,
              color: const Color(0xFF16A34A),
              size: 22.sp,
            ),
            SizedBox(width: 10.w),
            // Search Input with Animated Cycling Placeholder
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
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: currentPlaceholder,
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF6B7280),
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
                  color: Color(0xFF9CA3AF),
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearch('');
                },
              ),
            // Right Search Button with emerald gradient
            InkWell(
              onTap: () => _onSearch(_searchCtrl.text),
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(10.r),
              ),
              child: Container(
                width: 48.w,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(10.r),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── Category Breadcrumb
  Widget _buildCategoryBreadcrumb() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 10.h),
      child: Row(
        children: [
          InkWell(
            onTap: _clearCategorySelection,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_rounded, color: Color(0xFF2563EB), size: 16),
                SizedBox(width: 4.w),
                Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: const Text('/', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          Expanded(
            child: Text(
              _selectedCategoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          InkWell(
            onTap: _clearCategorySelection,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 2.w),
                  Text(
                    'Clear',
                    style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          height: 154.h,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
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

              // Dots Indicator
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
                      width: _currentBannerIndex == i ? 16.w : 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == i
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
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

  // ───────────────────────────────────────────────────────── 4. Diagnostic Lab Tests Section (matches LabTest.jsx)
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
          color: const Color(0xFFF4FBF7), // Mint background
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

  // ───────────────────────────────────────────────────────── 5. "Especially For You" Dynamic Section (matches SpecialForYou.jsx)
  Widget _buildEspeciallyForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Especially For You',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<List<OfferItem>>(
          stream: getOffersRx.valueStreamData,
          builder: (context, snapshot) {
            final offers = (snapshot.data != null && snapshot.data!.isNotEmpty)
                ? snapshot.data!
                : _fallbackOffers;

            return SizedBox(
              height: 175.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return _buildOfferCard(offer, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOfferCard(OfferItem offer, int index) {
    final accent = offer.cardColor;

    return InkWell(
      onTap: () => _handleOfferClick(offer),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.r),
        topRight: Radius.circular(52.r), // Asymmetric top-right curved corner matching web!
        bottomLeft: Radius.circular(16.r),
        bottomRight: Radius.circular(16.r),
      ),
      child: Container(
        width: 220.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFFEF9), accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(52.r),
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Title + Circular Top-Right Icon Container
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h, right: 8.w),
                    child: Text(
                      offer.topText.isNotEmpty ? offer.topText : offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      offer.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.local_offer_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Middle Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offer.mainText.isNotEmpty ? offer.mainText : offer.discount,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (offer.supportText != null && offer.supportText!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    offer.supportText!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            // Bottom Action Button with white background and accent text
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 7.h),
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
                offer.buttonText,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 6. "Shop by Category" Section (matches CategoryShowcase.jsx)
  Widget _buildShopByCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Shop by Category',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<List<CategoryItem>>(
          stream: getCategoriesRx.valueStreamData,
          builder: (context, snapshot) {
            final categories = (snapshot.data ?? _defaultCategories)
                .where((category) => category.parentId == null)
                .toList();

            return SizedBox(
              height: 116.h,
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
                    borderRadius: BorderRadius.circular(16.r),
                    child: SizedBox(
                      width: 82.w,
                      child: Column(
                        children: [
                          Container(
                            width: 72.w,
                            height: 72.w,
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Container(
                                color: const Color(0xFFF8FAFC),
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
                          ),
                          SizedBox(height: 5.h),
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

  // ───────────────────────────────────────────────────────── Dynamic Homepage Category Sections (matches HomeCategorySections.jsx)
  Widget _buildHomePageCategorySectionsSliver() {
    return StreamBuilder<List<HomePageMenu>>(
      stream: getHomePageMenusRx.valueStreamData,
      builder: (context, snapshot) {
        final menus = snapshot.data ?? [];
        if (menus.isEmpty) {
          // If menus endpoint loading or empty, show single default category section
          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDefaultCategoryHeader('Featured Products'),
                _buildProductGridWidget(),
                _buildLoadMoreButton(),
              ],
            ),
          );
        }

        // Render each category section sequentially (matching HomeCategorySections.jsx)
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final menu = menus[index];
              return _HomePageCategoryProductSection(
                menu: menu,
                onViewAll: () => _onCategorySelected(menu.category, menu.name),
              );
            },
            childCount: menus.length,
          ),
        );
      },
    );
  }

  Widget _buildDefaultCategoryHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── Subcategory Selector
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
          height: 44.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            scrollDirection: Axis.horizontal,
            itemCount: subcategories.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final category = index == 0 ? selectedRoot! : subcategories[index - 1];
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

  // ───────────────────────────────────────────────────────── Category Products Header
  Widget _buildCategorySectionHeader() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final count = products.length;

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategoryName,
                    style: TextStyle(
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 44.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$count products',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF009640),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── Product Grid Sliver
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

  Widget _buildProductGridWidget() {
    return StreamBuilder<List<MedicineProduct>>(
      stream: getProductsRx.valueStreamData,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? _fallbackProducts;
        final visibleCount = allProducts.length < 6 ? allProducts.length : 6;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 12.h,
            ),
            itemBuilder: (context, index) {
              return MedivilaProductCard(product: allProducts[index]);
            },
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────── Load More Button
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
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF059669)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.3),
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

  // Fallbacks
  static final List<OfferItem> _fallbackOffers = [
    OfferItem(
      id: 1,
      title: 'Upload Prescription',
      topText: 'Upload Prescription',
      discount: '7% Discount',
      mainText: '7% Discount',
      buttonText: 'Upload',
      buttonLink: 'prescription',
      image: 'https://api.medivila.com/storage/offers/6a44d1dc6de73.webp',
      rawCardColor: '#10ADBE',
    ),
    OfferItem(
      id: 2,
      title: 'Whats App',
      topText: 'Whats App',
      discount: '5% Discount',
      mainText: '5% Discount',
      buttonText: 'Call Now',
      buttonLink: 'https://wa.me/8801625491153',
      image: 'https://api.medivila.com/storage/offers/6a44d1e94e7fe.webp',
      rawCardColor: '#bc6c00',
    ),
    OfferItem(
      id: 3,
      title: 'Call Now',
      topText: 'Call Now',
      discount: '2% Discount',
      mainText: '2% Discount',
      supportText: '+8801625491153',
      buttonText: 'Call Now',
      buttonLink: 'https://wa.me/8801625491153',
      image: 'https://api.medivila.com/storage/offers/6a47f4db3d3f3.webp',
      rawCardColor: '#dc6803',
    ),
    OfferItem(
      id: 4,
      title: 'HealthCare',
      topText: 'HealthCare',
      discount: 'Upto 60% Discount',
      mainText: 'Upto 60% Discount',
      buttonText: 'Click Here',
      buttonLink: 'https://medivila.com/category/healthcare',
      image: 'https://api.medivila.com/storage/offers/6a47f3bc9c68b.webp',
      rawCardColor: '#10ADBE',
    ),
  ];

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

  static final List<CategoryItem> _defaultCategories = [
    CategoryItem(
      id: 5,
      name: 'HealthCare',
      bnName: 'HealthCare',
      slug: 'healthcare',
      image: 'https://api.medivila.com/storage/rauvRIlkn2jt8sQzHZmZnBAg90vHWFET.webp',
    ),
    CategoryItem(
      id: 16,
      name: 'Sergical & Ortho Care',
      bnName: 'Sergical & Ortho Care',
      slug: 'sergical-ortho-care',
      image: 'https://api.medivila.com/storage/sZw999wWzCZ6vfFzKbLyg9ahqYdl0cP0.webp',
    ),
    CategoryItem(
      id: 86,
      name: 'Medical Equipments',
      bnName: 'Medical Equipments',
      slug: 'medical-equipments',
      image: 'https://api.medivila.com/storage/B1MsEz3L316g9k6syQRqYoV1KeFGl3qC.webp',
    ),
    CategoryItem(
      id: 14,
      name: 'Baby & Mom Care',
      bnName: 'Baby & Mom Care',
      slug: 'baby-mom-care',
      image: 'https://api.medivila.com/storage/Zy0VO1ho0DOHbH5pFsCfpQzPJwn2J4gx.webp',
    ),
    CategoryItem(
      id: 12,
      name: 'Personal & Privacy care',
      bnName: 'Personal & Privacy care',
      slug: 'personal-privacy-care',
      image: 'https://api.medivila.com/storage/9EoOLr1HZptUdxx9zUKgHOzznSIWLih9.webp',
    ),
  ];

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

// ───────────────────────────────────────────────────────────── Individual Section for Each Home Category (matches ProductSection.jsx)
class _HomePageCategoryProductSection extends StatefulWidget {
  const _HomePageCategoryProductSection({
    required this.menu,
    required this.onViewAll,
  });

  final HomePageMenu menu;
  final VoidCallback onViewAll;

  @override
  State<_HomePageCategoryProductSection> createState() =>
      _HomePageCategoryProductSectionState();
}

class _HomePageCategoryProductSectionState
    extends State<_HomePageCategoryProductSection> {
  List<MedicineProduct> _products = [];
  bool _loading = true;
  int _visibleCount = 6;

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    final catId = widget.menu.categoryId ?? widget.menu.category?.id;
    if (catId == null) return;

    try {
      final items = await ProductsApi.instance.getProducts(
        categoryId: catId,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _products = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _products.isEmpty) return const SizedBox.shrink();

    final shown = _products.take(_visibleCount).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Title + Green Gradient Accent Line + Product Count Badge)
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.menu.name,
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 44.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ],
                ),
                if (_products.isNotEmpty)
                  InkWell(
                    onTap: widget.onViewAll,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_products.length} products',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF009640),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: Color(0xFF009640),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Grid or Shimmer
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 12.h,
                ),
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shown.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 12.h,
                ),
                itemBuilder: (context, idx) {
                  return MedivilaProductCard(product: shown[idx]);
                },
              ),
            ),

          // "Load More" / "View All" Button for Section
          if (_products.length > _visibleCount)
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _visibleCount += 6;
                    });
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Load More (${shown.length} of ${_products.length})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
