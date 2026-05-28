import 'dart:convert';

class IpoNotification {
  final String id;
  final String ipoId;
  final String companyName;
  final String type; // 'subscription' | 'listing'
  final DateTime scheduledDate;
  bool isRead;

  IpoNotification({
    required this.id,
    required this.ipoId,
    required this.companyName,
    required this.type,
    required this.scheduledDate,
    this.isRead = false,
  });

  String get typeLabel => type == 'subscription' ? '청약' : '상장';

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return date.difference(today).inDays;
  }

  String get dateLabel =>
      '${scheduledDate.month.toString().padLeft(2, '0')}.${scheduledDate.day.toString().padLeft(2, '0')}';

  String get dDayLabel {
    if (daysLeft <= 0) return 'D-Day';
    return 'D-$daysLeft';
  }

  String get comment {
    if (daysLeft <= 0) return '$companyName $typeLabel D-Day입니다.';
    return '$companyName $typeLabel $daysLeft일 남았습니다.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ipoId': ipoId,
        'companyName': companyName,
        'type': type,
        'scheduledDate': scheduledDate.toIso8601String(),
        'isRead': isRead,
      };

  factory IpoNotification.fromJson(Map<String, dynamic> json) =>
      IpoNotification(
        id: json['id'] as String,
        ipoId: json['ipoId'] as String,
        companyName: json['companyName'] as String,
        type: json['type'] as String,
        scheduledDate: DateTime.parse(json['scheduledDate'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );

  static String encodeList(List<IpoNotification> list) =>
      jsonEncode(list.map((n) => n.toJson()).toList());

  static List<IpoNotification> decodeList(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => IpoNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
