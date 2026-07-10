import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UsageLimitProgressBar extends StatelessWidget {
  final String title;
  final int used;
  final int limit;
  final IconData icon;

  const UsageLimitProgressBar({
    super.key,
    required this.title,
    required this.used,
    required this.limit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    double progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    bool isDanger = progress >= 0.9;
    bool isWarning = progress >= 0.7 && !isDanger;

    Color progressColor = isDanger 
        ? AppTheme.danger 
        : (isWarning ? Colors.orangeAccent : AppTheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: progressColor.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: progressColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$used / $limit',
                style: GoogleFonts.outfit(
                  color: progressColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
