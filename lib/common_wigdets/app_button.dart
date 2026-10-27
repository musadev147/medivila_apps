import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String? title;
  final VoidCallback onPressed;
  final Color? buttonColor;
  final double? paddingHorizontal;
  final Color? borderColor;
  final double? height;
  final TextStyle? style;
  final double? borderRadius;
  final Widget? suffixIcon;

  const AppButton({
    super.key,
    this.title,
    required this.onPressed,
    this.buttonColor = AppColors.allPrimaryColor,
    this.borderColor = Colors.transparent,
    this.height,
    this.style,
    this.borderRadius = 9.21,
    this.suffixIcon, this.paddingHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal?? 22.w),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: height ?? 50,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: ShapeDecoration(
            color: buttonColor ?? AppColors.allPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              side: BorderSide(
                color: borderColor ?? Colors.transparent,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title ?? '',
                textAlign: TextAlign.center,
                style: style ??
                    TextStyle(
                      color: Theme.of(context).cardColor,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
              ),
              if (suffixIcon != null) ...[
                const SizedBox(width: 8),
                suffixIcon!,
              ]
            ],
          ),
        ),
      ),
    );
  }
}





