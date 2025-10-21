# whattodo (EclipseApp)

간단 소개
- 프로젝트 이름: whattodo
- 한 줄 요약: Flutter로 만든 멀티플랫폼 할 일(또는 간단한 유틸) 앱 템플릿
- 이 리포지터리는 포트폴리오용으로 제작한 Flutter 프로젝트입니다. (프로젝트 목적이나 핵심 아이디어를 한두 문장 더 추가하세요.)

핵심 기능
- 플랫폼: Android / iOS / Web / macOS / Windows / Linux (프로젝트에 각 플랫폼 폴더가 포함되어 있습니다)
- 네트워크 요청: HTTP 클라이언트를 사용한 외부 API 연동 (pubspec에 http 의존성 포함)
- 에셋 관리: assets/images 폴더에 이미지를 두어 UI에서 사용
- (필요 시 실제 구현된 기능 목록을 여기에 채워 넣으세요: 예: 할 일 CRUD, 로컬 저장, 알림 등)

내 역할 (hongsh2003)
- 주된 역할: 전체 설계 및 구현 (프론트엔드(UI)/로직), Flutter 프로젝트 구성, 멀티플랫폼 빌드 설정
- 기여한 핵심 항목 예시:
  - 플랫폼별 폴더 구조 정리 (android/ios/web/macos/windows/linux)
  - 외부 API 연동을 위한 HTTP 모듈 구성
  - 에셋 관리 및 앱 리소스 구조 설계

기술 스택
- 언어/플랫폼: Dart / Flutter (Dart SDK constraint: ^3.9.2)
- 주요 패키지:
  - cupertino_icons: ^1.0.8
  - http: ^1.1.0
- 개발 도구: Flutter CLI, (IDE: Android Studio / VSCode 등)
- 기타: 프로젝트는 Flutter 멀티플랫폼 구성을 포함합니다 (Android/iOS/Web/데스크탑).

프로젝트 구조 (루트 폴더 기준, 핵심 항목만)
- .gitignore
- analysis_options.yaml
- pubspec.yaml
- android/
- ios/
- web/
- macos/
- windows/
- linux/
- lib/               ← Dart 소스 코드 (일반적으로 진입점: lib/main.dart)
- assets/
  - images/          ← 앱에서 사용하는 이미지 리소스
- test/              ← 테스트 코드
- README.md

설치 및 로컬 실행 (로컬 환경에 맞게 실제 버전/경로로 수정하세요)
1. 요구사항
   - Flutter SDK (Dart SDK >= 3.9.2 권장)
   - Android SDK / Xcode / Web 지원 등 (실행 대상 플랫폼에 따라)
2. 저장소 클론
   git clone https://github.com/sswwdk/EclipseApp.git
   cd EclipseApp
3. 패키지 설치
   flutter pub get
4. 앱 실행 (디바이스/에뮬레이터 선택)
   - 모바일/데스크탑: flutter run
   - 웹(Chrome): flutter run -d chrome
5. 빌드 예시
   - Android APK: flutter build apk --release
   - Web 빌드: flutter build web

환경/설정 관련
- pubspec.yaml 주요 내용:
  - name: whattodo
  - description: "A new Flutter project."
  - environment: sdk: ^3.9.2
  - dependencies: flutter, cupertino_icons, http
  - assets: assets/images/
- 분석 규칙: analysis_options.yaml 포함 (코드 스타일/린트 규칙)

테스트
- 단위/위젯 테스트 실행:
  flutter test

데모 및 스크린샷
- (배포한 데모 URL이 있다면 여기에 추가)
- 스크린샷은 /assets/images 또는 /docs/screenshots 에 추가 후 아래에 삽입하세요.

배포
- Flutter 빌드 명령으로 플랫폼별 바이너리/웹 빌드 생성 후 원하는 호스팅에 업로드
- (CI/CD를 사용한다면 GitHub Actions 등으로 빌드/배포 파이프라인 구성 권장)

향후 개선 계획 (예시)
- 실제 기능 구현 보강 및 UI 개선
- 상태 관리 라이브러리(Riverpod, Provider, Bloc 등) 도입
- E2E/통합 테스트 추가
- 접근성/로컬라이제이션(다국어) 지원

포트폴리오용 요약 (면접용 강조 포인트)
- Flutter 멀티플랫폼 경험: 모바일 + 웹 + 데스크탑 빌드 경험
- 외부 API 연동 경험: http 패키지 사용
- 프로젝트 구성 및 에셋/플랫폼 관리 경험

연락처
- GitHub: https://github.com/hongsh2003
- 이메일: (원하시면 기입)

라이선스
- 기본 템플릿: MIT License 권장 (원하시면 명시하세요)

추가 안내
- README의 빈칸(상세 기능 설명, 데모 URL, 스크린샷, 구체적인 역할/성과 수치 등)은 실제 구현 내용으로 덧붙이면 포트폴리오에 바로 사용할 수 있습니다.
