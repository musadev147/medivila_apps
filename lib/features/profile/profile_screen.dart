import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../networks/medivila_api_services.dart';
import '../../provider/auth_provider.dart';
import '../../networks/api_error.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _trackCtrl = TextEditingController();
  Map<String, dynamic>? _trackedOrder;

  @override
  void dispose() {
    _trackCtrl.dispose();
    super.dispose();
  }

  void _showAuthModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const _AuthSheet(),
    );
  }

  Future<void> _trackOrder() async {
    if (_trackCtrl.text.trim().isEmpty) {
      AppToast.error('অর্ডার আইডি লিখুন');
      return;
    }

    try {
      final res = await OrdersApi.instance.trackOrder(_trackCtrl.text.trim());
      if (mounted) setState(() => _trackedOrder = res);
    } catch (error) {
      if (mounted) {
        AppToast.error(apiError(error, 'অর্ডারের তথ্য পাওয়া যায়নি।'));
      }
    }
  }

  Future<void> _callHelpline() async {
    final uri = Uri.parse('tel:${AppConfig.helplinePhone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.phoneUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'অ্যাকাউন্ট ও হেল্পলাইন',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 30.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'অতিথি ব্যবহারকারী',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          user?.phone ?? 'লগইন করতে নিচের বাটন চাপুন',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        InkWell(
                          onTap: user == null
                              ? () => _showAuthModal()
                              : () => auth.logout(),
                          child: Text(
                            user == null
                                ? 'লগইন বা রেজিস্ট্রেশন করুন >'
                                : 'লগআউট করুন >',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coins Badge
                  if (user != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${user.points} Coins',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Order Tracking Card
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'অর্ডার ট্র্যাক করুন',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _trackCtrl,
                          decoration: InputDecoration(
                            hintText: 'অর্ডার আইডি দিন (যেমন: MED...)',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 42.h,
                        child: ElevatedButton(
                          onPressed: _trackOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: const Text(
                            'ট্র্যাক',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_trackedOrder != null) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'অর্ডার আইডি: ${_trackedOrder!['order_id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'স্ট্যাটাস: ${_trackedOrder!['status_bn'] ?? _trackedOrder!['status']}',
                          ),
                          Text(
                            'আনুমানিক ডেলিভারি: ${_trackedOrder!['estimated_delivery']}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Hotline Call Card
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '২৪/৭ কাস্টমার সাপোর্ট হেল্পলাইন',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppConfig.helplinePhone,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: _callHelpline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.zero,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text(
                        'কল করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet();

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        14.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTab == 0
                      ? 'মেডিভিলা অ্যাকাউন্টে লগইন'
                      : 'নতুন অ্যাকাউন্ট তৈরি করুন',
                  style: TextStyle(
                    fontSize: 15.sp,
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
            SizedBox(height: 8.h),

            // Tab Switcher
            Container(
              height: 40.h,
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
                        child: Center(
                          child: Text(
                            'লগইন',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : AppColors.textSoft,
                            ),
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
                        child: Center(
                          child: Text(
                            'রেজিস্ট্রেশন',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : AppColors.textSoft,
                            ),
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
              TextField(
                controller: _loginPhoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'মোবাইল নম্বর',
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'লগইন করুন',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  child: Text(
                    'অ্যাকাউন্ট নেই? এখনই রেজিস্ট্রেশন করুন',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _regNameCtrl,
                keyboardType: TextInputType.name,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'আপনার পুরো নাম',
                  hintText: 'যেমন: মোঃ আব্দুল্লাহ',
                  prefixIcon: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _regPhoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'মোবাইল নম্বর',
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _regPassCtrl,
                obscureText: _obscurePass,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                  hintText: '••••••',
                  prefixIcon: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSoft,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'অ্যাকাউন্ট তৈরি করুন',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _selectedTab = 0),
                  child: Text(
                    'ইতিমধ্যে অ্যাকাউন্ট আছে? লগইন করুন',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
