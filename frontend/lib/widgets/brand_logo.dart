import 'package:flutter/material.dart';

import '../styles.dart';

class BrandLogoMark extends StatelessWidget {
  final double size;
  final bool glow;

  const BrandLogoMark({super.key, this.size = 34, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppStyles.softBlueBorder),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppStyles.accent.withValues(alpha: 0.32),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: Image.asset(AppStyles.logoAsset, fit: BoxFit.contain),
      ),
    );
  }
}

class BrandAppBarTitle extends StatelessWidget {
  final String title;

  const BrandAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogoMark(size: 32),
        const SizedBox(width: 9),
        Text(title),
      ],
    );
  }
}
