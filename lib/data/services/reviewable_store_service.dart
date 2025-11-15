import 'package:flutter/foundation.dart';
import '../models/reviewable_store.dart';
import 'api_service.dart';
import 'history_service.dart';
import 'review_service.dart';

class ReviewableStoreService {
  /// 리뷰 작성 가능한 매장 목록 조회
  /// (방문 횟수 > 리뷰 개수인 매장만 반환, 최신 방문순)
  static Future<List<ReviewableStore>> getReviewableStores({
    int limit = 6,
  }) async {
    try {
      debugPrint('🔍 리뷰 작성 가능한 매장 조회 시작...');

      // 1. 방문 기록 목록 조회
      final historyData = await HistoryService.getMyHistory('');
      debugPrint('📦 히스토리 원시 데이터: $historyData');

      final List<dynamic> historyList = historyData['results'] ?? [];
      debugPrint('📝 히스토리 항목 개수: ${historyList.length}');

      if (historyList.isEmpty) {
        debugPrint('❌ 방문 기록이 없습니다');
        return [];
      }

      // 2. 각 히스토리의 상세 정보 조회 (category_id를 얻기 위해)
      final Map<String, _VisitInfo> visitMap = {};

      for (final historyItem in historyList) {
        final item = historyItem as Map<String, dynamic>;
        final historyId = item['id'] ?? '';

        if (historyId.isEmpty) {
          debugPrint('⚠️ history id가 없는 항목: $item');
          continue;
        }

        try {
          // 상세 정보 조회
          final detailData = await HistoryService.getHistoryDetail(
            '',
            historyId,
          );
          debugPrint('📄 히스토리 상세 정보: $detailData');

          final List<dynamic> categories = detailData['categories'] ?? [];
          final visitedAtStr = item['visited_at'];
          final visitedAt = visitedAtStr != null
              ? DateTime.parse(visitedAtStr)
              : DateTime.now();

          // 각 카테고리 처리
          for (final categoryItem in categories) {
            final category = categoryItem as Map<String, dynamic>;
            final categoryId = category['category_id'] ?? '';
            final categoryName = category['category_name'] ?? '알 수 없음';

            if (categoryId.isEmpty) {
              debugPrint('⚠️ category_id가 없는 항목: $category');
              continue;
            }

            if (!visitMap.containsKey(categoryId)) {
              visitMap[categoryId] = _VisitInfo(
                categoryId: categoryId,
                categoryName: categoryName,
                visitCount: 0,
                lastVisitDate: visitedAt,
                imageUrl: category['image'],
              );
            }

            visitMap[categoryId]!.visitCount++;

            // 가장 최근 방문일 업데이트
            if (visitedAt.isAfter(visitMap[categoryId]!.lastVisitDate)) {
              visitMap[categoryId]!.lastVisitDate = visitedAt;
            }
          }
        } catch (e) {
          debugPrint('⚠️ 히스토리 상세 조회 실패 (id: $historyId): $e');
          continue;
        }
      }

      debugPrint('📍 ${visitMap.length}개의 고유한 매장 방문 기록');

      // 3. 각 매장별로 리뷰 개수 확인 및 필터링
      final List<ReviewableStore> reviewableStores = [];

      for (final visitInfo in visitMap.values) {
        try {
          // 해당 매장의 리뷰 개수 조회
          final reviewCount = await ReviewService.getMyReviewCount(
            visitInfo.categoryId,
          );

          // 방문 횟수 > 리뷰 개수인 경우만 추가
          if (visitInfo.visitCount > reviewCount) {
            debugPrint(
              '✅ ${visitInfo.categoryName}: 방문 ${visitInfo.visitCount}회, 리뷰 $reviewCount개 - 리뷰 작성 가능!',
            );

            reviewableStores.add(
              ReviewableStore(
                categoryId: visitInfo.categoryId,
                categoryName: visitInfo.categoryName,
                categoryType: '',
                imageUrl: visitInfo.imageUrl,
                visitCount: visitInfo.visitCount,
                reviewCount: reviewCount,
                lastVisitDate: visitInfo.lastVisitDate,
                address: '',
              ),
            );
          } else {
            debugPrint(
              '⏭️ ${visitInfo.categoryName}: 방문 ${visitInfo.visitCount}회, 리뷰 $reviewCount개 - 이미 리뷰 작성 완료',
            );
          }
        } catch (e) {
          debugPrint('⚠️ ${visitInfo.categoryName} 리뷰 개수 조회 실패: $e');
          continue;
        }
      }

      // 4. 최신 방문순 정렬 후 제한
      reviewableStores.sort(
        (a, b) => b.lastVisitDate.compareTo(a.lastVisitDate),
      );

      final result = reviewableStores.take(limit).toList();

      debugPrint('✨ 최종 리뷰 작성 가능한 매장: ${result.length}개');

      return result;
    } catch (e) {
      debugPrint('❌ 리뷰 작성 가능한 매장 조회 중 오류: $e');
      debugPrint('   스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }
}

/// 방문 정보를 저장하는 내부 클래스
class _VisitInfo {
  final String categoryId;
  final String categoryName;
  int visitCount;
  DateTime lastVisitDate;
  String? imageUrl;

  _VisitInfo({
    required this.categoryId,
    required this.categoryName,
    required this.visitCount,
    required this.lastVisitDate,
    this.imageUrl,
  });
}
