import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;
  final Widget icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final Color labelColor;
  final String? subtitle;
  final Color? subtitleColor;

  const StatCard({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.labelColor,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconTheme(
              data: IconThemeData(size: 17, color: iconColor),
              child: icon,
            ),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                  height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: labelColor)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle!,
                style: TextStyle(
                    fontSize: 10,
                    color: subtitleColor ?? labelColor)),
          ],
        ],
      ),
    );
  }
}
