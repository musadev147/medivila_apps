import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../networks/api_access.dart';
import '../../provider/auth_provider.dart';
import '../../provider/cart_provider.dart';
import '../main_nav/main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Kick off bootstrap and cart loading in parallel
    final futures = <Future>[
      getBootstrapRx.fetchBootstrap(),
      getProductsRx.fetchProducts(),
      getLabTestsRx.fetchLabTests(),
      getDoctorsRx.fetchDoctors(),
      context.read<AuthProvider>().restore(),
      context.read<CartProvider>().load(),
      Future.delayed(
        const Duration(milliseconds: 2200),
      ), // Smooth transition minimum time
    ];

    try {
      await Future.wait(futures);
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, secondaryAnim) =>
            FadeTransition(opacity: anim, child: const MainNavScreen()),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background soft gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF1F8F4),
                    Color(0xFFE8F5E9),
                  ],
                ),
              ),
            ),
          ),

          // Central Logo and Branding
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Medivila App Icon Card
                        Container(
                          width: 110.w,
                          height: 110.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Image.asset(
                            AppConfig.logoAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.local_pharmacy_rounded,
                              size: 54.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Bengali Brand Name
                        Text(
                          'মেডিভিলা',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(height: 6.h),

                        // Slogan
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Text(
                            AppConfig.appSlogan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSoft,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Loading spinner & version tag
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 26.w,
                  height: 26.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '১০০% খাঁটি ঔষধ ও দ্রুত হোম ডেলিভারি',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
