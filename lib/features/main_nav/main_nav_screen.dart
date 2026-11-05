import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../common_wigdets/live_chat_button.dart';
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
  static const Color _activeEmerald = Color(0xFF16A34A);
  static const Color _activeBg = Color(0x4D16A34A);
  static const Color _inactiveBg = Color(0x14FFFFFF);
  static const Color _activeText = Colors.white;
  static const Color _inactiveText = Color(0xD9FFFFFF);

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

          // Floating Live Chat Button
          Positioned(
            right: 14.w,
            bottom: 76.h,
            child: const LiveChatFloatingButton(),
          ),
        ],
      ),

      // Bottom Navigation matching React Web BottomNav.jsx exactly:
      // Navy gradient (#1a3453 to #001f41), top emerald indicator, circular icon highlights, cart badge
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3453), Color(0xFF001F41)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border(
            top: BorderSide(
              color: Color(0x1AFFFFFF),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64.h,
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

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            // Active Top Emerald Accent Line (matches BottomNav.jsx top-0 rounded-b-full width 28px height 3px)
            Container(
              height: 3.h,
              width: 28.w,
              decoration: BoxDecoration(
                color: isSelected ? _activeEmerald : Colors.transparent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3.r)),
              ),
            ),

            const Spacer(),

            // Circular Icon Backdrop (matches BottomNav.jsx w-40 h-40 rounded-full)
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _activeBg : _inactiveBg,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? _activeText : _inactiveText,
                  size: isSelected ? 21.sp : 19.sp,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _activeText : _inactiveText,
                letterSpacing: 0.1,
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

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            Container(
              height: 3.h,
              width: 28.w,
              decoration: BoxDecoration(
                color: isSelected ? _activeEmerald : Colors.transparent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3.r)),
              ),
            ),

            const Spacer(),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _activeBg : _inactiveBg,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: isSelected ? _activeText : _inactiveText,
                      size: isSelected ? 21.sp : 19.sp,
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 2.h),

            Text(
              'Cart',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _activeText : _inactiveText,
                letterSpacing: 0.1,
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
