import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../common_wigdets/auth_bottom_sheet.dart';
import '../common_wigdets/brand_logo.dart';
import '../constants/app_colors.dart';
import '../features/doctors/doctors_screen.dart';
import '../features/lab_tests/lab_tests_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/wholesale/wholesale_screen.dart';
import '../models/medivila_models.dart';
import '../networks/api_access.dart';
import '../provider/auth_provider.dart';

class MedivilaDrawer extends StatefulWidget {
  const MedivilaDrawer({
    super.key,
    this.onSelectCategory,
  });

  final void Function(CategoryItem? category, String? title)? onSelectCategory;

  @override
  State<MedivilaDrawer> createState() => _MedivilaDrawerState();
}

class _MedivilaDrawerState extends State<MedivilaDrawer> {
  final Set<int> _expandedCategoryIds = {};

  void _toggleCategoryExpand(int id) {
    setState(() {
      if (_expandedCategoryIds.contains(id)) {
        _expandedCategoryIds.remove(id);
      } else {
        _expandedCategoryIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.phoneUser;

    return Drawer(
      backgroundColor: Colors.white,
      width: 310.w,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Drawer Header (Medivila logo + Close Button)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 14.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(height: 34),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 2. User / Login Box
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.loggedIn
                              ? (user?.name ?? 'সম্মানিত গ্রাহক')
                              : 'স্বাগতম! মেডিভিলাতে',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          auth.loggedIn
                            ? 'পয়েন্ট: ${user?.points ?? 0}'
                            : 'লগইন করলেই পাবেন বোনাস পয়েন্ট',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (!auth.loggedIn)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showAuthModal(context);
                      },
                      icon: Icon(Icons.person, size: 14.sp, color: Colors.white),
                      label: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'প্রোফাইল',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 3. Category Header
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'সব ক্যাটাগরি (CATEGORIES)',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Scrollable Menu List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: [
                  // Flash Sale Card (Exact Match to Image 2)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectCategory?.call(null, 'Flash Sale');
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFB7EBC9)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: const Color(0xFF009640),
                            size: 26.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flash Sale',
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF007A34),
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Limited Time Offers',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC7F3D6),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'HOT',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF007A34),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Appointment
                  _buildQuickMenuItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Appointment',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorsScreen()),
                      );
                    },
                  ),

                  // Lab Test
                  _buildQuickMenuItem(
                    icon: Icons.science_rounded,
                    title: 'Lab Test',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LabTestsScreen()),
                      );
                    },
                  ),

                  // Wholesale
                  _buildQuickMenuItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Wholesale',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WholesaleScreen()),
                      );
                    },
                  ),

                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  // Dynamic Categories from Bootstrap
                  StreamBuilder<BootstrapData>(
                    stream: getBootstrapRx.valueStreamData,
                    builder: (context, snapshot) {
                      final categories = snapshot.data?.categories ?? _defaultCategories;
                      return Column(
                        children: categories.map((cat) => _buildCategoryTile(cat)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(CategoryItem cat) {
    final hasChildren = cat.children.isNotEmpty;
    final isExpanded = _expandedCategoryIds.contains(cat.id);

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (hasChildren) {
              _toggleCategoryExpand(cat.id);
            } else {
              Navigator.pop(context);
              widget.onSelectCategory?.call(cat, cat.displayName);
            }
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Row(
              children: [
                _buildCategoryIcon(cat.name),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    cat.displayName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (hasChildren)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20.sp,
                    color: const Color(0xFF64748B),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: const Color(0xFFCBD5E1),
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 36.w),
            child: Column(
              children: cat.children.map((sub) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectCategory?.call(sub, sub.displayName);
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 6.w),
                    child: Row(
                      children: [
                        Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            sub.displayName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryIcon(String name) {
    IconData iconData = Icons.category_outlined;
    final lower = name.toLowerCase();
    if (lower.contains('health') || lower.contains('care')) {
      iconData = Icons.health_and_safety_outlined;
    } else if (lower.contains('equip') || lower.contains('medical')) {
      iconData = Icons.medical_services_outlined;
    } else if (lower.contains('baby') || lower.contains('mom')) {
      iconData = Icons.child_care_rounded;
    } else if (lower.contains('privacy') || lower.contains('personal')) {
      iconData = Icons.person_pin_circle_outlined;
    } else if (lower.contains('sergical') || lower.contains('ortho')) {
      iconData = Icons.accessible_forward_rounded;
    } else if (lower.contains('beauty') || lower.contains('lifestyle')) {
      iconData = Icons.spa_outlined;
    } else if (lower.contains('lab')) {
      iconData = Icons.biotech_outlined;
    }

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(iconData, color: const Color(0xFF475569), size: 18.sp),
    );
  }

  static final List<CategoryItem> _defaultCategories = [
    CategoryItem(id: 1, name: 'HealthCare', bnName: 'HealthCare', slug: 'healthcare'),
    CategoryItem(
      id: 2,
      name: 'Medical Equipments',
      bnName: 'Medical Equipments',
      slug: 'medical-equipments',
      children: [
        CategoryItem(id: 201, name: 'Diagnostic Equipments', bnName: 'Diagnostic Equipments', slug: 'diagnostic-equipments'),
        CategoryItem(id: 202, name: 'Abbott Medical Device', bnName: 'Abbott Medical Device', slug: 'abbott-medical-device'),
      ],
    ),
    CategoryItem(id: 3, name: 'Baby & Mom Care', bnName: 'Baby & Mom Care', slug: 'baby-mom-care'),
    CategoryItem(id: 4, name: 'Personal & Privacy care', bnName: 'Personal & Privacy care', slug: 'personal-privacy-care'),
    CategoryItem(id: 5, name: 'Sergical & Ortho Care', bnName: 'Sergical & Ortho Care', slug: 'sergical-ortho-care'),
    CategoryItem(id: 6, name: 'Beauty & Lifestyles', bnName: 'Beauty & Lifestyles', slug: 'beauty-lifestyles'),
    CategoryItem(id: 7, name: 'Lab Test', bnName: 'Lab Test', slug: 'lab-test'),
  ];
}

