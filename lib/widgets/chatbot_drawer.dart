import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';

class ChatbotDrawer extends StatefulWidget {
  final VoidCallback onNewChat;
  final Function(String) onLoadChat;
  final String? currentSessionId;
  final VoidCallback? onCurrentSessionDeleted;
  final bool hasMessages;

  const ChatbotDrawer({
    super.key,
    required this.onNewChat,
    required this.onLoadChat,
    this.currentSessionId,
    this.onCurrentSessionDeleted,
    this.hasMessages = false,
  });

  @override
  State<ChatbotDrawer> createState() => _ChatbotDrawerState();
}

class _ChatbotDrawerState extends State<ChatbotDrawer> {
  final ChatService _chatService = ChatService.instance;
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  @override
  void didUpdateWidget(ChatbotDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasMessages && widget.hasMessages) {
      _fetchSessions();
    }
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _chatService.getSessions();
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePin(String sessionId, bool currentlyPinned) async {
    try {
      await _chatService.pinSession(sessionId, !currentlyPinned);
      _fetchSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('고정 상태 변경 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 대화 내역을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _chatService.deleteSession(sessionId);
      _fetchSessions();
      if (sessionId == widget.currentSessionId) {
        if (mounted) Navigator.pop(context);
        widget.onCurrentSessionDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('대화 삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllRecentSessions() async {
    final unpinnedSessions = _sessions.where((s) => s['pinned'] != true).toList();
    if (unpinnedSessions.isEmpty) {
      _showSnackBar('삭제할 최근 기록이 없습니다.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('북마크(고정)된 대화를 제외한 모든 최근 기록을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final deletedIds = unpinnedSessions.map((s) => s['sessionId'].toString()).toList();
      // Delete unpinned sessions in parallel
      await Future.wait(unpinnedSessions.map((s) => _chatService.deleteSession(s['sessionId'].toString())));
      await _fetchSessions();
      
      if (widget.currentSessionId != null && deletedIds.contains(widget.currentSessionId)) {
        if (mounted) Navigator.pop(context);
        widget.onCurrentSessionDeleted?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('기록 삭제 실패: $e');
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _buildSessionItem(dynamic session) {
    final bool isPinned = session['pinned'] == true;
    
    Decoration? itemDecoration;
    EdgeInsetsGeometry? itemMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 2);
    EdgeInsetsGeometry itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Container(
      margin: itemMargin,
      decoration: itemDecoration,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onLoadChat(session['sessionId'].toString());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: itemPadding,
          child: Row(
            children: [
              Icon(
                isPinned ? Icons.bookmark_rounded : Icons.chat_bubble_outline, 
                size: 18, 
                color: isPinned ? AppColors.primary : AppColors.textGray
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session['title'] ?? '제목 없는 대화',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPinned ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18,
                  color: isPinned ? AppColors.primary : AppColors.textGray.withOpacity(0.5),
                ),
                onPressed: () => _togglePin(session['sessionId'].toString(), isPinned),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: isPinned ? AppColors.textGray.withOpacity(0.5) : AppColors.primaryRed,
                ),
                onPressed: () => _deleteSession(session['sessionId'].toString()),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excludeId = (!widget.hasMessages && widget.currentSessionId != null)
        ? widget.currentSessionId
        : null;
    final pinnedSessions = <dynamic>[];
    final recentSessions = <dynamic>[];
    for (final s in _sessions) {
      if (s['lastMessagePreview'] == null) continue;
      if (excludeId != null && s['sessionId'].toString() == excludeId) continue;
      (s['pinned'] == true ? pinnedSessions : recentSessions).add(s);
    }

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onNewChat();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgLightBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_comment_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text(
                        '새 채팅 시작하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Divider(height: 1),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? const Center(
                          child: Text(
                            '대화 기록이 없습니다.',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pinnedSessions.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  child: Text(
                                    '북마크',
                                    style: TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...pinnedSessions.map((s) => _buildSessionItem(s)),
                                const SizedBox(height: 16),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Text(
                                  '최근 기록',
                                  style: TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (recentSessions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Text(
                                    '최근 대화 기록이 없습니다.',
                                    style: TextStyle(
                                      color: AppColors.textGray,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else
                                ...recentSessions.map((s) => _buildSessionItem(s)),
                            ],
                          ),
                        ),
            ),
            
            const Divider(height: 1),
            
            // 모든 기록 삭제
            Padding(
              padding: const EdgeInsets.all(20),
              child: InkWell(
                onTap: _deleteAllRecentSessions,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '모든 기록 삭제',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
