import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (status) {
      '수요예측' || 'DEMAND_FORECAST'          => (const Color(0xFFFFEAEA), const Color(0xFFD32F2F)),
      '상장'    || 'LISTED'                   => (const Color(0xFFE2F6EA), const Color(0xFF107C41)),
      '청약종료' || 'SUBSCRIPTION_CLOSED'      => (const Color(0xFFF3F3F3), AppColors.textGray),
      '환불'                                   => (const Color(0xFFFFF4E8), const Color(0xFFFF5E00)),
      _                                        => (AppColors.bgLightBlue, AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
