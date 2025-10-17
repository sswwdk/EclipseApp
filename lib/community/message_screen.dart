import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '쪽지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 첫 번째 쪽지
          _buildMessageCard(
            senderName: '맛잘알',
            lastMessage: '버거퀸 어때요? 가보셨나요?',
            time: '2시간 전',
            isRead: false,
            onTap: () {
              _showMessageDetail(context, '맛잘알');
            },
          ),
          
          const SizedBox(height: 12),
          
          // 두 번째 쪽지
          _buildMessageCard(
            senderName: '미식가',
            lastMessage: '오늘 날씨가 좋네요! 어디 가실 계획이신가요?',
            time: '1일 전',
            isRead: true,
            onTap: () {
              _showMessageDetail(context, '미식가');
            },
          ),
          
          const SizedBox(height: 12),
          
          // 세 번째 쪽지
          _buildMessageCard(
            senderName: '여행러',
            lastMessage: '추천해주신 곳 정말 좋았어요! 감사합니다.',
            time: '3일 전',
            isRead: true,
            onTap: () {
              _showMessageDetail(context, '여행러');
            },
          ),
          
          const SizedBox(height: 12),
          
          // 네 번째 쪽지
          _buildMessageCard(
            senderName: '카페매니아',
            lastMessage: '새로 오픈한 카페 같이 가실래요?',
            time: '1주 전',
            isRead: false,
            onTap: () {
              _showMessageDetail(context, '카페매니아');
            },
          ),
          
          const SizedBox(height: 12),
          
          // 다섯 번째 쪽지
          _buildMessageCard(
            senderName: '독서광',
            lastMessage: '책 추천 감사합니다. 정말 재미있게 읽었어요!',
            time: '2주 전',
            isRead: true,
            onTap: () {
              _showMessageDetail(context, '독서광');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required String senderName,
    required String lastMessage,
    required String time,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 메시지 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 읽음 표시
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8126),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetail(BuildContext context, String senderName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$senderName님과의 쪽지'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('쪽지 상세 내용을 구현해주세요.'),
              const SizedBox(height: 16),
              const Text('여기에 실제 쪽지 내용이 표시됩니다.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '확인',
                style: TextStyle(color: Color(0xFFFF8126)),
              ),
            ),
          ],
        );
      },
    );
  }
}
