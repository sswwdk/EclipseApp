import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../widgets/common_dialogs.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
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
          '게시글',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (String value) {
              if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('게시글 신고하기'),
                  ],
                ),
              ),
            ],
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 메인 포스트 카드
            _buildMainPostCard(),
            const Divider(height: 1),
            
            // 댓글 섹션
            _buildCommentsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildMainPostCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
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
                  widget.post['profileImage'] ?? Icons.person,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // 닉네임과 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['nickname'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.post['timeAgo'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 종이비행기 아이콘
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        user: {
                          'nickname': widget.post['nickname'],
                          'profileImage': widget.post['profileImage'],
                        },
                        post: {
                          'title': widget.post['title'],
                          'content': widget.post['content'],
                          'schedule': widget.post['schedule'],
                        },
                      ),
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: -0.5, // 오른쪽 위를 가리키도록 회전
                  child: Icon(
                    Icons.send,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 포스트 제목
          Text(
            widget.post['title'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 포스트 내용
          Text(
            widget.post['content'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // 일정표 정보 (있는 경우에만 표시)
          if (widget.post['schedule'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8126).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8126).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: const Color(0xFFFF8126),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '일정표가 뜰 예정입니다',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8126),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 액션 버튼들
          Row(
            children: [
              _buildActionButton(Icons.chat_bubble_outline, '댓글', '8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, String count) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          count.isEmpty ? label : '$label $count',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    // 샘플 댓글 데이터
    final comments = [
      {
        'nickname': '근면한 떡볶이',
        'timeAgo': '1시간 전',
        'content': '저도 같이 가고 싶어요!',
        'likes': 3,
      },
      {
        'nickname': '꼼꼼한 연어',
        'timeAgo': '2시간 전',
        'content': '카츠진 정말 맛있어요. 추천합니다!',
        'likes': 5,
      },
      {
        'nickname': '활발한 칼국수',
        'timeAgo': '3시간 전',
        'content': '언제 가시나요?',
        'likes': 1,
      },
    ];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '댓글 ${comments.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...comments.map((comment) => _buildCommentCard(comment)).toList(),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 32,
                height: 32,
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
              // 닉네임과 시간
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['nickname'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      comment['timeAgo'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 좋아요 버튼
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${comment['likes']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['content'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 32,
            height: 32,
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
          const SizedBox(width: 12),
          // 댓글 입력 필드
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8126),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    CommonDialogs.showReportConfirmation(
      context: context,
      title: '게시글 신고하기',
      content: '이 게시글을 신고하시겠습니까?\n신고된 게시글은 검토 후 조치됩니다.',
      onConfirm: () {
        _showReportSuccess();
      },
    );
  }

  void _showReportSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
        backgroundColor: Color(0xFFFF8126),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
