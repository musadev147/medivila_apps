// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:svg_flutter/svg.dart';
import '../constants/app_colors.dart';
import '../constants/text_font_style.dart';

class CustomTextFormField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final IconData? suffixIcon;
  final bool? obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool? isPrefixIcon;
  final AutovalidateMode? autovalidateMode;
  final double? borderRadius;
  final VoidCallback? onSuffixIconTap;
  final String? iconpath;
  final FocusNode? focusNode;
  TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  List<TextInputFormatter>? inputFormatters;
  final int? maxLine;
  final bool? isReadOnly;
  final VoidCallback? onTap;
  final bool? enableBorderSide;
  final bool? isPassword;

  CustomTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.borderRadius = 12.0,
    this.isPrefixIcon,
    this.iconpath,
    this.onSuffixIconTap,
    this.focusNode,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.maxLine = 1,
    this.isReadOnly = false,
    this.onTap,
    this.enableBorderSide = true,
    this.isPassword = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPasswordVisible = false;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
      ),
      child: TextFormField(
        onTap: widget.onTap,
        readOnly: widget.isReadOnly ?? false,
        autovalidateMode: widget.autovalidateMode,
        focusNode: _focusNode,
        controller: widget.controller,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        obscureText: (widget.isPassword ?? false) && !_isPasswordVisible,
        onChanged: widget.onChanged,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLine ?? 1,
        style: TextFontStyle.textStyle20PoppinsW400
            .copyWith(
          color: AppColors.text,
          fontSize: 16.sp,
        ),
        cursorColor: AppColors.allPrimaryColor,
        decoration: InputDecoration(
  filled: true,
  fillColor: Colors.white,
  labelText: widget.labelText,
  hintText: widget.hintText,
  hintStyle: TextFontStyle.textStyle121C1C28Poppins400.copyWith(
    fontSize: 13.sp,
    color: AppColors.c494953,
  ),
  
  prefixIcon: (widget.isPrefixIcon ?? false) && widget.iconpath != null
      ? Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: SvgPicture.asset(widget.iconpath!, width: 24),
        )
      : widget.prefixIcon,

  suffixIcon: widget.isPassword == true
      ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: _isFocused ? AppColors.allPrimaryColor : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
      : widget.suffixIcon != null
          ? GestureDetector(
              onTap: widget.onSuffixIconTap,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  widget.suffixIcon,
                  color: _isFocused ? AppColors.allPrimaryColor : Colors.orange,
                ),
              ),
            )
          : null,

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
    borderSide: const BorderSide(width: 1, color: Colors.grey),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
    borderSide: const BorderSide(width: 1, color: Colors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
    borderSide: const BorderSide(width: 1, color: AppColors.allPrimaryColor),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
    borderSide: const BorderSide(width: 1, color: Colors.red),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
    borderSide: const BorderSide(width: 1, color: Colors.red),
  ),

  errorStyle: const TextStyle(
    color: Colors.red,
    fontSize: 12,
  ),

  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
),

      ),
    );
  }
}
