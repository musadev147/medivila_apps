import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../common_wigdets/app_toast.dart';
import '../features/product/product_detail_screen.dart';
import '../models/medivila_models.dart';
import '../provider/cart_provider.dart';

class MedivilaProductCard extends StatelessWidget {
  const MedivilaProductCard({
    super.key,
    required this.product,
  });

  final MedicineProduct product;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDiscounted = product.hasDiscount;
    final discountPercent = product.discountPercentage;
    final isAdded = cart.lines.any((l) => l.product == '');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Discount badge & Product Image
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 110.h,
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Image.network(
                      product.primaryImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 42,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Discount Badge on top-left (rounded pill)
                if (isDiscounted && discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8.h),

            // Product Title
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.25,
              ),
            ),

            const Spacer(),

            // Price & ADD Button Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDiscounted)
                        Text(
                          '৳${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '৳${product.effectivePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Outlined or filled ADD Button
                InkWell(
                  onTap: () {
                    cart.addMedicine(product);
                    AppToast.success('কার্টে যোগ করা হয়েছে!');
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isAdded ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFF16A34A),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      isAdded ? 'ADDED' : 'ADD',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
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
}
