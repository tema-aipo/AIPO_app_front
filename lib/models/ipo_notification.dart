import 'dart:convert';

class IpoNotification {
  final String id;
  final String ipoId;
  final String companyName;
  final String type; // 'subscription' | 'listing'
  final DateTime scheduledDate; // 청약/상장 대상일
  final DateTime createdAt; // 알림 생성일
  bool isRead;
  final String? title;
  final String? content;

  IpoNotification({
    required this.id,
    required this.ipoId,
    required this.companyName,
    required this.type,
    required this.scheduledDate,
    DateTime? createdAt,
    this.isRead = false,
    this.title,
    this.content,
  }) : createdAt = createdAt ?? scheduledDate;

  static String _extractCompanyName(String content) {
    if (content.contains(' 청약')) return content.split(' 청약')[0];
    if (content.contains(' 상장')) return content.split(' 상장')[0];
    return content.split(' ').first;
  }

  factory IpoNotification.fromApi(Map<String, dynamic> json) {
    final apiContent = json['content'] as String? ?? '';
    final apiTitle = json['title'] as String?;
    final apiType = json['type'] as String? ?? '';
    final type = apiType == 'LISTING_DATE' ? 'listing' : 'subscription';
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final targetDate = json['targetDate'] as String?;

    return IpoNotification(
      id: json['notificationId'].toString(),
      ipoId: json['ipoId']?.toString() ?? '',
      companyName: _extractCompanyName(apiContent),
      type: type,
      scheduledDate: targetDate == null ? createdAt : DateTime.parse(targetDate),
      createdAt: createdAt,
      isRead: json['read'] as bool? ?? false,
      title: apiTitle,
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
      '${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';

  String get dDayLabel {
    if (daysLeft <= 0) return 'D-Day';
    return 'D-$daysLeft';
  }

  String get comment {
    if (content != null && content!.isNotEmpty) return content!;
    if (title != null && title!.isNotEmpty) return title!;
    if (daysLeft <= 0) return '$companyName $typeLabel D-Day입니다.';
    return '$companyName $typeLabel $daysLeft일 남았습니다.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ipoId': ipoId,
        'companyName': companyName,
        'type': type,
        'scheduledDate': scheduledDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
      };

  factory IpoNotification.fromJson(Map<String, dynamic> json) =>
      IpoNotification(
        id: json['id'] as String,
        ipoId: json['ipoId'] as String,
        companyName: json['companyName'] as String,
        type: json['type'] as String,
        scheduledDate: DateTime.parse(json['scheduledDate'] as String),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        isRead: json['isRead'] as bool? ?? false,
        title: json['title'] as String?,
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
