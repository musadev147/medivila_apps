import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/text_font_style.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Color appBarColor;
  final String? title;
  final Color circleColor;
  final String leftIcon;
  final String? rightIcon;
  final bool? isRightIcon;
  final bool? isLeftIcon;
  final VoidCallback? onTap;
  final VoidCallback backOnTap;
  final Color? textColor;

  const CustomAppbar({
    super.key,
    required this.appBarColor,
    this.title,
    required this.leftIcon,
    this.rightIcon,
    required this.circleColor,
    this.onTap,
    this.isRightIcon = true,
    required this.backOnTap,
    this.isLeftIcon,
    this.textColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(80.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBarColor,
      height: preferredSize.height,
      child: Padding(
        padding: EdgeInsets.only(top: 36.h, left: 16.w, right: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: backOnTap,
              child: Container(
                height: 0.h,
                width: 0.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: circleColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    leftIcon,
                    height: 24.h,
                    width: 24.w,
                  ),
                ),
              ),
            ),

            Text(
              title ?? '',
              style: TextFontStyle.textStyleMontserrarTegular.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                height: 0.0,
                color: textColor ?? Colors.white,
              ),
            ),

            isRightIcon! && rightIcon != null
                ? GestureDetector(
              onTap: onTap,
              child: Image.asset(
                rightIcon!,
                height: 20.h,
                width: 20.w,
              ),
            )
                : SizedBox(width: 20.w),
          ],
        ),
      ),
    );
  }
}
