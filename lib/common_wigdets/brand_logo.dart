import 'package:flutter/material.dart';

const brandLogoAsset = 'assets/images/playstore.png';

/// Medivila Brand Logo
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 42,
    this.card = false,
  });

  final double height;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      brandLogoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_pharmacy_rounded, color: const Color(0xFF009640), size: height * 0.8),
          const SizedBox(width: 8),
          Text(
            'মেডিভিলা',
            style: TextStyle(
              fontSize: height * 0.45,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF132B45),
            ),
          ),
        ],
      ),
    );

    if (!card) return img;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: height * .2, vertical: height * .12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height * .25),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: img,
    );
  }
}
