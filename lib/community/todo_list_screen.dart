import 'package:flutter/material.dart';
import 'write_post_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // 샘플 일정표 데이터 (실제로는 서버에서 가져올 데이터)
  final List<Map<String, dynamic>> _todoList = [
    {
      'id': '1',
      'title': '메가커피 노량진점 → 카츠진 → 영등포 CGV',
      'date': '2024-01-15',
      'time': '19:00',
      'people': 2,
      'categories': ['카페', '음식점', '콘텐츠'],
      'description': '노량진 메가커피에서 시작해서 카츠진에서 저녁 먹고 영등포 CGV에서 영화 보기',
      'schedule': [
        {'place': '메가커피 노량진점', 'activity': '커피 마시며 대화'},
        {'place': '카츠진', 'activity': '일식 저녁 식사'},
        {'place': '영등포 CGV', 'activity': '영화 관람'},
      ],
    },
    {
      'id': '2',
      'title': '홍대 스타벅스 → 망원시장 → 홍대 클럽',
      'date': '2024-01-16',
      'time': '18:30',
      'people': 3,
      'categories': ['카페', '음식점', '콘텐츠'],
      'description': '홍대 스타벅스에서 만나서 망원시장에서 간식 먹고 홍대 클럽에서 놀기',
      'schedule': [
        {'place': '홍대 스타벅스', 'activity': '커피와 간단한 대화'},
        {'place': '망원시장', 'activity': '길거리 음식과 쇼핑'},
        {'place': '홍대 클럽', 'activity': '클럽에서 춤과 음악'},
      ],
    },
    {
      'id': '3',
      'title': '강남 이마트 → 코엑스 아쿠아리움 → 봉은사',
      'date': '2024-01-17',
      'time': '14:00',
      'people': 1,
      'categories': ['콘텐츠'],
      'description': '강남 이마트에서 쇼핑하고 코엑스 아쿠아리움 구경한 후 봉은사에서 산책',
      'schedule': [
        {'place': '강남 이마트', 'activity': '생활용품 쇼핑'},
        {'place': '코엑스 아쿠아리움', 'activity': '수족관 관람'},
        {'place': '봉은사', 'activity': '절에서 산책과 명상'},
      ],
    },
    {
      'id': '4',
      'title': '잠실 롯데월드 → 잠실 래미안 → 송파구청',
      'date': '2024-01-20',
      'time': '09:00',
      'people': 4,
      'categories': ['콘텐츠'],
      'description': '잠실 롯데월드에서 놀이기구 타고 잠실 래미안에서 쇼핑 후 송파구청에서 공원 산책',
      'schedule': [
        {'place': '잠실 롯데월드', 'activity': '놀이기구와 어트랙션'},
        {'place': '잠실 래미안', 'activity': '쇼핑몰에서 쇼핑'},
        {'place': '송파구청', 'activity': '공원에서 산책과 휴식'},
      ],
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
          '내 일정표',
          style: TextStyle(
            color: Color(0xFFFF8126),
            fontSize: 20,
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
      body: _todoList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                final todo = _todoList[index];
                return _buildTodoCard(todo);
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
            Icons.task_alt,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 생성된 일정표가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일정표를 먼저 생성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(Map<String, dynamic> todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToWritePost(todo),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 화살표 아이콘
                Row(
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 제목
                Text(
                  todo['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 날짜와 시간
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      todo['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${todo['people']}명',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 카테고리 (카페, 음식점, 콘텐츠만 표시)
                Wrap(
                  spacing: 6,
                  children: (todo['categories'] as List<String>)
                      .where((category) => ['카페', '음식점', '콘텐츠'].contains(category))
                      .map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8126).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF8126),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                
                // 일정 정보
                if (todo['schedule'] != null) ...[
                  const SizedBox(height: 8),
                  ...(todo['schedule'] as List<Map<String, dynamic>>).map((scheduleItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8126),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scheduleItem['place'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWritePost(Map<String, dynamic> selectedTodo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WritePostScreen(selectedTodo: selectedTodo),
      ),
    );
  }
}
