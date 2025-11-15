import 'package:flutter/material.dart';
import '../../../data/models/reviewable_store.dart';

/// 리뷰 작성 가능한 매장 드롭다운 위젯
class ReviewableStoresDropdown extends StatelessWidget {
  final List<ReviewableStore> stores;
  final Function(ReviewableStore) onStoreTap;

  const ReviewableStoresDropdown({
    Key? key,
    required this.stores,
    required this.onStoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return _buildEmptyState();
    }
    return _buildStoreList();
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '리뷰 작성 가능한\n매장이 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매장을 방문하고\n리뷰를 작성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 매장 목록 위젯
  Widget _buildStoreList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8126).withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.rate_review, color: Color(0xFFFF8126), size: 20),
              const SizedBox(width: 8),
              const Text(
                '리뷰 작성 가능한 매장',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8126),
                ),
              ),
            ],
          ),
        ),
        // 매장 목록
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: stores.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _buildStoreItem(store);
            },
          ),
        ),
      ],
    );
  }

  /// 매장 아이템 위젯
  Widget _buildStoreItem(ReviewableStore store) {
    return InkWell(
      onTap: () => onStoreTap(store),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 매장 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

