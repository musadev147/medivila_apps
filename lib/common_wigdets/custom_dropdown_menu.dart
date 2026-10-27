import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'custom_image_view.dart';

class CustomRealDropDownWithTitle<T> extends StatelessWidget {
  final bool showIcons;
  final List<T> dataArray;
  final T? selectedValue;
  final Function(T?)? selectTap;
  final String title;
  final String hint;
  final bool isRequired;
  final double height;
  final Color? borderColor;
  final Color? fillColor;
  final Color? hintTextColor;
  final Color? titleTextColor;

  /// ✅ new optional left icon (static icon on the left of dropdown)
  final String? leftIconPath;

  /// ✅ new optional right arrow icon color
  final Color? arrowIconColor;

  const CustomRealDropDownWithTitle({
    super.key,
    this.showIcons = false,
    required this.dataArray,
    required this.title,
    required this.hint,
    this.selectedValue,
    this.selectTap,
    this.isRequired = false,
    this.height = 45,
    this.borderColor,
    this.fillColor,
    this.hintTextColor,
    this.titleTextColor,
    this.leftIconPath, // ✅ left icon
    this.arrowIconColor, // ✅ arrow icon color
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired)
          Text(
            title,
            style: TextStyle(
              color: titleTextColor ?? const Color(0xFF292929),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.40,
            ),
          ),
        const SizedBox(height: 6),
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? Colors.grey),
            color: fillColor ?? Colors.white,
          ),
          child: Row(
            children: [
              /// ✅ static left icon (nullable)
              if (leftIconPath != null && leftIconPath!.isNotEmpty) ...[
                CustomImageView(
                  imagePath: leftIconPath!,
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 8),
              ],

              /// dropdown expanded part
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: fillColor ?? Colors.white,
                  ),
                  child: DropdownButton<T>(
                    value: selectedValue,
                    underline: const SizedBox(),
                    isExpanded: true,
                    hint: Text(
                      hint,
                      style: TextStyle(color: hintTextColor ?? Colors.grey),
                    ),

                    /// ✅ custom arrow icon
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: arrowIconColor ?? Colors.black,
                      size: 28,
                    ),

                    items: dataArray.map((item) {
                      Widget child;
                      if (T == String) {
                        child = Text(
                          item as String,
                          style: TextStyle(
                            color: const Color(0xFF6B6B6B),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      } else {
                        final platform = item as PlatformModel;
                        child = Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (showIcons && platform.icon.isNotEmpty) ...[
                              CustomImageView(
                                imagePath: platform.icon,
                                width: 25,
                                height: 25,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                platform.name,
                                style: TextStyle(
                                  color: const Color(0xFF6B6B6B),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return DropdownMenuItem<T>(
                        value: item,
                        child: child,
                      );
                    }).toList(),
                    onChanged: selectTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Platform Model (unchanged)
class PlatformModel {
  final String name;
  final String icon;

  PlatformModel({required this.name, required this.icon});

  factory PlatformModel.fromJson(Map<String, dynamic> json) {
    return PlatformModel(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

