import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common_wigdets/medivila_product_card.dart';
import '../../constants/app_colors.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';

class ShopCatalogScreen extends StatefulWidget {
  const ShopCatalogScreen({super.key});

  @override
  State<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends State<ShopCatalogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedCategoryId;
  int _productsVisibleLimit = 12;

  @override
  void initState() {
    super.initState();
    if (getProductsRx.dataFetcher.valueOrNull == null) {
      getProductsRx.fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    getProductsRx.fetchProducts(
      categoryId: _selectedCategoryId,
      search: query.trim().isNotEmpty ? query.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Shop',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 6.h),
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFFD81B60),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  Icon(
                    Icons.search_rounded,
                    color: const Color(0xFFD81B60),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
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
                      style: TextStyle(fontSize: 13.sp),
                      decoration: InputDecoration(
                        hintText: 'পণ্য অনুসন্ধান করুন...',
                        hintStyle: TextStyle(
                          fontSize: 12.5.sp,
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
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    ),
                  InkWell(
                    onTap: () => _onSearch(_searchCtrl.text),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6.5.r),
                    ),
                    child: Container(
                      width: 44.w,
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
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Filter Chips
          StreamBuilder<BootstrapData>(
            stream: getBootstrapRx.valueStreamData,
            builder: (context, snapshot) {
              final categories = snapshot.data?.categories ?? [];
              if (categories.isEmpty) return const SizedBox.shrink();

              return Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return ChoiceChip(
                        label: Text('All Products', style: TextStyle(fontSize: 12.sp)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = null);
                          getProductsRx.fetchProducts();
                        },
                      );
                    }
                    final cat = categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;
                    return ChoiceChip(
                      label: Text(cat.displayName, style: TextStyle(fontSize: 12.sp)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = cat.id);
                        getProductsRx.fetchProducts(categoryId: cat.id);
                      },
                    );
                  },
                ),
              );
            },
          ),

          SizedBox(height: 8.h),

          // Product Grid
          Expanded(
            child: StreamBuilder<List<MedicineProduct>>(
              stream: getProductsRx.valueStreamData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'কোনো পণ্য পাওয়া যায়নি',
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

                final visibleCount = products.length < _productsVisibleLimit
                    ? products.length
                    : _productsVisibleLimit;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 12.h,
                      ),
                      itemCount: visibleCount,
                      itemBuilder: (context, index) {
                        return MedivilaProductCard(product: products[index]);
                      },
                    ),

                    if (products.length > _productsVisibleLimit) ...[
                      SizedBox(height: 16.h),
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _productsVisibleLimit += 12;
                            });
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009640),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Text(
                              'Load More ($_productsVisibleLimit of ${products.length})',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
