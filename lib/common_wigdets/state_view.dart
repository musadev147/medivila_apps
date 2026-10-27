import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

/// Standard loading / error / empty / content switch used by list screens.
class StateView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String emptyText;
  final IconData emptyIcon;
  final Future<void> Function()? onRetry;
  final Widget child;

  const StateView({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.child,
    this.error,
    this.emptyText = 'Nothing here yet.',
    this.emptyIcon = Icons.inbox_rounded,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        color: Colors.orange.shade700,
        title: 'Could not load data',
        subtitle: error!,
        onRetry: onRetry,
      );
    }
    if (isEmpty) {
      return _Message(icon: emptyIcon, color: Colors.grey.shade400, title: emptyText, onRetry: onRetry);
    }
    if (onRetry != null) {
      return RefreshIndicator(onRefresh: onRetry!, color: AppColors.allPrimaryColor, child: child);
    }
    return child;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Future<void> Function()? onRetry;

  const _Message({required this.icon, required this.color, required this.title, this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72.r, color: color),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 18.r, color: AppColors.allPrimaryColor),
                label: Text('Retry', style: TextStyle(color: AppColors.allPrimaryColor, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.allPrimaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded white card used throughout the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      // ListTile / InkWell children paint on the nearest Material; give them
      // a transparent one so the card's own background stays visible.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(24.r),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding ?? EdgeInsets.all(20.w), child: child),
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24.r), child: card);
  }
}

/// Small coloured pill for statuses.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.w800)),
    );
  }
}

/// Icon + text row used for meta data inside cards.
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoItem(this.icon, this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.r, color: color ?? Colors.grey.shade400),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10.sp, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Label / value row for detail sheets.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.sp, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, color: valueColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent primary-coloured app bar.
AppBar appBarOf(String title, {List<Widget>? actions, Widget? leading, PreferredSizeWidget? bottom}) => AppBar(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white)),
      backgroundColor: AppColors.allPrimaryColor,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
      actions: actions,
      leading: leading,
      bottom: bottom,
    );

/// Pull-handle used at the top of bottom sheets.
Widget sheetHandle() => Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
      ),
    );

const Color kScreenBackground = Color(0xFFF4F6F9);
