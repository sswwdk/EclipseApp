import 'package:flutter/material.dart';
import 'package:whattodo/presentation/screens/community/chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // 샘플 쪽지 데이터
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'sender': '근면한 떡볶이',
      'content': '안녕하세요! 같이 가고 싶어요',
      'timeAgo': '1시간 전',
      'isRead': false,
      'post': {
        'title': '메가커피 노량진점 → 카츠진 → 영등포 CGV',
        'content': '노량진 메가커피에서 시작해서 카츠진에서 저녁 먹고 영등포 CGV에서 영화 보기',
      },
    },
    {
      'id': '2',
      'sender': '꼼꼼한 연어',
      'content': '카츠진 정말 맛있어요. 추천합니다!',
      'timeAgo': '2시간 전',
      'isRead': true,
      'post': {
        'title': '홍대 맛집 투어',
        'content': '홍대 근처 맛집들을 돌아다니며 맛있는 음식들을 즐겨보세요',
      },
    },
    {
      'id': '3',
      'sender': '활발한 칼국수',
      'content': '언제 가시나요?',
      'timeAgo': '3시간 전',
      'isRead': false,
      'post': {
        'title': '강남 카페 투어',
        'content': '강남의 인기 카페들을 순회하며 좋은 시간을 보내요',
      },
    },
    {
      'id': '4',
      'sender': '케밥데몬헌터',
      'content': '서울 근교 여행지 추천해주세요',
      'timeAgo': '1일 전',
      'isRead': true,
      'post': {
        'title': '서울 근교 당일치기 여행',
        'content': '서울에서 가까운 근교 여행지들을 추천해드려요',
      },
    },
    {
      'id': '5',
      'sender': '달콤한 파스타',
      'content': '홍대 근처에서 혼자 가서 책 읽기 좋은 조용한 카페 있나요?',
      'timeAgo': '2일 전',
      'isRead': true,
      'post': {
        'title': '홍대 조용한 카페 추천',
        'content': '홍대에서 혼자 시간을 보내기 좋은 조용한 카페들을 소개해요',
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '내 쪽지함',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // 더보기 메뉴
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
      body: _messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageCard(message);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '받은 쪽지가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 사용자들과 소통해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final isRead = message['isRead'] as bool;
    
    return Container(
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  user: {
                    'nickname': message['sender'],
                    'profileImage': Icons.person,
                  },
                  post: message['post'] != null ? {
                    'title': message['post']['title'],
                    'content': message['post']['content'],
                  } : null,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 프로필 이미지
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 쪽지 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message['sender'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                      const SizedBox(height: 4),
                      Text(
                        message['content'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 게시물 정보
                      if (message['post'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8126).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
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
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  message['post']['title'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFF8126),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message['timeAgo'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 화살표 아이콘
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
