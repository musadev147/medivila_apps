import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_wigdets/app_toast.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';

class LiveChatFloatingButton extends StatelessWidget {
  const LiveChatFloatingButton({super.key});

  static Future<void> showSupportOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'মেডিভিলা লাইভ সাপোর্ট',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'যেকোনো প্রয়োজনে আমরা আছি আপনার পাশে',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _SupportOptionTile(
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF25D366),
              title: 'WhatsApp লাইভ চ্যাট',
              subtitle: 'মেসেজ দিন ও সাথে সাথে পরামর্শ নিন',
              onTap: () async {
                Navigator.pop(ctx);
                final cleanPhone = AppConfig.cleanBdPhone(AppConfig.helplinePhone);
                final uri = Uri.parse(
                  'https://wa.me/880$cleanPhone?text=${Uri.encodeComponent('হ্যালো মেডিভিলা, আমার কিছু তথ্য প্রয়োজন।')}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  AppToast.error('WhatsApp ওপেন করা যাচ্ছে না');
                }
              },
            ),
            SizedBox(height: 10.h),
            _SupportOptionTile(
              icon: Icons.phone_in_talk_rounded,
              iconColor: AppColors.primary,
              title: 'সরাসরি কল করুন',
              subtitle: AppConfig.helplinePhone,
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:${AppConfig.helplinePhone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  AppToast.error('কল করা যাচ্ছে না');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showSupportOptions(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF009640),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/customer.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF009640),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'LIVE\nCHAT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF009640),
                height: 1.05,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportOptionTile extends StatelessWidget {
  const _SupportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

