import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../models/medivila_models.dart';
import '../../networks/api_access.dart';
import '../../networks/medivila_api_services.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  int _selectedDeptId = 0;
  List<DepartmentModel> _departments = [];
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    if (getDoctorsRx.dataFetcher.valueOrNull == null) {
      getDoctorsRx.fetchDoctors();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final depts = await DoctorsApi.instance.getDepartments();
      if (mounted) setState(() => _departments = depts);
    } catch (_) {
      if (mounted) {
        AppToast.error('বিভাগ লোড করা যায়নি। আবার চেষ্টা করুন।');
      }
    }
  }

  void _onDepartmentSelected(int deptId) {
    setState(() => _selectedDeptId = deptId);
    getDoctorsRx.fetchDoctors(
      departmentId: deptId > 0 ? deptId : null,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'অনলাইন বিশেষজ্ঞ ডাক্তার',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          _buildSearchBar(),

          // 2. Department Filters
          _buildDepartmentFilter(),

          // 3. Doctors List
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: getDoctorsRx.valueStreamData,
              builder: (context, snapshot) {
                final allDoctors = snapshot.data ?? [];
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => getDoctorsRx.fetchDoctors(
                        departmentId: _selectedDeptId > 0
                            ? _selectedDeptId
                            : null,
                        search: _searchQuery.isEmpty ? null : _searchQuery,
                      ),
                      child: const Text('ডাক্তার লোড হয়নি। আবার চেষ্টা করুন।'),
                    ),
                  );
                }
                if (allDoctors.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final doctors = _searchQuery.isEmpty
                    ? allDoctors
                    : allDoctors.where((d) {
                        final q = _searchQuery.toLowerCase();
                        return d.name.toLowerCase().contains(q) ||
                            d.degrees.toLowerCase().contains(q) ||
                            d.specialityTitle.toLowerCase().contains(q) ||
                            d.workplace.toLowerCase().contains(q) ||
                            (d.department?.name.toLowerCase().contains(q) ??
                                false) ||
                            (d.department?.bnName?.toLowerCase().contains(q) ??
                                false);
                      }).toList();

                if (doctors.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 56.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'কোনো ডাক্তার পাওয়া যায়নি',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '"$_searchQuery" সম্পর্কিত কোনো ফলাফল পাওয়া যায়নি।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          OutlinedButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              getDoctorsRx.fetchDoctors(
                                departmentId: _selectedDeptId > 0
                                    ? _selectedDeptId
                                    : null,
                              );
                            },
                            child: const Text('অনুসন্ধান রিসেট করুন'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                  itemCount: doctors.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    return _buildDoctorCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 8.h),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                  getDoctorsRx.fetchDoctors(
                    departmentId: _selectedDeptId > 0 ? _selectedDeptId : null,
                    search: val.trim(),
                  );
                },
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'ডাক্তারের নাম, বিশেষজ্ঞতা বা হাসপাতাল খুঁজুন...',
                  hintStyle: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16.sp,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                  getDoctorsRx.fetchDoctors(
                    departmentId: _selectedDeptId > 0 ? _selectedDeptId : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: SizedBox(
        height: 34.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildFilterChip('সব বিভাগ', 0),
                  ..._departments.map(
                    (d) => _buildFilterChip(d.displayName, d.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int id) {
    final isSelected = _selectedDeptId == id;
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onDepartmentSelected(id),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSoft,
          fontSize: 11.5.sp,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doc) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Doctor Avatar with Online/Available Badge
              _buildDoctorAvatar(doc),
              SizedBox(width: 12.w),

              // 2. Doctor Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            doc.formattedName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                            Text(
                              ' ${doc.rating}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      doc.degrees,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Speciality Pill Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        doc.displaySpeciality,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Experience & Workplace
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 12.sp,
                          color: const Color(0xFF0284C7),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          doc.displayExperience,
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            doc.displayWorkplace,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    // Available Timing
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          doc.displayAvailableTime,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 18, color: Color(0xFFF1F5F9)),

          // 3. Consultation Fee & Calendar Booking Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'পরামর্শ ফি',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '৳ ${doc.effectiveFee.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF009640),
                        ),
                      ),
                      if (doc.discountedFee != null &&
                          doc.discountedFee! > 0 &&
                          doc.consultationFee > doc.discountedFee!) ...[
                        SizedBox(width: 5.w),
                        Text(
                          '৳${doc.consultationFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openBookingModal(doc),
                icon: Icon(Icons.calendar_month_rounded, size: 15.sp),
                label: Text(
                  'অ্যাপয়েন্টমেন্ট নিন',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatar(DoctorModel doc) {
    final hasCustomAvatar =
        doc.avatar != null &&
        doc.avatar!.trim().isNotEmpty &&
        !doc.avatar!.contains('placeholder') &&
        !doc.avatar!.contains('medivila_logo');

    return Stack(
      children: [
        Container(
          width: 76.w,
          height: 90.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasCustomAvatar
              ? Image.network(
                  doc.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDoctorDefaultAvatar(),
                )
              : _buildDoctorDefaultAvatar(),
        ),
        if (doc.isAvailableNow)
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'অনলাইন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDoctorDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.medical_services_rounded,
          color: AppColors.primary,
          size: 38.sp,
        ),
      ),
    );
  }

  void _openBookingModal(DoctorModel doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _DoctorBookingSheet(doctor: doc),
    );
  }
}

