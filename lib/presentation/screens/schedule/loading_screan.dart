import 'package:flutter/material.dart';

import 'recommendation_screen.dart';

/// 채팅 및 추천 화면에서 공유하는 로딩 위젯
class LoadingScreanIndicator extends StatelessWidget {
  const LoadingScreanIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF7A21),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '생각 중...',
                style: TextStyle(
                  color: Color(0xFFFF7A21),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 후보지 출력 요청 후 결과를 기다리는 로딩 화면
class LoadingScrean extends StatefulWidget {
  final Future<Map<String, dynamic>> loadingTask;
  final List<String> selectedCategories;

  const LoadingScrean({
    super.key,
    required this.loadingTask,
    required this.selectedCategories,
  });

  @override
  State<LoadingScrean> createState() => _LoadingScreanState();
}

class _LoadingScreanState extends State<LoadingScrean> {
  @override
  void initState() {
    super.initState();

    widget.loadingTask.then((recommendations) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RecommendationResultScreen(
            recommendations: recommendations,
            selectedCategories: widget.selectedCategories,
          ),
        ),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추천 결과를 가져오지 못했어요. 다시 시도해주세요.\n오류: $error'),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A21)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '후보지를 준비하고 있어요...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF444444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

