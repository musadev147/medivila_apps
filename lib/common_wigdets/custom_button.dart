// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Widget CustomButton({
  required String name,
  required VoidCallback onCallBack,
  required double height,
  required double minWidth,
  required double borderRadius,
  required Color color,
  required TextStyle textStyle,
  required BuildContext context,
  Color? borderColor,
}) {
  return MaterialButton(
    onPressed: onCallBack,
    height: height,
    minWidth: double.infinity,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: borderColor ?? AppColors.allPrimaryColor, width: 1.5),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    color: color,
    splashColor: Colors.white.withOpacity(0.4),
    child: Text(
      name,
      style: textStyle,
    ),
  );
}
