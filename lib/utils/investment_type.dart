import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Map<String, Color> getBadgeColors(String rawType) {
  final cleanType = rawType.startsWith('#') ? rawType : '#$rawType';
  if (cleanType == '#안정형') {
    return {'bg': AppColors.bgLightBlue, 'text': AppColors.primary};
  } else if (cleanType == '#공격형') {
    return {
      'bg': const Color(0xFFFFEAEA),
      'text': const Color(0xFFD32F2F),
    };
  } else if (cleanType == '#중립형') {
    return {
      'bg': const Color(0xFFE2F6EA),
      'text': const Color(0xFF107C41),
    };
  } else {
    return {'bg': const Color(0xFFF3F3F3), 'text': AppColors.textGray};
  }
}
