import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../networks/medivila_api_services.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  File? _imageFile;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      AppToast.error('ছবি নির্বাচন করতে সমস্যা হয়েছে');
    }
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      AppToast.error('অনুগ্রহ করে প্রেসক্রিপশনের ছবি সিলেক্ট করুন');
      return;
    }

    setState(() => _uploading = true);

    try {
      final res = await PrescriptionApi.instance.uploadPrescription(
        name: _nameCtrl.text.trim(),
        phone: AppConfig.cleanBdPhone(_phoneCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
        filePath: _imageFile!.path,
      );

      setState(() => _uploading = false);

      if (mounted) {
        _showSuccessDialog(res['message'] ?? 'প্রেসক্রিপশন সফলভাবে জমা দেওয়া হয়েছে!');
      }
    } catch (e) {
      setState(() => _uploading = false);
      AppToast.error('আপলোড ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
            ),
            SizedBox(height: 12.h),
            Text(
              'ধন্যবাদ!',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSoft, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            ),
            child: const Text('হোমে ফিরে যান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'প্রেসক্রিপশন আপলোড',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'আমাদের রেজিস্টার্ড ফার্মাসিস্ট আপনার প্রেসক্রিপশন যাচাই করে নিশ্চিত কল করবেন।',
                        style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF1B5E20), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // Image Picker Area
              Text(
                'প্রেসক্রিপশনের ছবি সিলেক্ট করুন *',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
              SizedBox(height: 8.h),
              InkWell(
                onTap: () => _showPickerSheet(),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  height: 180.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => setState(() => _imageFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                              child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 30.sp),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'ক্যামেরা অথবা গ্যালারি থেকে ছবি আপলোড করুন',
                              style: TextStyle(fontSize: 12.sp, color: AppColors.textSoft, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'JPG, PNG, PDF (সর্বোচ্চ ৫ মেগাবাইট)',
                              style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 18.h),

              // Patient Name
              Text(
                'রোগীর / আপনার নাম *',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'দয়া করে নাম প্রদান করুন' : null,
                decoration: InputDecoration(
                  hintText: 'যেমন: মোহাম্মদ রহিম',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 14.h),

              // Phone Number
              Text(
                'মোবাইল নম্বর (১১ ডিজিট) *',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'মোবাইল নম্বর প্রদান করুন';
                  if (!AppConfig.isValidBdPhone(v)) return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন 017xxxxxxxx)';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 14.h),

              // Special Notes
              Text(
                'বিশেষ নির্দেশনা / ঔষধের মেয়াদ (ঐচ্ছিক)',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'যেমন: ১ মাসের ওষুধ দিন অথবা নির্দিষ্ট ব্র্যান্ড উল্লেখ করুন...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 24.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _submitPrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(
                          'প্রেসক্রিপশন জমা দিন',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ছবি আপলোডের উৎস নির্বাচন করুন',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(Icons.camera_alt_rounded, 'ক্যামেরা', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  }),
                  _buildSourceButton(Icons.photo_library_rounded, 'গ্যালারি', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: AppColors.primary),
            SizedBox(height: 6.h),
            Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
