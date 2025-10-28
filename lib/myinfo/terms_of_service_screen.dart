import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '이용약관',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFFF8126),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('제1조 (목적)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '본 약관은 "오늘 뭐하지"를 운영하는 이클립스팀이 제공하는 서비스의 이용과 관련하여, 이용자와 운영자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제2조 (정의)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''"서비스"란 사용자의 취향, 위치, 시간대 등에 따라 활동(맛집, 여행, 카페, 전시 등)을 추천하는 모바일 애플리케이션을 의미합니다.\n\n"이용자"란 본 약관에 동의하고 서비스를 이용하는 개인을 말합니다.\n\n"콘텐츠"란 이용자가 업로드하거나 앱 내에서 표시되는 모든 정보(리뷰, 사진, 태그, 일정 등)를 말합니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제3조 (약관의 효력 및 변경)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''본 약관은 서비스를 통해 공지함으로써 효력을 가집니다.\n\n운영자는 법령 변경이나 서비스 정책의 개선 등을 위해 약관을 변경할 수 있으며, 변경된 약관은 공지 후 효력을 가집니다.\n\n이용자가 변경된 약관에 동의하지 않을 경우, 서비스 이용을 중단하고 탈퇴할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제4조 (서비스의 제공 및 변경)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''운영자는 다음과 같은 서비스를 제공합니다.\n  - 개인 맞춤형 활동 추천 기능\n  - 위치 기반 맛집·카페·여행지 추천\n  - 사용자 리뷰 및 콘텐츠 공유 기능\n\n운영자는 서비스의 품질 향상을 위해 기능을 추가·변경하거나, 일부 서비스를 중단할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제5조 (이용자의 의무)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''이용자는 다음 행위를 해서는 안 됩니다.\n  - 타인의 정보를 도용하거나 허위 정보 등록\n  - 불법적이거나 사회질서에 반하는 콘텐츠 게시\n  - 서비스의 정상 운영을 방해하는 행위\n\n이용자가 위 행위를 할 경우, 운영자는 서비스 이용을 제한할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제6조 (개인정보의 보호)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''운영자는 이용자의 개인정보를 보호하기 위해 관련 법령을 준수하며, 별도의 "개인정보처리방침"을 제공합니다.\n\n서비스 이용 과정에서 수집되는 데이터(위치 정보, 관심 카테고리 등)는 개인 식별이 불가능한 범위 내에서만 분석 및 추천에 활용됩니다.\n\n이용자는 언제든지 개인정보의 열람, 수정, 삭제를 요청할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제7조 (위치정보의 이용)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''본 서비스는 사용자 근처의 장소 및 활동을 추천하기 위해 위치정보를 활용할 수 있습니다.\n\n이용자는 위치정보 제공 동의를 언제든 철회할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제8조 (콘텐츠의 저작권 및 이용권)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''이용자가 작성한 리뷰, 사진, 태그 등의 콘텐츠에 대한 저작권은 이용자에게 있습니다.\n\n다만, 이용자는 운영자가 서비스의 홍보, 개선, 통계 분석을 위해 콘텐츠를 비식별화된 형태로 사용할 수 있음에 동의합니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제9조 (서비스 이용 제한 및 해지)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''이용자가 본 약관을 위반하거나 서비스 운영을 방해할 경우, 운영자는 사전 통보 없이 이용을 제한할 수 있습니다.\n\n이용자는 언제든지 앱 내 탈퇴 기능을 통해 이용계약을 해지할 수 있습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제10조 (면책 조항)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '''운영자는 이용자의 단말기, 통신 환경 등의 문제로 인해 발생한 서비스 장애에 대해 책임지지 않습니다.\n\n추천 결과 및 제3자 정보(위치, 리뷰 등)는 참고용이며, 실제 내용의 정확성을 보장하지 않습니다.''',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('제11조 (관할법원 및 준거법)'),
            const SizedBox(height: 8),
            _buildSectionContent(
              '본 약관과 관련하여 발생하는 분쟁은 대한민국 법률을 따르며, 관할법원은 운영자의 주소지를 관할하는 법원으로 합니다.',
            ),
            const SizedBox(height: 32),
            
            _buildSectionContent(
              '''📅 시행일자: 2025년 10월 28일\n\n👤 운영자명: 이클립스\n\n📧 문의: [이메일 주소 또는 고객센터]''',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
        height: 1.6,
      ),
    );
  }
}

