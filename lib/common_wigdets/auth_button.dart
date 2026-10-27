// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
Widget AppCustomeButton({
  bool? isIcon = false,
  required String name,
  required VoidCallback onCallBack,
  required double height,
  required double minWidth,
  required double borderRadius,
  required Color color,
  Color? borderSideColor,
  required TextStyle textStyle,
  required BuildContext context,
}) {
  return MaterialButton(
    elevation: 0,
    onPressed: onCallBack,
    height: height,
    minWidth: minWidth,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side:
            BorderSide(width: 2, color: borderSideColor ?? Colors.transparent)),
    color: color,
    splashColor: Colors.white.withOpacity(0.4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // isIcon! ? SvgPicture.asset(Assets.icons.add) : const SizedBox.shrink(),
        Text(
          name,
          style: textStyle,
        ),
      ],
    ),
  );
}
