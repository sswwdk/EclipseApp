## 현재 구조의 문제점

현재 `lib/` 폴더 하위에 모든 파일이 같은 수준으로 있어서:
- 파일 찾기가 어려움
- 유지보수가 힘듦
- 기능별 관심사 분리가 안됨
- 프로젝트가 커질수록 복잡도 증가

---

## 추천하는 새로운 구조
```
lib/
├── main.dart                          # 앱 진입점
│
├── core/                              # 핵심 기능
│   ├── config/                        # 설정
│   │   └── server_config.dart
│   ├── theme/                         # 테마
│   │   └── app_theme.dart
│   ├── constants/                     # 상수
│   │   └── app_constants.dart
│   └── utils/                         # 유틸리티
│       └── validators.dart
│
├── data/                              # 데이터 레이어
│   ├── models/                        # 데이터 모델
│   │   ├── restaurant.dart	
│   │   ├── review.dart
│   │   └── user.dart
│   ├── services/                      # API 서비스
│   │   ├── api_service.dart          # 메인 화면 API
│   │   ├── auth_service.dart         # 인증 관련 (user_service)
│   │   ├── like_service.dart		# 찜 목록 연결
│   │   ├── review_service.dart	# 리뷰 목록 연결
│   │   ├── history_service.dart	# 일정표 히스토리 연결
│   │   ├── service_api.dart          # 하루랑 채팅
│   │   └── route_service.dart	# 이동시간 계산 모델 연결
│   └── repositories/                  # 저장소 (옵션)
│       └── user_repository.dart
│
├── presentation/                      # UI 레이어
│   ├── screens/                       # 화면
│   │   ├── auth/                      # 인증 관련
│   │   │   ├── login_screen.dart	# 로그인 화면
│   │   │   └── signup_screen.dart		# 회원가입 화면
│   │   │
│   │   ├── main/                      # 메인 화면
│   │   │   ├── main_screen.dart		# 메인 화면(home.dart)
│   │   │   └── restaurant_detail_screen.dart		# 매장 상세 화면
│   │   │
│   │   ├── schedule/                  # 일정 만들기 (make_todo)
│   │   │   ├── schedule_screen.dart		# make_todo 시작화면
│   │   │   ├── schedule_select_screen.dart		# make_todo 위치, 
│   │   │   ├── schedule_chat_screen.dart		# make_todo 하루 채팅
│   │   │   ├── recommendation_screen.dart	# 후보지 추천화면
│   │   │   ├── recommendation_place_detail_screen.dart  X
│   │   │   ├── result_choice_confirm_screen.dart		# “그냥” 저장 화면(템플릿 X) 
│   │   │   ├── route_confirm_screen.dart		#  순서 저장 화면
│   │   │   ├── choose_template_screen.dart	# 템플릿 선택 화면
│   │   │   └── template_1_screen.dart	# 1번 템플릿 선택 화면(일정표)
│   │   │
│   │   ├── my_info/                   # 마이페이지
│   │   │   ├── my_info_screen.dart		# 하단바에서 내 정보를 눌렀을 때 뜨는 내 정보
│   │   │   ├── favorite_list_screen.dart		# 찜 목록
│   │   │   ├── schedule_history_screen.dart	# 일정표 히스토리
│   │   │   ├── schedule_history_detail_screen.dart		# “일정표” 탭 상세화면
│   │   │   ├── schedule_history_normal_detail_screen.dart	# “그냥” 탭 상세화면
│   │   │   ├── my_review_screen.dart	# 내가 쓴 리뷰 화면
│   │   │   ├── my_posts_screen.dart	# 내가 쓴 게시글 화면
│   │   │   └── change
│   │   │ 	├── change_adress_screen.dart		# 주소 변경 화면
│   │   │	├── change_email_screen.dart		# 이메일 변경 화면
│   │   │	├── change_nickname_screen.dart		# 닉네임 변경 화면
│   │   │	├── change_password_screen.dart		# 비밀번호 변경 화면
│   │   │	└── change_phone_screen.dart		# 전화번호 변경 화면
│   │   │
│   │   └── community/                 # 커뮤니티
│   │       ├── community_screen.dart		# 커뮤니티 시작 화면
│   │       ├── post_detail_screen.dart		# 커뮤니티 글 상세 화면
│   │       ├── choose_schedule_screen.dart	# 내 일정 선택 화면(내 일정선택후 글씀)
│   │       ├── create_post_screen.dart		# 내 글 쓰는 화면
│   │       ├── chat_list_screen.dart			# 채팅방 리스트 화면
│   │       └── chat_screen.dart			# 채팅방 화면
│   │
│   └── widgets/                       # 공통 위젯
│       ├── bottom_navigation_widget.dart		# 하단바
│       ├── common_dialogs.dart		#  다이얼로그 위젯화
│       └── custom_button.dart	# 버튼 위젯화
│
└── shared/                            # 공유 리소스
    ├── helpers/                       # 헬퍼 함수
    │   ├── token_manager.dart	# 서버 토큰 불러오는 파일
    │   └── http_interceptor.dart	# HTTP 요청을 가로채서 401 에러 시 자동으로 토큰 갱신 후 재시도하는 인터셉터
    └── extensions/                    # 확장 함수
        └── string_extensions.dart		# 이건 또 뭔데