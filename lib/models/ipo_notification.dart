import 'dart:convert';

class IpoNotification {
  final String id;
  final String ipoId;
  final String companyName;
  final String type; // 'subscription' | 'listing'
  final DateTime scheduledDate;
  bool isRead;
  final String? content; // 백엔드에서 제공하는 알림 내용

  IpoNotification({
    required this.id,
    required this.ipoId,
    required this.companyName,
    required this.type,
    required this.scheduledDate,
    this.isRead = false,
    this.content,
  });

  // 백엔드 content 형식: "삼성전자 청약이 오늘 시작됩니다."
  static String _extractCompanyName(String content) {
    if (content.contains(' 청약이')) return content.split(' 청약이')[0];
    if (content.contains(' 상장일이')) return content.split(' 상장일이')[0];
    return content.split(' ').first;
  }

  factory IpoNotification.fromApi(Map<String, dynamic> json) {
    final apiContent = json['content'] as String? ?? '';
    final apiType = json['type'] as String? ?? '';
    final type = apiType == 'LISTING_DATE' ? 'listing' : 'subscription';
    return IpoNotification(
      id: json['notificationId'].toString(),
      ipoId: json['ipoId']?.toString() ?? '',
      companyName: _extractCompanyName(apiContent),
      type: type,
      scheduledDate: DateTime.parse(json['createdAt'] as String),
      isRead: json['read'] as bool? ?? false,
      content: apiContent,
    );
  }

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
    if (content != null && content!.isNotEmpty) return content!;
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
        if (content != null) 'content': content,
      };

  factory IpoNotification.fromJson(Map<String, dynamic> json) =>
      IpoNotification(
        id: json['id'] as String,
        ipoId: json['ipoId'] as String,
        companyName: json['companyName'] as String,
        type: json['type'] as String,
        scheduledDate: DateTime.parse(json['scheduledDate'] as String),
        isRead: json['isRead'] as bool? ?? false,
        content: json['content'] as String?,
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
