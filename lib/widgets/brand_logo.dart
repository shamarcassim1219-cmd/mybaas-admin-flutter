import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The "GO[BAAS]" wordmark, with a small "Admin" tag underneath to
/// distinguish this app from the customer/Baas apps sharing the
/// same brand.
class BrandLogo extends StatelessWidget {
  final double fontSize;
  final bool showAdminTag;

  const BrandLogo({super.key, this.fontSize = 28, this.showAdminTag = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(text: 'GO'),
              TextSpan(text: 'BAAS', style: TextStyle(color: AppColors.accent)),
            ],
          ),
        ),
        if (showAdminTag) ...[
          const SizedBox(height: 2),
          Text(
            'ADMIN',
            style: TextStyle(
              fontSize: fontSize * 0.28,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 3,
            ),
          ),
        ],
      ],
    );
  }
}
