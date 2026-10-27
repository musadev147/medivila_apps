import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_assets/assets_icons.dart';
import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';

class Custom2Appbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? appBarColor;
  final Color? circleColor;
  final bool isLeftIcon;
  final bool isRightIcon;
  final String? leftIcon;
  final String? rightIcon;
  final VoidCallback? onTap;
  final VoidCallback? backOnTap;

  final bool isSkip;
  final String? skipText;
  final VoidCallback? onSkipTap;
  final List<Widget>? extraActions;

  const Custom2Appbar({
    super.key,
    required this.title,
    this.appBarColor,
    this.circleColor,
    this.isLeftIcon = true,
    this.isRightIcon = false,
    this.leftIcon,
    this.rightIcon,
    this.onTap,
    this.backOnTap,

    this.isSkip = false,
    this.skipText,
    this.onSkipTap,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBarColor ?? AppColors.c3B82F6,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

      title: Text(
        title,
        style: TextFontStyle.textStyle18PoppinsW500.copyWith(
          color: Theme.of(context).cardColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),

      leading: isLeftIcon
          ? GestureDetector(
        onTap: backOnTap ?? () => Get.back(),
        child: Container(
          margin: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
          height: 36.h,
          width: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor ?? AppColors.cF5F6FA,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              leftIcon ?? AssetsIcons.ArrowLeftIcons,
              height: 24.h,
              width: 24.w,
              color: AppColors.c1C1C28,
            ),
          ),
        ),
      )
          : const SizedBox(),

      actions: [
        if (isSkip)
          GestureDetector(
            onTap: onSkipTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Center(
                child: Text(
                  skipText ?? "Skip",
                  style: TextFontStyle.textStyle18PoppinsW500.copyWith(
                    color: Theme.of(context).cardColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),

        if (isRightIcon)
          GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              child: Image.asset(
                rightIcon ?? AssetsIcons.menu,
                height: 22.h,
                width: 22.w,
              ),
            ),
          ),

        ...?extraActions,
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
