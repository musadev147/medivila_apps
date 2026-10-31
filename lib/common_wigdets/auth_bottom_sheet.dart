import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../common_wigdets/app_toast.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../networks/api_error.dart';
import '../provider/auth_provider.dart';

/// Opens the Medivila Login & Register bottom sheet.
void showAuthModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AuthBottomSheet(),
  );
}

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  int _selectedTab = 0; // 0 = Login, 1 = Register
  final _loginPhoneCtrl = TextEditingController();

  final _regNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _loginPhoneCtrl.dispose();
    _regNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _loginPhoneCtrl.text.trim();
    if (!AppConfig.isValidBdPhone(phone)) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final clean = AppConfig.cleanBdPhone(phone);
      await context.read<AuthProvider>().loginWithPhone(clean);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      AppToast.success('লগইন সফল হয়েছে!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString();
      if (errorMsg.contains('404') ||
          errorMsg.toLowerCase().contains('user not found')) {
        AppToast.error('অ্যাকাউন্ট পাওয়া যায়নি। দয়া করে রেজিস্ট্রেশন করুন।');
        setState(() {
          _selectedTab = 1;
          _regPhoneCtrl.text = phone;
        });
      } else {
        AppToast.error(
          apiError(e, 'লগইন করা যায়নি। তথ্য যাচাই করে আবার চেষ্টা করুন।'),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();

    if (name.isEmpty) {
      AppToast.error('আপনার পুরো নাম লিখুন');
      return;
    }
    if (!AppConfig.isValidBdPhone(phone)) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন');
      return;
    }
    if (pass.length < 6) {
      AppToast.error('পাসওয়ার্ড কমপক্ষে ৬ ডিজিট হতে হবে');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final clean = AppConfig.cleanBdPhone(phone);
      await context.read<AuthProvider>().registerWithPhone(
        name: name,
        phone: clean,
        password: pass,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      AppToast.success('রেজিস্ট্রেশন এবং লগইন সফল হয়েছে!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(
        apiError(
          e,
          'রেজিস্ট্রেশন করা যায়নি। নম্বর ইতিমধ্যে ব্যবহৃত হতে পারে।',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        18.w,
        14.h,
        18.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTab == 0
                      ? 'মেডিভিলা অ্যাকাউন্টে লগইন'
                      : 'নতুন অ্যাকাউন্ট তৈরি করুন',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Tab Switcher
            Container(
              height: 42.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'লগইন',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == 0
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'রেজিস্ট্রেশন',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == 1
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            if (_selectedTab == 0) ...[
              Text(
                'মোবাইল নম্বর',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _loginPhoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_iphone_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'লগইন করুন',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else ...[
              Text(
                'আপনার নাম',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _regNameCtrl,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'উদা: মো: করিম',
                  prefixIcon: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'মোবাইল নম্বর',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _regPhoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_iphone_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'পাসওয়ার্ড',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _regPassCtrl,
                obscureText: _obscurePass,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'কমপক্ষে ৬ ডিজিট',
                  prefixIcon: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'নিবন্ধন সম্পন্ন করুন',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

