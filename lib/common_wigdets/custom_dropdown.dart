// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';
import '../helpers/ui_helpers.dart';

class MyCustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String? hinttext;
  final Function(T?) onChanged;
  final bool isImageNull;
  final bool isIcon;
  final Color borderCalor;
  final String? hintIcon;
  final TextStyle? hintTextStyle;
  final String Function(T) getLabel;
  final bool isEnabled;

  const MyCustomDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.getLabel,
    required this.isImageNull,
    required this.isIcon,
    required this.borderCalor,
    this.hinttext,
    this.hintIcon,
    this.hintTextStyle,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: borderCalor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: items.contains(value) ? value : null,

            icon: isIcon
                ? const Icon(Icons.keyboard_arrow_down, size: 22)
                : const SizedBox(),

            hint: Row(
              children: [
                if (isIcon && hintIcon != null) Image.asset(hintIcon!, width: 20),
                if (isIcon && hintIcon != null) UIHelper.horizontalSpace(8),
                Flexible(
                  child: Text(
                    hinttext ?? 'Select',
                    overflow: TextOverflow.ellipsis,
                    style: hintTextStyle ??
                        TextFontStyle.textStyle20PoppinsW400.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.c494953,
                        ),
                  ),
                ),
              ],
            ),

            items: items.map((v) {
              return DropdownMenuItem<T>(
                value: v,
                child: Text(
                  getLabel(v),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),

            onChanged: isEnabled ? onChanged : null,
          )
        ),
      ),
    );
  }
}