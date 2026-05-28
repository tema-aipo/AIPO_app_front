import 'package:flutter/material.dart';
import '../models/ipo_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _subscriptionColor = AppColors.primary;
  static const Color _subscriptionBg = AppColors.bgLightBlue;
  static const Color _listingColor = Color(0xFF107C41);
  static const Color _listingBg = Color(0xFFE2F6EA);

  @override
  void initState() {
    super.initState();
    NotificationService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.white,
        title: const Text(
          '알림 전체 삭제',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '모든 알림을 삭제하시겠습니까?',
          style: TextStyle(fontSize: 14, color: AppColors.textLightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textLightGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService.instance.deleteAll();
    }
  }

  List<IpoNotification> get _sortedNotifications {
    final list = List<IpoNotification>.from(
        NotificationService.instance.notifications);
    // 미읽음 먼저, 같은 상태 내 날짜 가까운 순
    list.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return a.scheduledDate.compareTo(b.scheduledDate);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _sortedNotifications;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _confirmDeleteAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(right: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '전체삭제',
                style: TextStyle(
                  color: AppColors.textLightGray,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: AppColors.borderGray),
        ),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderGray,
                  indent: 20,
                  endIndent: 20),
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_off_outlined,
                color: AppColors.textGray, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '관심 공모주의 청약·상장 일정을\n여기서 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textLightGray),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(IpoNotification n) {
    final isSubscription = n.type == 'subscription';
    final accentColor = isSubscription ? _subscriptionColor : _listingColor;
    final accentBg = isSubscription ? _subscriptionBg : _listingBg;
    final isRead = n.isRead;

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: const Color(0xFFFFEAEA),
        child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
      ),
      onDismissed: (_) {
        NotificationService.instance.deleteNotification(n.id);
      },
      child: InkWell(
        onTap: isRead
            ? null
            : () => NotificationService.instance.markAsRead(n.id),
        child: Opacity(
          opacity: isRead ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타입 뱃지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    n.typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            n.companyName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isRead
                                  ? AppColors.textGray
                                  : AppColors.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                n.dateLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGray,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(isRead ? 0.06 : 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  n.dDayLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isRead
                                        ? AppColors.textGray
                                        : accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.comment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLightGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