class _DoctorBookingSheet extends StatefulWidget {
  const _DoctorBookingSheet({required this.doctor});
  final DoctorModel doctor;

  @override
  State<_DoctorBookingSheet> createState() => _DoctorBookingSheetState();
}

class _DoctorBookingSheetState extends State<_DoctorBookingSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedSlot;
  bool _submitting = false;
  bool _slotsLoading = true;
  List<TimeSlot> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final slots = await DoctorsApi.instance.getDoctorSlots(
        widget.doctor.id,
        date,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _selectedSlot = slots
            .where((slot) => slot.isAvailable)
            .map((slot) => slot.time)
            .firstOrNull;
        _slotsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _slotsLoading = false);
      AppToast.error('সময়-সূচি লোড করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  Future<void> _confirmBooking() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.error('রোগীর নাম লিখুন');
      return;
    }
    if (!AppConfig.isValidBdPhone(_phoneCtrl.text.trim())) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন');
      return;
    }
    if (_selectedSlot == null) {
      AppToast.error('বুকিংয়ের জন্য কোনো সময়-সূচি পাওয়া যায়নি');
      return;
    }

    setState(() => _submitting = true);

    try {
      final formData = FormData.fromMap({
        'doctor_id': widget.doctor.id,
        'patient_name': _nameCtrl.text.trim(),
        'patient_phone': AppConfig.cleanBdPhone(_phoneCtrl.text.trim()),
        'appointment_date': DateTime.now().toIso8601String().substring(0, 10),
        'appointment_time_slot': _selectedSlot,
        'consultation_type': 'video',
      });

      final res = await DoctorsApi.instance.bookConsultation(formData);
      setState(() => _submitting = false);

      if (mounted) {
        Navigator.pop(context);
        _showSuccess(res);
      }
    } catch (_) {
      setState(() => _submitting = false);
      AppToast.error('বুকিং করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  void _showSuccess(Map<String, dynamic> res) {
    final booking = res['booking'] as Map? ?? {};
    final bookingId = booking['booking_id']?.toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        contentPadding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 46.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'বুকিং সফলভাবে সম্পন্ন হয়েছে!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bookingId != null && bookingId.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'বুকিং আইডি:',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          bookingId,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Text(
                    'ডাক্তার: ${widget.doctor.name}',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF132B45),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'সময় ও শিডিউল: $_selectedSlot',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'পরামর্শ ফি: ৳ ${widget.doctor.effectiveFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF009640),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'আমাদের প্রতিনিধি খুব শীঘ্রই আপনার দেওয়া নম্বরে ফোন করে অ্যাপয়েন্টমেন্ট নিশ্চিত করবে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSoft,
                height: 1.35,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: const Text(
                  'ঠিক আছে, ধন্যবাদ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ভিডিও পরামর্শ বুকিং',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            widget.doctor.name,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),

          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'রোগীর নাম',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '১১ ডিজিটের মোবাইল নম্বর',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'পছন্দের সময়সূচি (Slot):',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          if (_slotsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_slots.isEmpty)
            const Text('এই তারিখে কোনো সময়-সূচি পাওয়া যায়নি')
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _slots.map((slot) {
                final isSel = _selectedSlot == slot.time;
                return ChoiceChip(
                  label: Text(slot.time),
                  selected: isSel,
                  onSelected: slot.isAvailable
                      ? (_) => setState(() => _selectedSlot = slot.time)
                      : null,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppColors.text,
                    fontSize: 10.5.sp,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 18.h),

          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton(
              onPressed: _submitting || _slotsLoading || _selectedSlot == null
                  ? null
                  : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'বুকিং নিশ্চিত করুন (৳ ${widget.doctor.effectiveFee.toStringAsFixed(0)})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
