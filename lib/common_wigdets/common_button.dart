import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';
import '../helpers/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  /// Asset icon (like profile button)
  final String? assetIconPath;

  /// Custom widgets (optional)
  final Widget? icon;
  final Widget? suffixIcon;

  final bool isOutlined;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double? height;
  final double? borderRadius;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.assetIconPath,
    this.icon,
    this.suffixIcon,
    this.isOutlined = false,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextFontStyle.textStyle16Poppins500.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: textColor ?? AppColors.cFFFFFF,
      ),
    );

    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// LEFT ICON (asset)
        if (assetIconPath != null) ...[
          Image.asset(
            assetIconPath!,
            height: 20.w,
            width: 20.w,
            color: textColor ?? AppColors.cFFFFFF,
          ),
          UIHelper.horizontalSpace(10.w),
        ],

        /// Custom icon (optional)
        if (icon != null) ...[
          icon!,
          UIHelper.horizontalSpace(8.w),
        ],

        /// TEXT
        Flexible(child: textWidget),

        /// Suffix icon (right side if needed)
        if (suffixIcon != null) ...[
          UIHelper.horizontalSpace(8.w),
          suffixIcon!,
        ],
      ],
    );


    return SizedBox(
      width: double.infinity,
      height: height ?? 48.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                ),
               
              ),
              child: buttonContent,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? AppColors.allPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                ),
              ),
              child: buttonContent,
            ),
    );
  }
}