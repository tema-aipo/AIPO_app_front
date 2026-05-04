import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChatHistoryItem {
  final String id;
  final String title;
  bool isPinned;

  ChatHistoryItem({
    required this.id,
    required this.title,
    this.isPinned = false,
  });
}

class ChatbotDrawer extends StatefulWidget {
  final VoidCallback? onNewChat;
  final Function(String)? onLoadChat;
  
  const ChatbotDrawer({super.key, this.onNewChat, this.onLoadChat});

  @override
  State<ChatbotDrawer> createState() => _ChatbotDrawerState();
}

class _ChatbotDrawerState extends State<ChatbotDrawer> {
  String _searchQuery = '';
  
  final List<ChatHistoryItem> _history = [
    ChatHistoryItem(id: '1', title: '스페이스테크놀로지 수요예측 결과', isPinned: true),
    ChatHistoryItem(id: '2', title: '나의 성향 맞춤 종목 추천', isPinned: false),
    ChatHistoryItem(id: '3', title: '바이오메디컬 상장일 주가', isPinned: false),
  ];

  void _togglePin(String id) {
    setState(() {
      final item = _history.firstWhere((e) => e.id == id);
      item.isPinned = !item.isPinned;
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _history.removeWhere((e) => e.id == id);
    });
  }

  void _deleteAll() {
    setState(() {
      _history.removeWhere((e) => !e.isPinned);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _searchQuery.isEmpty 
        ? _history 
        : _history.where((e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final pinnedItems = filteredHistory.where((e) => e.isPinned).toList();
    final recentItems = filteredHistory.where((e) => !e.isPinned).toList();

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Section (Search & New Chat)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppColors.textLightGray),
                        hintText: '채팅 검색',
                        hintStyle: TextStyle(color: AppColors.textLightGray, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context); // close drawer and mock "new chat"
                      if (widget.onNewChat != null) {
                        widget.onNewChat!();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.edit_square, color: AppColors.textDark, size: 20),
                          SizedBox(width: 12),
                          Text(
                            '새 채팅',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pinnedItems.isNotEmpty)
                      ...[
                        const Text(
                          '북마크',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...pinnedItems.map((e) => _buildHistoryItem(e)),
                        const SizedBox(height: 24),
                      ],
                    if (recentItems.isNotEmpty)
                      ...[
                        const Text(
                          '최근 기록',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...recentItems.map((e) => _buildHistoryItem(e)),
                      ],
                  ],
                ),
              ),
            ),

            // Bottom Section (Delete All)
            const Divider(color: AppColors.borderGray, height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: InkWell(
                onTap: _deleteAll,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 20),
                      SizedBox(width: 12),
                      Text(
                        '모든 기록 삭제',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

  Widget _buildHistoryItem(ChatHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppColors.textGray, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (widget.onLoadChat != null) {
                  widget.onLoadChat!(item.id);
                }
              },
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _togglePin(item.id),
            child: Icon(
              item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: item.isPinned ? AppColors.primary : AppColors.textLightGray,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _deleteItem(item.id),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.textLightGray,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
