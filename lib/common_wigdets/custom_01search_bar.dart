import '../constants/app_assets/assets_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';

class Custom01SearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const Custom01SearchBar({
    super.key,
    this.hintText = "Search...",
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F848484),
            blurRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,

          /// search icon wrapped in SizedBox for proper size
          prefixIcon: SizedBox(
            width: 24.w,
            height: 24.h,
            child: Center(
              child: Image.asset(
                AssetsIcons.searchIcons,
                width: 16.w,
                height: 16.h,
                color: AppColors.c1C1C28,
              ),
            ),
          ),

          hintText: hintText,
          hintStyle: TextFontStyle.textStyle20PoppinsW400.copyWith(
            fontSize: 12.sp,
            color: AppColors.c4A4A68,
          ),

          /// clear icon
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              controller!.clear();
              onChanged?.call("");
            },
          )
              : null,
        ),
      ),
    );
  }
}