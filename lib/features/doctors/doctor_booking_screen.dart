import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_config.dart';
import '../../models/medivila_models.dart';
import '../../networks/medivila_api_services.dart';
import '../../provider/auth_provider.dart';

class DoctorBookingScreen extends StatefulWidget {
  const DoctorBookingScreen({
    super.key,
    required this.doctor,
    this.onBack,
  });

  final DoctorModel doctor;
  final VoidCallback? onBack;

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  final ScrollController _dateScrollCtrl = ScrollController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _problemCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late List<DateTime> _dates;
  late DateTime _selectedDate;

  List<TimeSlot> _slots = [];
  bool _slotsLoading = false;
  String? _selectedSlot;

  final List<File> _selectedDocuments = [];
  bool _submitting = false;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(14, (i) => now.add(Duration(days: i)));
    _selectedDate = _dates.first;

    // Prefill phone if logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final phone = auth.phoneUser?.phone;
      if (phone != null && phone.isNotEmpty) {
        _phoneCtrl.text = phone;
      }
      _fetchSlotsForDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    _phoneCtrl.dispose();
    _problemCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _slotsLoading = true;
      _selectedSlot = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final slots = await DoctorsApi.instance.getDoctorSlots(
        widget.doctor.id,
        dateStr,
      );

      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        if (slots.isNotEmpty) {
          _slots = slots;
          final firstAvail = slots.where((s) => s.isAvailable).firstOrNull;
          _selectedSlot = firstAvail?.time ?? slots.first.time;
        } else {
          // Fallback slots if backend slots array is empty
          _slots = [
            TimeSlot(time: '6:00 PM - 10:00 PM', isAvailable: true),
            TimeSlot(time: '10:00 AM - 01:00 PM', isAvailable: true),
            TimeSlot(time: '03:00 PM - 05:00 PM', isAvailable: true),
          ];
          _selectedSlot = _slots.first.time;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        _slots = [
          TimeSlot(time: '6:00 PM - 10:00 PM', isAvailable: true),
        ];
        _selectedSlot = _slots.first.time;
      });
    }
  }

  void _scrollDates(bool forward) {
    if (!_dateScrollCtrl.hasClients) return;
    final current = _dateScrollCtrl.offset;
    final target = forward ? current + 160.w : current - 160.w;
    _dateScrollCtrl.animateTo(
      target.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDocuments() async {
    if (_selectedDocuments.length >= 3) {
      AppToast.error('সর্বোচ্চ ৩টি ডকুমেন্ট যোগ করা যাবে');
      return;
    }

    try {
      final pickedList = await _picker.pickMultiImage(
        limit: 3 - _selectedDocuments.length,
        imageQuality: 85,
      );

      if (pickedList.isNotEmpty) {
        setState(() {
          for (final item in pickedList) {
            if (_selectedDocuments.length < 3) {
              _selectedDocuments.add(File(item.path));
            }
          }
        });
      }
    } catch (e) {
      AppToast.error('ডকুমেন্ট সিলেক্ট করতে সমস্যা হয়েছে');
    }
  }

  Future<void> _confirmBooking() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !AppConfig.isValidBdPhone(phone)) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)');
      return;
    }

    if (_selectedSlot == null) {
      AppToast.error('বুকিংয়ের জন্য কোনো সময়সূচি নির্বাচন করা হয়নি');
      return;
    }

    setState(() => _submitting = true);

    try {
      final mapData = <String, dynamic>{
        'doctor_id': widget.doctor.id,
        'patient_phone': AppConfig.cleanBdPhone(phone),
        'problem': _problemCtrl.text.trim(),
        'appointment_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'appointment_time_slot': _selectedSlot,
        'consultation_type': 'video',
      };

      if (_selectedDocuments.isNotEmpty) {
        final docFiles = <MultipartFile>[];
        for (final doc in _selectedDocuments) {
          docFiles.add(await MultipartFile.fromFile(doc.path));
        }
        mapData['medical_documents[]'] = docFiles;
      }

      final formData = FormData.fromMap(mapData);
      final res = await DoctorsApi.instance.bookConsultation(formData);

      if (!mounted) return;
      setState(() => _submitting = false);
      _showBookingSuccessDialog(res);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.error('বুকিং সম্পন্ন করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  void _showBookingSuccessDialog(Map<String, dynamic> res) {
    final booking = res['booking'] as Map? ?? {};
    final bookingId = booking['booking_id']?.toString() ?? 'MD-${DateTime.now().millisecondsSinceEpoch % 100000}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        contentPadding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00A896),
                size: 46,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'বুকিং আইডি:',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        bookingId,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00A896),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Text(
                    'ডাক্তার: ${widget.doctor.formattedName}',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'তারিখ: ${DateFormat('dd MMM, yyyy').format(_selectedDate)}',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'সময়সূচি: $_selectedSlot',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'ফি: ৳ ${widget.doctor.effectiveFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF009640),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'আমাদের প্রতিনিধি শীঘ্রই আপনার সাথে যোগাযোগ করে ভিডিও কলের লিঙ্ক পাঠিয়ে দেবেন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  _handleBack(); // back to list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: _handleBack,
        ),
        title: Text(
          'ডাক্তার অ্যাপয়েন্টমেন্ট',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: TextButton.icon(
              onPressed: _handleBack,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2F1),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: Color(0xFF00796B),
              ),
              label: Text(
                'ডাক্তারদের তালিকা',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00796B),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Breadcrumbs Bar
              _buildBreadcrumbBar(),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildDoctorProfileCard()),
                          SizedBox(width: 16.w),
                          Expanded(flex: 6, child: _buildBookingScheduleCard()),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDoctorProfileCard(),
                          SizedBox(height: 14.h),
                          _buildBookingScheduleCard(),
                          SizedBox(height: 36.h),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 1. Breadcrumb Bar
  Widget _buildBreadcrumbBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home_rounded,
            size: 14.sp,
            color: const Color(0xFF64748B),
          ),
          SizedBox(width: 4.w),
          Text(
            'হোম',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            '  /  স্পেশালিস্ট ডক্টর  /  ',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Expanded(
            child: Text(
              widget.doctor.formattedName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00796B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 2. Doctor Profile Card
  Widget _buildDoctorProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Avatar & Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.r),
                  child: widget.doctor.avatar != null &&
                          widget.doctor.avatar!.isNotEmpty
                      ? Image.network(
                          widget.doctor.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              SizedBox(width: 12.w),

              // Name, Speciality & Degree
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        widget.doctor.displaySpeciality.isNotEmpty
                            ? widget.doctor.displaySpeciality
                            : 'মেডিসিন বিশেষজ্ঞ',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00796B),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.doctor.degrees.isNotEmpty
                          ? widget.doctor.degrees
                          : 'MBBS',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 4 Stats in 2x2 Grid (Exact Match to Screenshot)
          Row(
            children: [
              // 1. Experience
              Expanded(
                child: _buildStatBox(
                  icon: Icons.work_outline_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Experience',
                  value: '${widget.doctor.experienceYears > 0 ? widget.doctor.experienceYears : 5} years',
                ),
              ),
              SizedBox(width: 10.w),

              // 2. Rating
              Expanded(
                child: _buildStatBox(
                  icon: Icons.star_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Rating',
                  value: widget.doctor.rating > 0
                      ? widget.doctor.rating.toStringAsFixed(1)
                      : '4.9',
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          Row(
            children: [
              // 3. Reviews
              Expanded(
                child: _buildStatBox(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Reviews',
                  value: '${widget.doctor.totalReviews > 0 ? widget.doctor.totalReviews : 2}',
                ),
              ),
              SizedBox(width: 10.w),

              // 4. Follow up
              Expanded(
                child: _buildStatBox(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  title: 'Follow up',
                  value: '90 days',
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          SizedBox(height: 14.h),

          // Biography
          Text(
            'Biography',
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.doctor.bio?.trim().isNotEmpty == true
                ? widget.doctor.bio!
                : '${widget.doctor.name} is a renowned medical specialist providing advanced diagnosis and consultations with compassionate care.',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFE0F2F1),
      child: Center(
        child: Icon(
          Icons.medical_services_rounded,
          color: const Color(0xFF00A896),
          size: 32.sp,
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 14.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────── 3. Right Booking & Schedules Card
  Widget _buildBookingScheduleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fee Information Header
          Text(
            'Fee Information',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 8.h),

          // Video Call Fee Box
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF00A896),
                    size: 22,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Call',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Can Make a Video Call with Doctor',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳ ${widget.doctor.effectiveFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Schedules Section with < > Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedules',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
              ),
              Row(
                children: [
                  _buildArrowButton(
                    Icons.chevron_left_rounded,
                    () => _scrollDates(false),
                  ),
                  SizedBox(width: 6.w),
                  _buildArrowButton(
                    Icons.chevron_right_rounded,
                    () => _scrollDates(true),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Horizontal Date Cards (Exact match to Screenshot)
          SizedBox(
            height: 74.h,
            child: ListView.separated(
              controller: _dateScrollCtrl,
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = DateUtils.isSameDay(date, _selectedDate);

                final dayName = DateFormat('EEE').format(date);
                final dayNum = DateFormat('d').format(date);
                final monthYear = DateFormat('MMM, yy').format(date);

                return InkWell(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _fetchSlotsForDate(date);
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 58.w,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00A896)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00A896).withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isSelected
                                ? const Color(0xFF00A896)
                                : const Color(0xFF64748B),
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFF00A896)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          monthYear,
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 18.h),

          // Available Time Header
          Text(
            'Available Time',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 8.h),

          // Time Slots Chips
          if (_slotsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00A896)),
              ),
            )
          else if (_slots.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text(
                'এই তারিখে কোনো সময়সূচি পাওয়া যায়নি',
                style: TextStyle(fontSize: 11.5.sp, color: Colors.grey),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 3.4,
              ),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final isSel = _selectedSlot == slot.time;
                return InkWell(
                  onTap: slot.isAvailable
                      ? () => setState(() => _selectedSlot = slot.time)
                      : null,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFFE0F2F1)
                          : (slot.isAvailable
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSel
                            ? const Color(0xFF00A896)
                            : (slot.isAvailable
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE2E8F0)),
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13.sp,
                            color: isSel
                                ? const Color(0xFF00796B)
                                : const Color(0xFF64748B),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                slot.time,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: isSel
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSel
                                      ? const Color(0xFF00796B)
                                      : (slot.isAvailable
                                          ? const Color(0xFF334155)
                                          : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: 18.h),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          SizedBox(height: 14.h),

          // Booking Information Header
          Text(
            'Booking Information',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 10.h),

          // Contact Number *
          Text(
            'Contact Number *',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 12.5.sp),
            decoration: InputDecoration(
              hintText: 'Phone number',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFF00A896), width: 1.5),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Write Your Problem
          Text(
            'Write Your Problem',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: _problemCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 12.5.sp),
            decoration: InputDecoration(
              hintText: 'e.g. Sleeping Problem',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFF00A896), width: 1.5),
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // Select Medical Documents
          Text(
            'Select Medical Documents',
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),

          // Dashed Upload Container (Exact Match to Screenshot)
          InkWell(
            onTap: _pickDocuments,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Select Medical documents (Prescriptions/ Lab Reports)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Maximum 3 documents (Images or PDFs)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected Document Chips
          if (_selectedDocuments.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: _selectedDocuments.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                final name = file.path.split(Platform.pathSeparator).last;
                return Chip(
                  avatar: const Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: Color(0xFF00796B),
                  ),
                  label: Text(
                    name.length > 15 ? '${name.substring(0, 12)}...' : name,
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  backgroundColor: const Color(0xFFE0F2F1),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _selectedDocuments.removeAt(idx));
                  },
                );
              }).toList(),
            ),
          ],

          SizedBox(height: 20.h),

          // Book Appointment Button
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton(
              onPressed: _submitting ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A896),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        width: 26.w,
        height: 26.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Icon(icon, size: 16.sp, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }
}
