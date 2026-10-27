import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';
import '../helpers/ui_helpers.dart';

class RoundedActionButton extends StatelessWidget {
  final String title;
  final Color containerBgColor;
  final Color iconBgColor;
  final String icon;
  final VoidCallback? onTap;
  final bool iconAtStart;
  final double radius;

  const RoundedActionButton({
    super.key,
    required this.title,
    required this.containerBgColor,
    required this.iconBgColor,
    required this.icon,
    this.onTap,
    this.iconAtStart = false,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: TextFontStyle.textStyle18PoppinsW500.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.c1C1C28,
      ),
    );

    final iconWidget = Container(
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(30.r),
      ),
      padding: EdgeInsets.all(6.w),
      child: Image.asset(
        icon,
        height: 18.h,
        width: 18.w,
        fit: BoxFit.contain,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: containerBgColor,
          borderRadius: BorderRadius.circular(radius.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisSize: MainAxisSize.min,
          children: iconAtStart
              ? [
            iconWidget,
            UIHelper.horizontalSpace(6.w),
            titleWidget,
          ]
              : [
            titleWidget,
            UIHelper.horizontalSpace(6.w),
            iconWidget,
          ],
        ),
      ),
    );
  }
}
