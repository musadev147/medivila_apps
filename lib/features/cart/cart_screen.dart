import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../common_wigdets/app_toast.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../networks/medivila_api_services.dart';
import '../../provider/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _paymentMethod = 'cod';
  bool _placingOrder = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartProvider cart) async {
    if (cart.isEmpty) {
      AppToast.info('আপনার কার্ট খালি');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.error('দয়া করে আপনার নাম লিখুন');
      return;
    }
    if (!AppConfig.isValidBdPhone(_phoneCtrl.text.trim())) {
      AppToast.error('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন');
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      AppToast.error('ডেলিভারি ঠিকানা লিখুন');
      return;
    }

    setState(() => _placingOrder = true);

    try {
      final orderId = 'MED${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'order_id': orderId,
        'customer_name': _nameCtrl.text.trim(),
        'phone_number': AppConfig.cleanBdPhone(_phoneCtrl.text.trim()),
        'customer_address': _addressCtrl.text.trim(),
        'order_type': 'product',
        'delivery_charge': cart.deliveryCharge,
        'product_price': cart.subtotal,
        'total': cart.grandTotal,
        'payment_method': _paymentMethod,
        'delivery_note': _noteCtrl.text.trim(),
        'items': cart.apiItems,
      };

      await OrdersApi.instance.submitOrder(payload);
      cart.clear();
      setState(() => _placingOrder = false);

      if (mounted) {
        _showOrderSuccessDialog(orderId, cart.grandTotal);
      }
    } catch (e) {
      setState(() => _placingOrder = false);
      AppToast.error('অর্ডার সম্পন্ন করা সম্ভব হয়নি। আবার চেষ্টা করুন।');
    }
  }

  void _showOrderSuccessDialog(String orderId, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 54),
            ),
            SizedBox(height: 12.h),
            Text(
              'অর্ডার সফল হয়েছে!',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('অর্ডার আইডি: $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6.h),
            Text('সর্বমোট: ৳ ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            SizedBox(height: 10.h),
            Text(
              'আমাদের প্রতিনিধি দ্রুত কল করে আপনার ডেলিভারি নিশ্চিত করবেন।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSoft),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
              ),
              child: const Text('হোমে ফিরে যান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'শপিং কার্ট ও চেকআউট',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64.sp, color: AppColors.textMuted),
                  SizedBox(height: 12.h),
                  Text('আপনার কার্ট বর্তমানে খালি', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.textSoft)),
                  SizedBox(height: 6.h),
                  Text('প্রয়োজনীয় ওষুধ বা স্বাস্থ্যসেবা পণ্য কার্টে যোগ করুন', style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prescription alert if needed
                  if (cart.requiresPrescription) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'কার্টের কিছু ওষুধের জন্য ডাক্তারের প্রেসক্রিপশন প্রয়োজন। ডেলিভারির সময় তা প্রস্তুত রাখুন।',
                              style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final line = cart.lines[index];
                      return _buildCartItemCard(cart, line);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // District Delivery Selector
                  _buildDistrictSelector(cart),
                  SizedBox(height: 16.h),

                  // Customer Delivery Information Form
                  _buildCustomerForm(),
                  SizedBox(height: 16.h),

                  // Payment Method Selector
                  _buildPaymentMethodSelector(),
                  SizedBox(height: 16.h),

                  // Pricing Summary Card
                  _buildPriceSummary(cart),
                  SizedBox(height: 20.h),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _placingOrder ? null : () => _submitOrder(cart),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: _placingOrder
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'অর্ডার নিশ্চিত করুন (৳ ${cart.grandTotal.toStringAsFixed(0)})',
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItemCard(CartProvider cart, CartLine line) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              line.thumbnail ?? AppConfig.defaultImageFallback,
              width: 52.w,
              height: 52.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52.w,
                height: 52.w,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.medication, color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: AppColors.accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (line.variantLabel.isNotEmpty)
                  Text(line.variantLabel, style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
                SizedBox(height: 4.h),
                Text(
                  '৳ ${line.unitPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.textSoft,
                onPressed: () => cart.setQuantity(line, line.quantity - 1),
              ),
              Text(
                '${line.quantity}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.primary,
                onPressed: () => cart.setQuantity(line, line.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictSelector(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ডেলিভারি এরিয়া নির্বাচন করুন:',
            style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => cart.setDistrict('ঢাকা সিটি', 60.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: cart.deliveryCharge == 60 ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: cart.deliveryCharge == 60 ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('ঢাকা সিটি', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                        Text('ডেলিভারি: ৳ ৬০', style: TextStyle(fontSize: 10.sp, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: InkWell(
                  onTap: () => cart.setDistrict('ঢাকার বাইরে', 120.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: cart.deliveryCharge == 120 ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: cart.deliveryCharge == 120 ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('ঢাকার বাইরে', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                        Text('ডেলিভারি: ৳ ১২০', style: TextStyle(fontSize: 10.sp, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'গ্রাহকের তথ্য ও ঠিকানা',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'আপনার নাম',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '১১ ডিজিটের মোবাইল নম্বর',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'সম্পূর্ণ ডেলিভারি ঠিকানা',
              hintText: 'বাসা নং, রোড, এলাকা, জেলা',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'পেমেন্ট মাধ্যম',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            SizedBox(height: 8.h),
            RadioListTile<String>(
              value: 'cod',
              groupValue: _paymentMethod,
              title: const Text('ক্যাশ অন ডেলিভারি (Cash on Delivery)'),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            RadioListTile<String>(
              value: 'bkash',
              groupValue: _paymentMethod,
              title: const Text('বিকাশ (bKash Payment)'),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ওষুধের মোট মূল্য:', style: TextStyle(fontSize: 12.sp, color: AppColors.textSoft)),
              Text('৳ ${cart.subtotal.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ডেলিভারি চার্জ (${cart.selectedDistrict}):', style: TextStyle(fontSize: 12.sp, color: AppColors.textSoft)),
              Text('৳ ${cart.deliveryCharge.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('সর্বমোট পরিশোধযোগ্য:', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: AppColors.accent)),
              Text(
                '৳ ${cart.grandTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
