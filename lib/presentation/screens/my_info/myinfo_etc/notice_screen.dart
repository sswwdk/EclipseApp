import 'package:flutter/material.dart';
import '../../../widgets/app_title_widget.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

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
        title: const AppTitleWidget('공지사항'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '📢 [공지사항] “오늘 뭐하지” 정식 오픈 기념',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8126),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '일정표 만들기 기능 2개월 무료 이용 이벤트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '안녕하세요,\n\n이클립스 팀입니다.\n\n드디어 우리 서비스가 정식 오픈했습니다! '
              '그동안 베타 테스트 기간 동안 보내주신 많은 관심과 피드백 덕분에 '
              '더 안정적이고 즐거운 서비스로 돌아왔습니다.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '오픈 기념 이벤트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '평소에는 유료로 제공되는 일정표 자동 생성 기능을 '
              '오픈 기념으로 2개월간 무료로 이용하실 수 있습니다!',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            _NoticeSection(
              title: '이벤트 기간',
              body: '서비스 오픈일 ~ 2개월간',
            ),
            SizedBox(height: 12),
            _NoticeSection(
              title: '대상',
              body: '오늘 뭐할지 앱을 사용하는 모든 회원',
            ),
            SizedBox(height: 12),
            _NoticeSection(
              title: '혜택',
              body: '- 취향 기반 추천을 통한 일정표 자동 생성\n'
                  '- 이동수단/시간대별 맞춤 일정 구성\n'
                  '- 생성된 일정표 저장 및 공유 기능',
            ),
            SizedBox(height: 24),
            Text(
              '앞으로의 계획',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '- 더 다양한 카테고리와 태그 추가\n'
              '- 커뮤니티 기능 강화\n'
              '- 사용자 후기 기반 추천 알고리즘 고도화',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '여러분의 소중한 의견이 “오늘 뭐하지”를 더 좋은 방향으로 성장시킵니다.\n'
              '앞으로도 많은 관심과 참여 부탁드립니다.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeSection extends StatelessWidget {
  final String title;
  final String body;

  const _NoticeSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

