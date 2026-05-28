import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';


class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  int _feedbackState = 0; // 0: none, 1: like, -1: dislike
  bool _feedbackSubmitted = false;
  int? _selectedReason;
  List<({String text, bool isTable})> _splitMarkdownSegments(String markdown) {
    final lines = markdown.split('\n');
    final result = <({String text, bool isTable})>[];
    final buffer = StringBuffer();
    bool inTable = false;

    for (final line in lines) {
      final isTableLine = line.trim().startsWith('|');
      if (isTableLine != inTable) {
        final block = buffer.toString().trim();
        if (block.isNotEmpty) {
          result.add((text: block, isTable: inTable));
        }
        buffer.clear();
        inTable = isTableLine;
      }
      buffer.writeln(line);
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      result.add((text: remaining, isTable: inTable));
    }

    return result;
  }

  Widget _buildNativeTable(String tableMarkdown) {
    final lines = tableMarkdown.trim().split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 3) return MarkdownBody(data: tableMarkdown);

    List<String> parseRow(String line) => line
        .split('|')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final headers = parseRow(lines[0]);
    final colCount = headers.length;
    final rows = lines.sublist(2).map((l) {
      final cells = parseRow(l);
      // 열 수 맞추기
      while (cells.length < colCount) { cells.add(''); }
      return cells.take(colCount).toList();
    }).toList();

    const cellPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    const headerStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    );
    const bodyStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textDark,
    );

    TableRow makeRow(List<String> cells, TextStyle style, {Color? bg}) =>
        TableRow(
          decoration: bg != null ? BoxDecoration(color: bg) : null,
          children: cells.map((c) => Padding(
            padding: cellPadding,
            child: Text(c, style: style),
          )).toList(),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: AppColors.borderGray, width: 1),
        children: [
          makeRow(headers, headerStyle, bg: const Color(0xFFF0F4FF)),
          ...rows.map((r) => makeRow(r, bodyStyle)),
        ],
      ),
    );
  }

  static final _bracketRegex = RegExp(r'\[([^\[\]]+)\](?!\()');

  String _preprocessHighlights(String text) =>
      text.replaceAllMapped(_bracketRegex, (m) => '`${m[1]}`');

  Widget _markdownBody(String data, MarkdownStyleSheet style) => MarkdownBody(
        data: _preprocessHighlights(data),
        styleSheet: style,
      );

  Widget _buildMarkdownContent(String data, MarkdownStyleSheet style) {
    final segments = _splitMarkdownSegments(data);
    if (segments.length == 1 && !segments.first.isTable) {
      return _markdownBody(data, style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final seg in segments)
          if (seg.isTable)
            _buildNativeTable(seg.text)
          else if (seg.text.isNotEmpty)
            _markdownBody(seg.text, style),
      ],
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle({
    required Color textColor,
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.4,
  }) {
    final baseTextStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: fontSize,
      color: textColor,
      height: height,
    );
    return MarkdownStyleSheet(
      p: baseTextStyle.copyWith(fontWeight: fontWeight),
      strong: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
      h1: baseTextStyle.copyWith(fontSize: fontSize + 4, fontWeight: FontWeight.w800),
      h2: baseTextStyle.copyWith(fontSize: fontSize + 2, fontWeight: FontWeight.w800),
      h3: baseTextStyle.copyWith(fontSize: fontSize + 1, fontWeight: FontWeight.w800),
      h4: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
      h5: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
      h6: baseTextStyle.copyWith(fontWeight: FontWeight.w800),
      listBullet: baseTextStyle.copyWith(fontWeight: fontWeight),
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 20,
      blockSpacing: 10,
      a: baseTextStyle.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary,
      ),
      code: baseTextStyle.copyWith(
        fontWeight: FontWeight.w600,
        backgroundColor: AppColors.primary.withOpacity(0.1),
      ),
      blockquote: baseTextStyle.copyWith(
        color: AppColors.textLightGray,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.bgGray,
        border: const Border(
          left: BorderSide(color: AppColors.borderGray, width: 4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }


  void _copyToClipboard() {
    String copyText = widget.message.text;
    if (widget.message.aiSummaryData != null) {
      widget.message.aiSummaryData!.forEach((k, v) => copyText += '\n- $k: $v');
    }
    if (widget.message.aiSecondaryText != null) {
      copyText += '\n\n${widget.message.aiSecondaryText}';
    }
    
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('클립보드에 복사되었습니다.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: MarkdownBody(
          data: widget.message.text,
          styleSheet: _buildMarkdownStyle(
            textColor: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Title
                const SizedBox(height: 6),
                _buildMarkdownContent(
                  widget.message.text,
                  _buildMarkdownStyle(
                    textColor: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                
                if (widget.message.aiSummaryData != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgLightBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.message.aiSummaryData!.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDark,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                TextSpan(text: e.value, style: const TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                if (widget.message.aiSecondaryText != null) ...[
                  const SizedBox(height: 16),
                  _buildMarkdownContent(
                    widget.message.aiSecondaryText!,
                    _buildMarkdownStyle(
                      textColor: AppColors.textBody,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Active Toolbar
                Row(
                  children: [
                    _buildIconButton(
                      icon: _feedbackState == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                      isActive: _feedbackState == 1,
                      onTap: () async {
                        final previousState = _feedbackState;
                        setState(() {
                          _feedbackState = _feedbackState == 1 ? 0 : 1;
                        });
                        if (_feedbackState == 1) {
                          try {
                            await ChatService().submitFeedback(
                              messageId: widget.message.id,
                              feedbackType: 'LIKE',
                            );
                          } catch (_) {
                            setState(() {
                              _feedbackState = previousState;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: _feedbackState == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                      isActive: _feedbackState == -1,
                      onTap: () {
                        setState(() {
                          if (_feedbackState == -1) {
                            _feedbackState = 0;
                            _feedbackSubmitted = false;
                          } else {
                            _feedbackState = -1;
                            _feedbackSubmitted = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.copy_outlined,
                      isActive: false,
                      onTap: _copyToClipboard,
                    ),
                  ],
                ),
                
                // Feedback Form
                if (_feedbackState == -1 && !_feedbackSubmitted)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '어떤 점이 아쉬우셨나요?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRadioOption(0, '공모가, 일정 등 정보가 부정확해요'),
                        const SizedBox(height: 4),
                        _buildRadioOption(1, '내용이 너무 복잡하고 어려워요'),
                        const SizedBox(height: 4),
                        _buildRadioOption(2, '질문의 의도와 다른 엉뚱한 답변이에요'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              if (_selectedReason == null) return;
                              final int reasonIdx = _selectedReason!;
                              final reasonCodes = [
                                'INACCURATE_INFO',
                                'TOO_COMPLEX',
                                'IRRELEVANT_ANSWER'
                              ];
                              final reasonDetails = [
                                '공모가, 일정 등 정보가 부정확해요',
                                '내용이 너무 복잡하고 어려워요',
                                '질문의 의도와 다른 엉뚱한 답변이에요'
                              ];
                              
                              setState(() {
                                _feedbackSubmitted = true;
                              });

                              try {
                                await ChatService().submitFeedback(
                                  messageId: widget.message.id,
                                  feedbackType: 'DISLIKE',
                                  reasonCode: reasonCodes[reasonIdx],
                                  reasonDetail: reasonDetails[reasonIdx],
                                );
                              } catch (_) {
                                // Ignore or handle silently
                              }

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('소중한 의견이 제출되었습니다.'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '제출하기',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(int value, String label) {
    bool isSelected = _selectedReason == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textLightGray,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.white : AppColors.textLightGray,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.message.isUser ? _buildUserBubble() : _buildAiBubble();
  }
}
