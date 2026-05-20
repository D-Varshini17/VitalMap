import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String status;
  final Widget? trailing;

  const StatusCard({required this.title, required this.subtitle, required this.color, required this.status, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $status. $subtitle',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
              if (trailing != null) ...[SizedBox(height: 8), trailing!]
            ],
          ),
        ),
      ),
    );
  }
}
