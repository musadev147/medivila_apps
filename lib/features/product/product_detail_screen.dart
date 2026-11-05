import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../common_wigdets/app_toast.dart';
import '../../common_wigdets/medivila_product_card.dart';
import '../../constants/app_colors.dart';
import '../../models/medivila_models.dart';
import '../../networks/medivila_api_services.dart';
import '../../provider/cart_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final MedicineProduct product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductSize? _selectedSize;
  late MedicineProduct _product;
  bool _isLoading = true;
  String? _loadError;
  List<MedicineProduct> _relatedProducts = [];
  bool _isRelatedLoading = false;
  String? _relatedError;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final slug = widget.product.slug.trim();
    if (slug.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'এই পণ্যের বিস্তারিত পাওয়া যায়নি।';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final product = await ProductsApi.instance.getProductDetail(slug);
      if (!mounted) return;
      setState(() {
        _product = product;
        _selectedSize = product.sizes.isNotEmpty ? product.sizes.first : null;
        _isLoading = false;
      });
      _loadRelatedProducts(product);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'পণ্যের তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।';
      });
    }
  }

  Future<void> _loadRelatedProducts(MedicineProduct product) async {
    final categoryId = product.categoryId;
    if (categoryId == null) {
      setState(() {
        _relatedProducts = [];
        _isRelatedLoading = false;
        _relatedError = null;
      });
      return;
    }

    setState(() {
      _isRelatedLoading = true;
      _relatedError = null;
    });
    try {
      final products = await ProductsApi.instance.getProducts(
        categoryId: categoryId,
        limit: 9,
      );
      if (!mounted) return;
      setState(() {
        _relatedProducts = products
            .where(
              (candidate) =>
                  candidate.id != product.id && candidate.slug != product.slug,
            )
            .take(8)
            .toList();
        _isRelatedLoading = false;
      });
    } catch (error) {
      log('Related products load failed: $error');
      if (!mounted) return;
      setState(() {
        _relatedError = 'সাজেস্টেড পণ্য লোড করা যায়নি। আবার চেষ্টা করুন।';
        _isRelatedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          p.name,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.accent,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.accent,
                ),
                if (cart.count > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  SizedBox(height: 12.h),
                  OutlinedButton(
                    onPressed: _loadProduct,
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image Container
                  Container(
                    height: 240.h,
                    width: double.infinity,
                    color: Colors.white,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p.primaryImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.medication_liquid_rounded,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (p.hasDiscount)
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '${p.discountPercentage}% ছাড়',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Medicine Details Card
                  Container(
                    margin: EdgeInsets.all(14.w),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (p.genericName != null) ...[
                          Text(
                            'জেনেরিক: ${p.genericName}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                        ],
                        if (p.manufacturer != null) ...[
                          Text(
                            'প্রস্তুতকারক: ${p.manufacturer}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],

                        // Price
                        Row(
                          children: [
                            Text(
                              '৳ ${p.effectivePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF009640),
                              ),
                            ),
                            if (p.hasDiscount) ...[
                              SizedBox(width: 8.w),
                              Text(
                                '৳${p.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  decoration: TextDecoration.lineThrough,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (p.requiresPrescription) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFFD97706),
                                  size: 18,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'এই ওষুধের জন্য রেজিস্টার্ড ডাক্তারের প্রেসক্রিপশন আবশ্যক',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: const Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Sizes / Pack Selection
                        if (p.sizes.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          Text(
                            'প্যাক সাইজ নির্বাচন করুন:',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 8.w,
                            children: p.sizes.map((s) {
                              final isSel = _selectedSize?.id == s.id;
                              return ChoiceChip(
                                label: Text(s.size),
                                selected: isSel,
                                onSelected: (_) =>
                                    setState(() => _selectedSize = s),
                                selectedColor: const Color(0xFFE8F5E9),
                                backgroundColor: const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.text,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSel
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Description
                        if (p.description != null &&
                            p.description!.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          const Divider(color: Color(0xFFF1F5F9)),
                          SizedBox(height: 6.h),
                          Text(
                            'ব্যবহার ও নির্দেশনা:',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final descriptionStyle = TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSoft,
                                height: 1.4,
                              );
                              final painter = TextPainter(
                                text: TextSpan(
                                  text: p.description!,
                                  style: descriptionStyle,
                                ),
                                textDirection: TextDirection.ltr,
                                maxLines: null,
                              )..layout(maxWidth: constraints.maxWidth);

                              final isLongDescription =
                                  painter.computeLineMetrics().length > 10;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.description!,
                                    maxLines: _showFullDescription ? null : 10,
                                    overflow: _showFullDescription
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    style: descriptionStyle,
                                  ),
                                  if (isLongDescription)
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _showFullDescription =
                                            !_showFullDescription;
                                      }),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: Text(
                                        _showFullDescription
                                            ? 'কম দেখুন'
                                            : 'See More',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (p.categoryId != null) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 10.h),
                      child: Text(
                        'এই ক্যাটাগরির আরও পণ্য',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (_isRelatedLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_relatedError != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 18.h),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                _relatedError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _loadRelatedProducts(p),
                                child: const Text('আবার চেষ্টা করুন'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_relatedProducts.isEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 18.h),
                        child: Text(
                          'এই ক্যাটাগরিতে আর কোনো পণ্য পাওয়া যায়নি।',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _relatedProducts.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 10.w,
                                mainAxisSpacing: 12.h,
                              ),
                          itemBuilder: (context, index) => MedivilaProductCard(
                            product: _relatedProducts[index],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _isLoading || _loadError != null
          ? null
          : Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          Text(
                            '$_quantity',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Add to cart button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          cart.addMedicine(
                            p,
                            quantity: _quantity,
                            size: _selectedSize,
                          );
                          AppToast.success('কার্টে যোগ হয়েছে: ${p.name}');
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(
                          'কার্টে যোগ করুন (৳ ${(p.effectivePrice * _quantity).toStringAsFixed(0)})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
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
