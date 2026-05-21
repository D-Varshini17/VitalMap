import 'package:flutter/material.dart';

import '../styles.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String status;
  final Widget? trailing;

  const StatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = AppStyles.statusStyle(status);
    return Semantics(
      container: true,
      label: '$title. ${statusStyle.label}. $subtitle',
      child: Card(
        color: statusStyle.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: statusStyle.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusStyle.icon, color: statusStyle.accent),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: statusStyle.text)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                    color: statusStyle.badgeBackground,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(statusStyle.label,
                    style: TextStyle(
                        color: statusStyle.text, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: AppStyles.muted),
                  textAlign: TextAlign.center),
              if (trailing != null) ...[const SizedBox(height: 8), trailing!]
            ],
          ),
        ),
      ),
    );
  }
}
