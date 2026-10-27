import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';

class CustomCircleAppbar extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final EdgeInsetsGeometry? margin;
  final BoxShadow? shadow;

  const CustomCircleAppbar({
    super.key,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.margin,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 40.h, left: 16.w, right: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Back Button
          GestureDetector(
            onTap: onTap ?? () => Get.back(),
            child: Container(
              height: size ?? 48.w,
              width: size ?? 48.w,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  shadow ??
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize ?? 20.sp,
                color: iconColor ?? AppColors.c1C1C28,
              ),
            ),
          ),

          // Share Button
          GestureDetector(
            onTap: () {
              SharePlus.instance.share(ShareParams(text: "Check this property: "));
            },
            child: Container(
              height: size ?? 48.w,
              width: size ?? 48.w,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  shadow ??
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                ],
              ),
              child: Icon(
                Icons.share,
                size: iconSize ?? 20.sp,
                color: iconColor ?? AppColors.c1C1C28,
              ),
            ),
          ),
        ],
      ),
    );
  }
  }

