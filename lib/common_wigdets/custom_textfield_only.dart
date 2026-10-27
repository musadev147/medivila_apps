// ignore_for_file: must_be_immutable, unused_field, unrelated_type_equality_checks
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextFormFieldOnly extends StatefulWidget {
  final bool isBorderColor;
  final String? labelText;
  final String? hintText;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final AutovalidateMode? autoValidateMode;
  final double borderRadius;
  final VoidCallback? onSuffixIconTap;
  final Object? prefixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLine;
  final bool? isReadOnly;
  final VoidCallback? onTap;
  final bool isRequired;
  final String? title;
  final double? titleHeight;
  final Color? fillColor;
  final Color? hintTextColor;
  final Color? titleTextColor;
  final Color? textActiveColor;
  final Color? prefixIconColor;
  final Color? cursorColor;
  final bool? showPasswordColor;
  final bool? focusBorder;
  final bool? filled;



  const CustomTextFormFieldOnly({
    super.key,
    this.fillColor,
    this.filled = false, // default false
    this.titleHeight = 6,
    this.labelText,
    this.hintText,
    this.suffixIcon,
    this.obscureText = false,
    this.autoValidateMode = AutovalidateMode.onUserInteraction,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.borderRadius = 10.0,
    this.prefixIcon,
    this.onSuffixIconTap,
    this.focusNode,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.maxLine = 1,
    this.isReadOnly = false,
    this.onTap,
    this.isBorderColor = true,
    this.isRequired = false,
    this.title,
    this.hintTextColor,
    this.titleTextColor,
    this.showPasswordColor,
    this.textActiveColor,
    this.cursorColor,
    this.focusBorder = true,
    this.prefixIconColor,
  });

  @override
  State<CustomTextFormFieldOnly> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormFieldOnly> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Helper method for prefix icon logic
  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon == null) {
      return null;
    }

    if (widget.prefixIcon is IconData) {
      /// IconData handle kora holo
      return Padding(
        padding: EdgeInsets.only(left: 12.w, right: 8.w),
        child: Icon(
          widget.prefixIcon as IconData,
          color: widget.prefixIconColor,
          size: 20.r,
        ),
      );
    } else if (widget.prefixIcon is String) {
      // String (Image Path) handle kora holo
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: Image.asset(
          widget.prefixIcon as String,
          color: widget.prefixIconColor,
          height: 20.h,
          width: 20.w,
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isRequired && widget.title != null)
          Text(
            widget.title!,
            style: TextStyle(
              color: widget.titleTextColor ?? Colors.black.withValues(alpha: 0.7),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        SizedBox(height: widget.titleHeight),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB3BAC5), width: 0.8),
            // borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: TextFormField(
            onTap: widget.onTap,
            readOnly: widget.isReadOnly ?? false,
            autovalidateMode: widget.autoValidateMode,
            focusNode: _focusNode,
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            validator: widget.validator,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            maxLines: widget.maxLine,
            style: TextStyle(
              color: widget.textActiveColor ?? Colors.black,
              fontSize: 14.sp,
            ),
            cursorColor: widget.cursorColor ?? const Color(0xFF6B6B6B),
            decoration: InputDecoration(
              // filled: true,
              filled: widget.filled ?? (widget.isReadOnly ?? false), // auto-filled if readOnly
              fillColor: widget.fillColor ?? Colors.white,
              labelText: widget.labelText,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.hintTextColor ?? Colors.grey,
                fontSize: 13.sp,
              ),
              prefixIcon: _buildPrefixIcon(),
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  width: 0.8,
                  color: widget.isBorderColor ? Colors.grey : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(
                  width: 0.8,
                  color: widget.focusBorder! ? const Color(0xFF6B6B6B) : Colors.transparent,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



/// ---- pore lagte pare
// decoration: InputDecoration(
//   filled: true,
//   fillColor: widget.fillColor ?? Colors.white,
//   labelText: widget.labelText,
//   hintText: widget.hintText,
//   hintStyle: TextStyle(
//     color: widget.hintTextColor ?? Colors.grey,
//     fontSize: 13.sp,
//   ),
//   suffixIcon: widget.suffixIcon,
//   border: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(widget.borderRadius),
//     borderSide: BorderSide.none,
//   ),
//   enabledBorder: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(widget.borderRadius),
//     borderSide: BorderSide(
//       width: 0.8,
//       color:
//           widget.isBorderColor ? Colors.grey : Colors.transparent,
//     ),
//   ),
//   focusedBorder: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(widget.borderRadius),
//     borderSide: BorderSide(
//       width: 0.8,
//       color:
//           widget.focusBorder!
//               ? Color(0xFF6B6B6B)
//               : Colors.transparent,
//     ),
//   ),
//   contentPadding: EdgeInsets.symmetric(
//     horizontal: 12.widget,
//     vertical: 12.h,
//   ),
// ),

///