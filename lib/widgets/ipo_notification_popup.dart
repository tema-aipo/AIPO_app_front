import 'package:flutter/material.dart';
import '../models/ipo_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class IpoNotificationPopup extends StatefulWidget {
  const IpoNotificationPopup({super.key});

  @override
  State<IpoNotificationPopup> createState() => _IpoNotificationPopupState();
}

class _IpoNotificationPopupState extends State<IpoNotificationPopup> {
  bool _dontShowAgain = false;

  static const Color _subscriptionColor = AppColors.primary;
  static const Color _subscriptionBg = AppColors.bgLightBlue;
  static const Color _listingColor = Color(0xFF107C41);
  static const Color _listingBg = Color(0xFFE2F6EA);

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    final subList = service.popupNotifications
        .where((n) => n.type == 'subscription')
        .toList();
    final lstList = service.popupNotifications
        .where((n) => n.type == 'listing')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (subList.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.how_to_vote_outlined,
                        label: '청약 임박',
                        color: _subscriptionColor,
                        bg: _subscriptionBg,
                      ),
                      const SizedBox(height: 10),
                      ...subList.map((n) => _buildNotificationItem(
                            n,
                            accentColor: _subscriptionColor,
                          )),
                    ],
                    if (subList.isNotEmpty && lstList.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.borderGray),
                      ),
                    if (lstList.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.trending_up_rounded,
                        label: '상장 임박',
                        color: _listingColor,
                        bg: _listingBg,
                      ),
                      const SizedBox(height: 10),
                      ...lstList.map((n) => _buildNotificationItem(
                            n,
                            accentColor: _listingColor,
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgLightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          '공모주 일정 알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(IpoNotification n,
      {required Color accentColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.companyName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  n.comment,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLightGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                n.dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  n.dDayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _dontShowAgain,
                  onChanged: (v) =>
                      setState(() => _dontShowAgain = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '다시 보지 않기',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLightGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await NotificationService.instance.confirmPopup(
                dontShowAgain: _dontShowAgain,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
