import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../common_wigdets/live_chat_button.dart';
import '../../constants/app_colors.dart';
import '../../provider/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../doctors/doctors_screen.dart';
import '../home/home_screen.dart';
import '../product/shop_catalog_screen.dart';
import '../search/search_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    MedivilaHomeScreen(),
    ShopCatalogScreen(),
    CartScreen(),
    SearchScreen(),
    DoctorsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Live Chat Button (Images 1, 2, 3)
          Positioned(
            right: 14.w,
            bottom: 76.h,
            child: const LiveChatFloatingButton(),
          ),
        ],
      ),

      // Dark Navy Bottom Navigation Bar (Exact Match to Images 1, 2, 3)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B2240), // Dark Navy Blue
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62.h,
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.storefront_rounded, 'Shop'),
                _buildCartItem(2, cart.count),
                _buildNavItem(3, Icons.search_rounded, 'Search'),
                _buildNavItem(4, Icons.calendar_month_rounded, 'Appointment'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF009640);
    const inactiveColor = Color(0xFF8DA4C4);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          children: [
            // Active Top Green Accent Bar (Image 1, 3)
            Container(
              height: 3.h,
              width: 32.w,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3.r)),
              ),
            ),

            const Spacer(),

            Icon(
              icon,
              color: isSelected ? Colors.white : inactiveColor,
              size: 22.sp,
            ),

            SizedBox(height: 2.h),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, int count) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF009640);
    const inactiveColor = Color(0xFF8DA4C4);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          children: [
            Container(
              height: 3.h,
              width: 32.w,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3.r)),
              ),
            ),

            const Spacer(),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  color: isSelected ? Colors.white : inactiveColor,
                  size: 22.sp,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 15.w, minHeight: 15.w),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 2.h),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Cart',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
