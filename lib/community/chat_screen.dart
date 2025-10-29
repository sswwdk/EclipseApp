import 'package:flutter/material.dart';
import '../widgets/common_dialogs.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? post;

  const ChatScreen({
    super.key,
    required this.user,
    this.post,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 샘플 채팅 데이터
  List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': '안녕하세요! 게시글 잘 봤어요',
      'isMe': true,
      'time': '14:30',
    },
    {
      'id': '2',
      'text': '안녕하세요! 관심 가져주셔서 감사해요',
      'isMe': false,
      'time': '14:32',
    },
    {
      'id': '3',
      'text': '같이 가고 싶은데 언제 가시나요?',
      'isMe': true,
      'time': '14:33',
    },
    {
      'id': '4',
      'text': '이번 주말에 가려고 해요! 같이 가실래요?',
      'isMe': false,
      'time': '14:35',
    },
  ];

  @override
  void initState() {
    super.initState();
    // 게시글 정보가 있으면 첫 메시지로 추가
    if (widget.post != null) {
      _messages.insert(0, {
        'id': '0',
        'text': '${widget.post!['title']} 게시글에 대해 문의드려요',
        'isMe': true,
        'time': '14:25',
        'isSystemMessage': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // 프로필 이미지
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user['nickname'],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              _showChatMenu();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: Column(
        children: [
          // 게시글 정보 (있는 경우)
          if (widget.post != null) _buildPostInfo(),
          
          // 채팅 메시지들
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // 메시지 입력창
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8126).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF8126).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.article,
            color: const Color(0xFFFF8126),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.post!['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8126),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final isSystemMessage = message['isSystemMessage'] as bool? ?? false;

    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message['text'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF8126) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8126),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage(_messageController.text.trim());
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8126),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isMe': true,
        'time': _formatTime(DateTime.now()),
      });
    });

    _messageController.clear();
    
    // 스크롤을 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('사용자 차단'),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('사용자 신고'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    CommonDialogs.showBlockConfirmation(
      context: context,
      title: '사용자 차단',
      content: '${widget.user['nickname']}님을 차단하시겠습니까?',
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.user['nickname']}님을 차단했습니다'),
            backgroundColor: const Color(0xFFFF8126),
          ),
        );
      },
    );
  }

  void _showReportDialog() {
    CommonDialogs.showReportConfirmation(
      context: context,
      title: '사용자 신고',
      content: '${widget.user['nickname']}님을 신고하시겠습니까?',
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.user['nickname']}님을 신고했습니다'),
            backgroundColor: const Color(0xFFFF8126),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
