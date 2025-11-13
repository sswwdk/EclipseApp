import 'package:flutter/material.dart';
import '../../../widgets/app_title_widget.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const AppTitleWidget('개인정보 처리방침'),
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
              '“오늘 뭐하지”는 이클립스팀이 운영하며, 이용자의 개인정보를 중요하게 생각합니다.\n\n'
              '운영팀은 「개인정보 보호법」 및 관련 법령을 준수하며, 개인정보가 어떠한 방식으로 수집·이용·보관·파기되는지에 대해 투명하게 공개합니다.\n\n'
              '본 방침은 서비스 이용자에게 관련 내용을 명확히 안내하기 위한 것입니다.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '1. 수집하는 개인정보 항목',
              body: '서비스는 원활한 이용과 맞춤형 기능 제공을 위해 다음과 같은 개인정보를 수집합니다.\n\n'
                  '1. 회원가입 시: 이메일, 비밀번호(암호화 저장), 닉네임\n'
                  '2. 선택 항목: 프로필 이미지\n'
                  '3. 위치 정보: GPS 기반 현재 위치(위도, 경도)\n'
                  '4. 서비스 이용 중 자동 수집 항목: 접속 로그, 기기 정보, 이용 기록, 오류 로그 등',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '2. 개인정보의 수집 방법',
              body: 
                  '- 회원가입 또는 로그인 시 사용자가 직접 입력하는 경우\n'
                  '- 위치 정보 제공 동의를 한 경우 GPS를 통한 자동 수집\n'
                  '- 서비스 이용 과정에서 시스템이 자동으로 생성하는 정보(로그, IP, 이용 시간 등)',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '3. 개인정보의 이용 목적',
              body: '운영팀은 수집한 개인정보를 다음의 목적을 위해 이용합니다.\n\n'
                  '1. 회원 관리 및 본인 확인\n'
                  '2. 위치 기반 맞춤 추천 서비스 제공\n'
                  '3. 일정 자동 생성 및 저장 기능 제공\n'
                  '4. 문의사항 응대 및 고객 지원\n'
                  '5. 서비스 품질 개선 및 통계 분석',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '4. 개인정보의 보관 및 파기',
              body: '1. 보관 기간\n'
                  '   - 회원 정보: 회원 탈퇴 시 즉시 삭제\n'
                  '   - 게시글 및 댓글: 서비스 운영 목적상 일정 기간 보관 후 익명 처리\n'
                  '   - 로그 기록: 1년 보관 후 자동 삭제\n\n'
                  '2. 파기 절차 및 방법\n'
                  '   - 전자 파일 형태의 정보는 복구가 불가능한 방법으로 영구 삭제',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '5. 개인정보의 제3자 제공',
              body: '운영팀은 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다.\n\n'
                  '다만, 아래의 경우에는 예외로 합니다.\n'
                  '- 이용자가 사전에 동의한 경우\n'
                  '- 법령에 따라 관계 기관이 정당하게 요청하는 경우',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '6. 이용자의 권리',
              body: '이용자는 다음과 같은 권리를 행사할 수 있습니다.\n\n'
                  '1. 본인의 개인정보 열람 및 수정 요청\n'
                  '2. 개인정보 처리 정지 요청\n'
                  '3. 회원 탈퇴 및 데이터 삭제 요청\n\n'
                  '요청은 서비스 내 문의 기능 또는 아래 연락처를 통해 가능합니다.',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '7. 위치 정보의 처리',
              body: '서비스는 이용자의 위치 정보를 다음의 목적에 한해 처리합니다.\n\n'
                  '1. 주변 장소 추천 및 일정 생성 기능 제공\n'
                  '2. 통계 분석을 통한 서비스 품질 개선\n\n'
                  '이용자가 위치 권한을 거부할 경우 일부 기능이 제한될 수 있습니다.\n'
                  '위치 정보는 서비스 제공 목적 외에는 저장·이용되지 않습니다.',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '8. 개인정보 보호를 위한 기술적 및 관리적 조치',
              body: 
                  '- 비밀번호는 암호화하여 저장\n'
                  '- 개인정보 접근 권한 최소화\n'
                  '- SSL(보안서버) 적용을 통한 전송 구간 암호화\n'
                  '- 접근 로그 및 접속 이력의 주기적 점검',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '9. 개인정보 처리방침의 변경',
              body: '본 방침은 관련 법령 및 서비스 정책 변경에 따라 수정될 수 있습니다.\n\n'
                  '변경 사항은 서비스 내 공지사항을 통해 사전 안내하며, 변경된 내용은 공지한 시행일부터 효력이 발생합니다.\n\n'
                  '시행일자: 2025년 11월 12일\n'
                  '최종 수정일: 2025년 11월 12일',
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '10. 문의처',
              body: '서비스명: 오늘 뭐하지\n'
                  '운영팀: 이클립스\n'
                  '이메일: example@gmail.com',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
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

