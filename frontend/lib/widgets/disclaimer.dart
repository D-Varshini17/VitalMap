import 'package:flutter/material.dart';

import '../styles.dart';
import 'brand_logo.dart';

class DisclaimerWidget extends StatelessWidget {
  const DisclaimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppStyles.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogoMark(size: 34),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VitalMap Safety Note',
                    style: TextStyle(
                        color: AppStyles.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.',
                  style: TextStyle(
                      fontSize: 12, color: AppStyles.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
