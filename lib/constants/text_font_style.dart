import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextFontStyle {
  //Initialising Constractor
  TextFontStyle._();

  // Custom Text  Style
  static final textStyleMontserrarTegular = TextStyle(
    fontFamily: 'Montserrat Regular',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );

  ///
  ///
  ///
  static final textStyle20PoppinsW400 = TextStyle(
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w400,
  );
  static final textStyle18PoppinsW500 = TextStyle(
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
  );

  static var textStyle16PoppinsColorColorLight;
  static final textStyle16Poppins500494953 = TextStyle(
    color: const Color(0xFF494953),
    fontSize: 14.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0, // 0%
  );

  static final textStyle18Poppins6000 = TextStyle(
    color: const Color(0xFF222222),
    fontSize: 16.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle16Poppins500 = TextStyle(
    color: const Color(0xFFFFFFFF),
    fontSize: 14.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle12FFFFFFPoppins500 = TextStyle(
    color: const Color(0xFFFFFFFF),
    fontSize: 10.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle121C1C28Poppins400 = TextStyle(
    color: const Color(0xFF1C1C28),
    fontSize: 10.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle14Poppins300494953 = TextStyle(
    color: const Color(0xFF494953),
    fontSize: 12.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle12Poppins300494953 = TextStyle(
    color: const Color(0xFF494953),
    fontSize: 10.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w300,
    height: 1.50,
    letterSpacing: 0.30,
  );
  static final textStyle12Poppins400494953 = TextStyle(
    color: const Color(0xFF494953),
    fontSize: 10.sp,
    fontFamily: GoogleFonts.openSans().fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
}
