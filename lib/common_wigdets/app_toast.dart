import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  AppToast._();

  static void _show({
    required String message,
    required List<Color> gradient,
    required IconData icon,
  }) {
    Get.closeAllSnackbars();

    Get.showSnackbar(GetSnackBar(
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.zero,
      barBlur: 0,
      boxShadows: const [], // Explicitly remove default GetX shadows
      duration: const Duration(seconds: 3),
      isDismissible: true,
    ));
  }

  static void success(String message) {
    _show(
      message: message,
      icon: Icons.check,
      gradient: const [
        Color(0xFF5B9CFF),
        Color(0xFF3C74D8),
      ],
    );
  }

  /// 🔴 Premium Red
  static void error(String message) {
    _show(
      message: message,
      icon: Icons.close,
      gradient: const [
        Color(0xFFFF7A7A),
        Color(0xFFE63946),
      ],
    );
  }

  /// ⚪ Premium Grey
  static void info(String message) {
    _show(
      message: message,
      icon: Icons.info_outline,
      gradient: const [
        Color(0xFF7A7A7A),
        Color(0xFF4F4F4F),
      ],
    );
  }
}