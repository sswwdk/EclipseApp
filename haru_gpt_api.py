"""
Haru GPT API - 대화형 활동 추천 시스템

사용자와 대화하며 원하는 활동(카페, 음식점, 콘텐츠)에 대한 정보를 수집하고,
LLM을 활용해 키워드를 추출한 후 맞춤 추천을 제공하는 FastAPI 서버
"""

import os
import sys
import io
import uuid
from typing import Dict, List, Optional
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# 환경 설정
load_dotenv()
openai_api_key = os.getenv("OPENAI_API_KEY")

# 한글 인코딩 설정 (Windows 환경에서 한글 출력 문제 해결)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# FastAPI 앱 초기화
app = FastAPI(title="Haru GPT API", version="1.0.0")

# CORS 미들웨어 설정 - Flutter 앱에서 API 호출 가능하도록 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: 프로덕션 배포 시 특정 도메인만 허용하도록 수정 필요
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =============================================================================
# LLM 시스템 프롬프트
# =============================================================================
# LLM이 사용자 입력을 키워드로 태그화할 때 사용하는 기본 지침
# 감정적 표현 제외, 구체적 키워드 중심으로 5-6개 추출
system_prompt = """
[역할]
당신은 사용자의 문장에서 의미 있는 구체적 키워드를 추출하는 '태그 생성 전문가'입니다.

[태그화 규칙]
1. 사용자의 문장에서 **핵심 명사 또는 형용사**만 추출합니다.
2. **감정적·추상적 단어**(예: '좋은', '멋진', '재미있는', '예쁜', '최고')는 제외합니다.
3. **구체적인 사물, 음식, 행동, 분위기, 공간적 특징** 중심으로 태그화합니다.
4. **비유적 표현, 관용구, 강조 구절**(예: '둘이 먹다 하나 죽어도 모를 정도', '끝내준다')는 태그로 포함하지 않습니다.
5. 유사한 단어는 한 번만 포함합니다. (예: '한적한', '조용한' → 하나만)
6. 반드시 **5~6개의 키워드**만 출력합니다.
7. 출력은 반드시 **한 줄**, **쉼표(,)로만 구분**하여 작성합니다.
8. 설명, 문장, 불릿, 숫자, 따옴표 등은 포함하지 않습니다. **키워드만 출력하세요.**

[출력 형식 예시]
올바른 출력 예시: 치즈케이크, 고구마 라떼, 한적한, 뷰, 조용한 공간
잘못된 출력 예시: 키워드는 다음과 같습니다 → 치즈케이크, 뷰, 조용한 공간 
잘못된 출력 예시: ["치즈케이크","뷰","조용한 공간"] 

[예시]
입력: "치즈케익이 맛있고, 고구마 라떼가 있었으면 좋겠어. 그리고 한적하고, 뷰가 좋았으면 좋겠어."
출력: 치즈케이크, 고구마 라떼, 한적한, 뷰, 조용한 공간

입력: "바닐라 라떼가 맛있고, 초코케익이 있었으면 좋겠어."
출력: 바닐라 라떼, 초코케이크, 디저트, 음료, 달콤한

입력: "탁 트인 뷰가 좋고, 음악이 잔잔했으면 좋겠어."
출력: 뷰, 음악, 잔잔한, 분위기, 카페, 조용한

입력: "커피 맛이 진하고 좌석이 편한 곳이 좋아."
출력: 커피, 진한 맛, 좌석, 편한, 공간, 분위기

입력: "둘이 먹다 하나 죽어도 모를 것 같은 맛있는 김치찌개랑 돼지고기 삼겹살을 먹고 싶어."
출력: 김치찌개, 삼겹살, 돼지고기, 맛집, 한식, 식사
"""



# =============================================================================
# API 요청/응답 데이터 모델 (Pydantic)
# =============================================================================

class StartRequest(BaseModel):
    """대화 시작 요청 모델"""
    peopleCount: int                    # 함께할 인원 수
    selectedCategories: List[str]       # 선택한 활동 카테고리 (예: ["카페", "음식점"])


class ChatRequest(BaseModel):
    """채팅 메시지 요청 모델"""
    sessionId: str                      # 세션 식별자
    message: str                        # 사용자 메시지


class StartResponse(BaseModel):
    """대화 시작 응답 모델"""
    status: str                         # 상태 (success/error)
    sessionId: str                      # 생성된 세션 ID
    message: str                        # 챗봇 메시지
    stage: str                          # 현재 대화 단계
    progress: Dict[str, int]            # 진행 상태 (current, total)


class ChatResponse(BaseModel):
    """채팅 응답 모델"""
    status: str                                      # 상태
    message: str                                     # 챗봇 메시지
    stage: str                                       # 현재 대화 단계
    tags: Optional[List[str]] = None                 # 추출된 태그 목록
    progress: Optional[Dict[str, int]] = None        # 진행 상태
    recommendations: Optional[Dict[str, List[str]]] = None  # 최종 추천 결과
    
    # Flutter 클라이언트 호환성을 위한 필드 (이름은 yesNo지만 실제로는 Next/More 또는 Yes 버튼)
    showYesNoButtons: Optional[bool] = False         # 버튼 표시 여부
    yesNoQuestion: Optional[str] = None              # 버튼과 함께 보여줄 질문
    currentCategory: Optional[str] = None            # 현재 질문 중인 카테고리
    availableCategories: Optional[List[str]] = None  # 선택 가능한 카테고리 목록


# =============================================================================
# 세션 저장소
# =============================================================================
# 현재는 메모리 기반 딕셔너리 사용 (서버 재시작 시 초기화됨)
# 프로덕션에서는 Redis나 데이터베이스 사용 권장
sessions: Dict[str, Dict] = {}


# =============================================================================
# LLM 체인 초기화
# =============================================================================

def setup_chain():
    """
    LangChain 기반 LLM 체인 초기화
    
    GPT-4o-mini 모델을 사용하여 시스템 프롬프트 + 사용자 입력을 처리하는
    체인을 구성. Temperature 0.1로 설정해서 일관성 있는 태그 추출
    """
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=openai_api_key,
        temperature=0.1  # 낮은 온도로 일관된 결과 보장
    )
    
    prompt_template = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", "{user_input}")
    ])
    
    output_parser = StrOutputParser()
    return prompt_template | llm | output_parser


# 전역 LLM 체인 인스턴스 (앱 시작 시 한 번만 초기화)
chain = setup_chain()


# =============================================================================
# 상수: 챗봇 응답 메시지
# =============================================================================
# 하드코딩된 메시지 템플릿 - 일관된 대화 흐름 유지
RESPONSE_MESSAGES = {
    "start": {
        "first_message": "안녕! 나는 하루야!\n\n{people_count}명이 함께할 거구나! 그리고 {categories_text} 활동을 하고 싶다고 했지?\n\n그럼 먼저 '{first_category}' 활동에 대해 좀 더 자세히 말해줄 수 있을까? 어떤 걸 원해?",
        "next_category": "좋아! 그럼 '{next_category}' 활동은 어떤 걸 원해?",
        "all_completed": "모든 활동에 대한 질문이 끝났어! 이제 후보지를 출력하시겠습니까?",
        "add_more": "좋아! '{current_category}' 활동에 대해 더 추가하고 싶은 내용이 있나요?",
        "final_result": "짜잔! 오늘의 추천 리스트야! 이 중에서 마음에 드는 게 있으면 좋겠다! 즐거운 하루 보내!",
        "modification_mode": "어떤 내용을 수정하시겠습니까? 선택한 활동 중 더 추가하고 싶은 것이 있나요?",
        "unclear_response": "죄송해요! '네' 또는 '추가하기'로 답변해주세요.",
        "unclear_result_response": "죄송해요! '후보지 출력' 버튼을 눌러주세요."
    },
    "buttons": {
        "yes_no_question": "이 정보로 다음 질문으로 넘어가시겠습니까?",
        "result_question": "후보지를 출력하시겠습니까?"
    }
}


# =============================================================================
# 상수: 추천 데이터베이스
# =============================================================================
# 태그 기반 장소 추천 매핑 테이블
# 각 카테고리별로 키워드에 맞는 추천 장소를 하드코딩
# 추후 실제 DB나 외부 API로 대체 가능
RECOMMENDATION_DATABASE = {
    "카페": {
        "조용한": ["조용한 카페", "사일런트 카페", "조용한 공간"],
        "공부": ["스터디 카페", "학습 카페", "집중 카페"],
        "와이파이": ["와이파이 카페", "인터넷 카페", "디지털 카페"],
        "라떼": ["라떼 전문점", "바리스타 카페", "프리미엄 카페"],
        "케이크": ["디저트 카페", "케이크 전문점", "스위트 카페"],
        "뷰": ["뷰 카페", "전망 카페", "루프탑 카페"],
        "아늑한": ["아늑한 카페", "코지 카페", "홈 카페"],
        "모던한": ["모던 카페", "트렌디 카페", "컨템포러리 카페"],
        "치즈케이크": ["디저트 카페", "케이크 전문점", "스위트 카페"],
        "고구마 라떼": ["라떼 전문점", "바리스타 카페", "프리미엄 카페"],
        "바닐라 라떼": ["라떼 전문점", "바리스타 카페", "프리미엄 카페"],
        "초코케이크": ["디저트 카페", "케이크 전문점", "스위트 카페"]
    },
    "음식점": {
        "한식": ["전통 한식당", "정통 한식", "한국 요리"],
        "중식": ["중화요리", "중국집", "차이나"],
        "일식": ["일본 요리", "스시", "라멘"],
        "양식": ["서양 요리", "스테이크 하우스", "이탈리안"],
        "데이트": ["데이트 레스토랑", "로맨틱 레스토랑", "커플 레스토랑"],
        "가족": ["가족 레스토랑", "패밀리 레스토랑", "아이 친화적"],
        "저렴한": ["저렴한 식당", "가성비 식당", "맛집"],
        "고급": ["고급 레스토랑", "파인 다이닝", "럭셔리 레스토랑"]
    },
    "콘텐츠": {
        "영화": ["영화관", "시네마", "멀티플렉스"],
        "전시회": ["미술관", "박물관", "갤러리"],
        "공연": ["콘서트홀", "극장", "공연장"],
        "게임": ["게임카페", "PC방", "보드게임카페"],
        "쇼핑": ["쇼핑몰", "상가", "마켓"],
        "액션": ["액션 영화", "스릴러", "모험"],
        "로맨스": ["로맨스 영화", "멜로", "러브스토리"],
        "코미디": ["코미디 영화", "개그", "유머"]
    }
}


# =============================================================================
# 유틸리티 함수: 추천 생성
# =============================================================================

def generate_recommendations_by_category_hardcoded(category: str, tags: List[str]) -> str:
    """
    카테고리와 태그를 기반으로 추천 장소 생성 (하드코딩 버전)
    
    Args:
        category: 카테고리 이름 (예: "카페", "음식점")
        tags: 추출된 태그 리스트 (예: ["조용한", "와이파이"])
    
    Returns:
        추천 장소 문자열 (예: "1. 조용한 카페, 2. 사일런트 카페, 3. 조용한 공간")
    """
    if category not in RECOMMENDATION_DATABASE:
        return f"1. 일반적인 {category}, 2. 추천 {category}, 3. 인기 {category}"
    
    recommendations = []
    used_recommendations = set()
    
    # 태그별로 추천 찾기
    for tag in tags:
        if tag in RECOMMENDATION_DATABASE[category]:
            for rec in RECOMMENDATION_DATABASE[category][tag]:
                if rec not in used_recommendations:
                    recommendations.append(rec)
                    used_recommendations.add(rec)
                    if len(recommendations) >= 3:
                        break
        if len(recommendations) >= 3:
            break
    
    # 추천이 부족하면 기본 추천 추가
    if len(recommendations) < 3:
        default_recommendations = [
            f"추천 {category}",
            f"인기 {category}",
            f"베스트 {category}"
        ]
        for default_rec in default_recommendations:
            if default_rec not in used_recommendations:
                recommendations.append(default_rec)
                if len(recommendations) >= 3:
                    break
    
    # 형식에 맞게 변환
    formatted_recommendations = ", ".join([f"{i+1}. {rec}" for i, rec in enumerate(recommendations[:3])])
    return formatted_recommendations


# =============================================================================
# 유틸리티 함수: 태그 추출 (LLM 기반)
# =============================================================================

def extract_tags_by_category(user_detail: str, category: str, people_count: int = 1) -> List[str]:
    """
    카테고리별 맞춤 프롬프트로 LLM을 사용해 태그 추출
    
    각 카테고리(카페, 음식점, 콘텐츠)마다 다른 키워드 우선순위를 적용해서
    더 정확한 태그를 추출. 예를 들어 카페는 분위기/용도/시설 중심,
    음식점은 음식종류/메뉴/가격대 중심으로 추출
    
    Args:
        user_detail: 사용자가 입력한 문장
        category: 카테고리명
        people_count: 함께 활동할 인원 수
    
    Returns:
        추출된 태그 리스트 (5-6개)
    """
    try:
        # 인원수 관련 제외 규칙 생성
        people_exclusion_rule = ""
        if people_count >= 2:
            people_exclusion_rule = f"- 인원 수가 {people_count}명이므로 '혼자', '1인', '솔로', '혼밥' 등 1인 관련 키워드는 제외"
        
        # 카테고리별 맞춤 프롬프트 생성
        category_prompts = {
            "카페": f"""
            [상황 정보]
            - 인원 수: {people_count}명
            - 활동 카테고리: 카페
            
            사용자가 "{user_detail}"라고 말했어.

            이 문장에서 카페 활동과 관련된 핵심 키워드를 정확히 5~6개만 추출해서 쉼표로 구분해서 알려줘.

            **카페 관련 키워드 우선순위:**
            1. 분위기 (조용한, 활기찬, 아늑한, 모던한 등)
            2. 용도 (공부, 업무, 독서, 대화, 휴식 등)
            3. 시설 (와이파이, 콘센트, 넓은 공간, 야외석 등)
            4. 음료/메뉴 (커피, 차, 디저트, 브런치 등)
            5. 시간대 (아침, 점심, 저녁, 늦은 밤 등)

            **제외할 키워드:**
            - 감정적 표현 ('좋은', '멋진', '재미있는' 등)
            - 일반적 표현 ('편한', '괜찮은' 등)
            {people_exclusion_rule}

            다른 설명 없이 키워드만 나열해줘.
            """,
            "음식점": f"""
            [상황 정보]
            - 인원 수: {people_count}명
            - 활동 카테고리: 음식점
            
            사용자가 "{user_detail}"라고 말했어.

            이 문장에서 음식점 활동과 관련된 핵심 키워드를 정확히 5~6개만 추출해서 쉼표로 구분해서 알려줘.

            **음식점 관련 키워드 우선순위:**
            1. 음식 종류 (한식, 중식, 일식, 양식, 이탈리안 등)
            2. 메뉴 (김치찌개, 파스타, 초밥, 스테이크 등)
            3. 분위기 (데이트, 가족, 친구, 단체 등)
            4. 가격대 (저렴한, 보통, 비싼, 고급 등)
            5. 특징 (얼큰한, 매운, 담백한, 신선한 등)

            **제외할 키워드:**
            - 감정적 표현 ('맛있는', '좋은' 등)
            - 일반적 표현 ('괜찮은', '편한' 등)
            {people_exclusion_rule}

            다른 설명 없이 키워드만 나열해줘.
            """,
            "콘텐츠": f"""
            [상황 정보]
            - 인원 수: {people_count}명
            - 활동 카테고리: 콘텐츠
            
            사용자가 "{user_detail}"라고 말했어.

            이 문장에서 콘텐츠 활동과 관련된 핵심 키워드를 정확히 5~6개만 추출해서 쉼표로 구분해서 알려줘.

            **콘텐츠 관련 키워드 우선순위:**
            1. 활동 종류 (영화, 전시회, 공연, 게임, 쇼핑 등)
            2. 장르 (액션, 로맨스, 코미디, 드라마, 다큐멘터리 등)
            3. 분위기 (재미있는, 감동적인, 교육적인, 스릴있는 등)
            4. 참여 형태 (커플, 가족, 친구, 그룹 등)
            5. 시간대 (낮, 저녁, 밤, 주말, 평일 등)

            **제외할 키워드:**
            - 감정적 표현 ('좋은', '멋진' 등)
            - 일반적 표현 ('편한', '괜찮은' 등)
            {people_exclusion_rule}

            다른 설명 없이 키워드만 나열해줘.
            """
        }
        
        base_prompt = category_prompts.get(category, category_prompts["카페"])
        
        tag_response = chain.invoke({"user_input": base_prompt})
        tag_list = [tag.strip() for tag in tag_response.split(",") if tag.strip()]
        
        # 태그가 너무 적으면 재시도
        if len(tag_list) < 3:
            tag_response = chain.invoke({"user_input": base_prompt})
            tag_list = [tag.strip() for tag in tag_response.split(",") if tag.strip()]
        
        # 최소 1개는 보장
        if len(tag_list) == 0:
            tag_list = [user_detail.strip()[:10]]
        
        return tag_list
        
    except Exception as e:
        # 오류 발생 시 기본 태그 반환
        fallback_tag = [user_detail.strip()[:10]] if user_detail.strip() else ["일반적인"]
        return fallback_tag


def extract_tags(user_detail: str) -> List[str]:
    """
    범용 태그 추출 함수 (카테고리 구분 없이)
    
    카테고리가 지정되지 않았을 때 사용하는 기본 태그 추출 함수
    현재는 사용하지 않지만 확장성을 위해 유지
    
    Args:
        user_detail: 사용자 입력 문장
    
    Returns:
        추출된 태그 리스트
    """
    try:
        tagging_prompt = f"""
        사용자가 "{user_detail}"라고 말했어.

        이 문장에서 핵심 키워드를 정확히 5~6개만 추출해서 쉼표로 구분해서 알려줘.
        다른 설명 없이 키워드만 나열해줘.

        **중요 규칙:**
        1. 반드시 5~6개의 키워드를 추출해야 함
        2. 구체적이고 명확한 단어만 사용
        3. 감정적 표현('좋은', '멋진', '재미있는' 등)은 제외
        4. 공간, 상황, 행동, 특징 중심으로 추출
        5. 쉼표로만 구분하고 다른 기호 사용 금지

        예시:
        - 입력: "조용하고 와이파이 잘 되는 곳"
        - 출력: 조용한, 와이파이, 공부하기 좋은, 집중, 인터넷

        - 입력: "분위기 좋고 데이트하기 좋은 곳"  
        - 출력: 분위기 좋은, 데이트, 로맨틱, 프라이빗, 조용한

        이제 키워드를 추출해줘:
        """
        
        tag_response = chain.invoke({"user_input": tagging_prompt})
        tag_list = [tag.strip() for tag in tag_response.split(",") if tag.strip()]
        
        # 태그가 너무 적으면 재시도
        if len(tag_list) < 3:
            tag_response = chain.invoke({"user_input": tagging_prompt})
            tag_list = [tag.strip() for tag in tag_response.split(",") if tag.strip()]
        
        # 최소 1개는 보장
        if len(tag_list) == 0:
            tag_list = [user_detail.strip()[:10]]
        
        return tag_list
        
    except Exception as e:
        # 오류 발생 시 기본 태그 반환
        fallback_tag = [user_detail.strip()[:10]] if user_detail.strip() else ["일반적인"]
        return fallback_tag


def generate_recommendations_by_category(category: str, tags: List[str]) -> str:
    """
    카테고리별 추천 생성 (하드코딩 버전 래퍼)
    
    추후 DB나 외부 API로 변경 시 이 함수만 수정하면 됨
    """
    return generate_recommendations_by_category_hardcoded(category, tags)


def generate_recommendations(selected_activities: List[str], collected_tags: Dict[str, List[str]]) -> str:
    """
    모든 카테고리에 대한 최종 추천 생성
    
    수집된 태그를 바탕으로 각 카테고리별 추천을 생성하고
    하나의 문자열로 합쳐서 반환
    
    Args:
        selected_activities: 선택한 활동 카테고리 리스트
        collected_tags: 카테고리별로 수집된 태그 딕셔너리
    
    Returns:
        전체 추천 결과 문자열
    """
    all_recommendations = []
    
    # 각 카테고리별로 추천 생성
    for category in selected_activities:
        if category in collected_tags and collected_tags[category]:
            category_recommendations = generate_recommendations_by_category(category, collected_tags[category])
            all_recommendations.append(f"{category}: {category_recommendations}")
        else:
            default_tags = ["일반적인", "추천", "인기"]
            category_recommendations = generate_recommendations_by_category(category, default_tags)
            all_recommendations.append(f"{category}: {category_recommendations}")
    
    final_recommendations = "\n".join(all_recommendations)
    return final_recommendations


def parse_recommendations(recommendations_text: str, selected_activities: List[str]) -> Dict[str, List[str]]:
    """
    추천 결과 문자열을 Flutter가 사용할 수 있는 딕셔너리로 변환
    
    "카페: 1. 조용한 카페, 2. 사일런트 카페, 3. 조용한 공간" 형태의 문자열을
    {"카페": ["조용한 카페", "사일런트 카페", "조용한 공간"]} 형태로 파싱
    
    Args:
        recommendations_text: 전체 추천 결과 문자열
        selected_activities: 카테고리 리스트
    
    Returns:
        카테고리별 추천 장소 딕셔너리
    """
    result = {}
    lines = recommendations_text.strip().split('\n')
    
    for line in lines:
        if not line.strip():
            continue
        
        for category in selected_activities:
            if line.strip().startswith(category):
                # "카테고리: 1. 장소1, 2. 장소2, 3. 장소3" 형식 파싱
                content = line.split(':', 1)[1].strip() if ':' in line else line
                
                # 숫자와 점 제거하여 장소명만 추출
                places = []
                for part in content.split(','):
                    place = part.strip()
                    # "1. 장소명" -> "장소명" 형태로 변환
                    import re
                    place = re.sub(r'^\d+\.\s*', '', place)
                    if place:
                        places.append(place)
                
                result[category] = places
                break
    
    return result


# =============================================================================
# API 엔드포인트
# =============================================================================

@app.get("/")
async def root():
    """
    헬스 체크 엔드포인트
    
    서버 상태 확인용. API 서버가 정상 동작 중인지 체크
    """
    return {
        "status": "ok",
        "message": "Haru GPT API is running!",
        "version": "1.0.0"
    }


@app.post("/api/start", response_model=StartResponse)
async def start_conversation(request: StartRequest):
    """
    대화 시작 엔드포인트
    
    새로운 대화 세션을 생성하고 첫 번째 카테고리에 대한 질문 반환.
    세션 ID를 발급받아 이후 모든 요청에서 사용
    
    Request Body:
        - peopleCount: 함께할 인원 수
        - selectedCategories: 선택한 활동 카테고리 리스트
    
    Response:
        - sessionId: 발급된 세션 ID
        - message: 첫 번째 질문 메시지
        - stage: 현재 대화 단계
        - progress: 진행 상태
    """
    try:
        # 세션 ID 생성
        session_id = str(uuid.uuid4())
        
        # 세션 데이터 초기화
        sessions[session_id] = {
            "peopleCount": request.peopleCount,
            "selectedCategories": request.selectedCategories,
            "collectedTags": {},  # 카테고리별 태그 저장
            "currentCategoryIndex": 0,  # 현재 질문 중인 카테고리
            "conversationHistory": [],  # 대화 히스토리
            "stage": "collecting_details",  # 현재 단계: collecting_details, confirming_results, completed
            "waitingForUserAction": False,  # 사용자 액션(Next/More 또는 Yes) 대기 중인지
            "lastUserMessage": "",  # 마지막 사용자 메시지
            "pendingTags": [],  # 대기 중인 태그들
            "modificationMode": False,  # 수정 모드인지
        }
        
        # 첫 번째 카테고리에 대한 질문 생성 (인원수와 카테고리 정보 포함)
        first_category = request.selectedCategories[0]
        categories_text = ', '.join(request.selectedCategories)
        
        first_message = RESPONSE_MESSAGES["start"]["first_message"].format(
            people_count=request.peopleCount,
            categories_text=categories_text,
            first_category=first_category
        )
        
        return StartResponse(
            status="success",
            sessionId=session_id,
            message=first_message,
            stage="collecting_details",
            progress={
                "current": 0,
                "total": len(request.selectedCategories)
            }
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"세션 시작 중 오류 발생: {str(e)}")


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    채팅 메시지 처리 엔드포인트
    
    사용자 메시지를 받아서:
    1. 일반 메시지 → LLM으로 태그 추출 후 Next/More 버튼 표시
    2. Next/More 응답 → 다음 카테고리로 이동 또는 추가 입력 요청
    3. 결과 확인 Yes 응답 → 최종 추천 생성
    
    Request Body:
        - sessionId: 세션 ID
        - message: 사용자 메시지
    
    Response:
        - message: 챗봇 응답
        - tags: 추출된 태그 (있는 경우)
        - showYesNoButtons: 버튼 표시 여부
        - recommendations: 최종 추천 (있는 경우)
    """
    try:
        # 세션 확인
        if request.sessionId not in sessions:
            raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
        
        session = sessions[request.sessionId]
        
        # completed 상태 처리 - 대화 완료 후 추가 메시지
        if session.get("stage") == "completed":
            return ChatResponse(
                status="success",
                message="대화가 완료되었습니다. 새로운 대화를 시작하려면 처음부터 다시 시작해주세요.",
                stage="completed"
            )
        
        # modification_mode 처리
        if session.get("stage") == "modification_mode":
            return handle_modification_mode(session, request.message)
        
        # 사용자 액션(Next/More 또는 Yes) 응답 처리
        if session.get("waitingForUserAction", False):
            return handle_user_action_response(session, request.message)
        
        # 일반 메시지 처리 (태그 생성)
        return handle_user_message(session, request.message)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"채팅 처리 중 오류 발생: {str(e)}")


# =============================================================================
# 핸들러 함수: 대화 흐름 제어
# =============================================================================

def handle_user_message(session: Dict, user_message: str) -> ChatResponse:
    """
    사용자 메시지 처리 및 태그 생성
    - 사용자가 입력한 내용에서 LLM을 통해 태그 추출
    - Next/More 버튼 표시
    """
    # 사용자 메시지 저장
    session["conversationHistory"].append({
        "role": "user",
        "message": user_message
    })
    session["lastUserMessage"] = user_message
    
    # 현재 카테고리 정보 확인
    current_index = session["currentCategoryIndex"]
    selected_categories = session["selectedCategories"]
    
    # 인덱스 범위 확인
    if current_index >= len(selected_categories):
        # 모든 카테고리 완료 -> 결과 출력 확인 단계로 전환
        session["stage"] = "confirming_results"
        session["waitingForUserAction"] = True  # 결과 출력 Yes 버튼 대기
        return ChatResponse(
            status="success",
            message=RESPONSE_MESSAGES["start"]["all_completed"],
            stage="confirming_results",
            showYesNoButtons=True,  # Yes 버튼 표시
            yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"],
            availableCategories=selected_categories
        )
    
    current_category = selected_categories[current_index]
    
    # 카테고리별 태그 추출 (LLM 사용)
    people_count = session.get("peopleCount", 1)
    new_tags = extract_tags_by_category(user_message, current_category, people_count)
    
    # collectedTags 초기화 확인
    if "collectedTags" not in session:
        session["collectedTags"] = {}
    
    # 기존 태그가 있는지 확인하고 추가
    if current_category in session["collectedTags"]:
        # 기존 태그가 있으면 새로운 태그와 합치기 (추가하기 선택한 경우)
        existing_tags = session["collectedTags"][current_category]
        combined_tags = existing_tags + new_tags
        # 중복 제거
        combined_tags = list(dict.fromkeys(combined_tags))  # 순서 유지하면서 중복 제거
        session["collectedTags"][current_category] = combined_tags
        session["pendingTags"] = combined_tags
    else:
        # 기존 태그가 없으면 새로운 태그만 사용
        session["collectedTags"][current_category] = new_tags
        session["pendingTags"] = new_tags
    
    tags = session["pendingTags"]
    
    # 태그 표시
    message = f"현재까지 수집된 키워드: {', '.join(tags)}"
    
    # Next/More 버튼 대기 상태로 전환
    session["waitingForUserAction"] = True
    
    return ChatResponse(
        status="success",
        message=message,
        stage="collecting_details",
        tags=tags,
        progress={
            "current": session["currentCategoryIndex"],
            "total": len(session["selectedCategories"])
        },
        showYesNoButtons=True,  # Next/More 버튼 표시
        yesNoQuestion="이 정보로 다음 질문으로 넘어가시겠습니까?",
        currentCategory=current_category
    )


def handle_user_action_response(session: Dict, user_response: str) -> ChatResponse:
    """
    사용자 버튼 액션 처리 (Next / More / Yes)
    
    대화 단계에 따라 다른 동작 수행:
    - collecting_details: Next(다음 카테고리) 또는 More(추가 입력)
    - confirming_results: Yes(최종 추천 생성)
    
    Args:
        session: 세션 데이터
        user_response: 사용자 응답 ("네", "추가하기" 등)
    
    Returns:
        다음 단계 응답
    """
    # 응답 파싱
    is_next = any(word in user_response.lower() for word in ["yes", "네", "넵", "예", "좋아", "좋아요", "그래", "맞아", "ㅇㅇ", "기기", "ㄱㄱ", "고고", "네네", "다음"])
    is_more = any(word in user_response.lower() for word in ["추가", "더", "더해", "추가하기", "추가요", "더할래"])
    
    # 결과 출력 확인 단계: Yes(결과 출력) 처리
    if session.get("stage") == "confirming_results":
        if is_next:
            # 추천 결과 생성
            recommendations_text = generate_recommendations(
                session["selectedCategories"],
                session["collectedTags"]
            )
            
            recommendations_dict = parse_recommendations(
                recommendations_text,
                session["selectedCategories"]
            )
            
            # 대화 완료 상태로 전환
            session["stage"] = "completed"
            session["waitingForUserAction"] = False
            
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["final_result"],
                stage="completed",
                recommendations=recommendations_dict
            )
        else:
            # 명확하지 않은 응답 - 사용자 액션 대기 상태 유지
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["unclear_result_response"],
                stage="confirming_results",
                showYesNoButtons=True,
                yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"]
            )
    
    # 태그 수집 단계: Next(다음 카테고리로) / More(현재 카테고리에 추가 입력) 처리
    if is_next and not is_more:
        return handle_next_category(session)
    elif is_more and not is_next:
        return handle_add_more_tags(session)
    else:
        # 명확하지 않은 응답 - 사용자 액션 대기 상태 유지
        return ChatResponse(
            status="success",
            message=RESPONSE_MESSAGES["start"]["unclear_response"],
            stage=session["stage"],
            showYesNoButtons=True,
            yesNoQuestion=RESPONSE_MESSAGES["buttons"]["yes_no_question"]
        )


def handle_next_category(session: Dict) -> ChatResponse:
    """
    Next 버튼 처리
    
    현재 카테고리 태그 수집 완료 후 다음 카테고리로 이동.
    모든 카테고리 완료 시 결과 출력 확인 단계로 전환
    
    Args:
        session: 세션 데이터
    
    Returns:
        다음 카테고리 질문 또는 결과 확인 메시지
    """
    # 사용자 액션 대기 상태 해제
    session["waitingForUserAction"] = False
    
    # 현재 카테고리 정보
    current_index = session["currentCategoryIndex"]
    selected_categories = session["selectedCategories"]
    
    # 인덱스 범위 확인
    if current_index >= len(selected_categories):
        # 이미 완료된 상태 -> 결과 출력 확인 단계로
        session["stage"] = "confirming_results"
        session["waitingForUserAction"] = True  # Yes 버튼 대기
        return ChatResponse(
            status="success",
            message=RESPONSE_MESSAGES["start"]["all_completed"],
            stage="confirming_results",
            showYesNoButtons=True,  # Yes 버튼 표시
            yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"],
            availableCategories=selected_categories
        )
    
    # 다음 카테고리로 이동
    session["currentCategoryIndex"] += 1
    
    # 더 질문할 카테고리가 있는지 확인
    if session["currentCategoryIndex"] < len(selected_categories):
        # 다음 카테고리 질문
        next_category = selected_categories[session["currentCategoryIndex"]]
        next_message = RESPONSE_MESSAGES["start"]["next_category"].format(next_category=next_category)
        
        return ChatResponse(
            status="success",
            message=next_message,
            stage="collecting_details",
            progress={
                "current": session["currentCategoryIndex"],
                "total": len(selected_categories)
            }
        )
    else:
        # 모든 카테고리 완료 -> 결과 출력 확인 단계로
        session["stage"] = "confirming_results"
        session["waitingForUserAction"] = True  # Yes 버튼 대기
        
        return ChatResponse(
            status="success",
            message=RESPONSE_MESSAGES["start"]["all_completed"],
            stage="confirming_results",
            showYesNoButtons=True,  # Yes 버튼 표시
            yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"],
            availableCategories=selected_categories
        )


def handle_modification_mode(session: Dict, user_message: str) -> ChatResponse:
    """
    수정 모드 처리 (현재 미사용)
    
    사용자가 이전 카테고리로 돌아가서 수정하고 싶을 때 사용.
    추후 확장 기능으로 개발 예정
    
    Args:
        session: 세션 데이터
        user_message: 사용자가 선택한 카테고리명
    
    Returns:
        선택한 카테고리로 이동 또는 재질문
    """
    # 사용자가 선택한 카테고리 확인
    selected_categories = session["selectedCategories"]
    selected_category = None
    
    for category in selected_categories:
        if category in user_message:
            selected_category = category
            break
    
    if selected_category:
        # 해당 카테고리의 인덱스 찾기
        category_index = selected_categories.index(selected_category)
        
        # 해당 카테고리로 돌아가기
        session["currentCategoryIndex"] = category_index
        session["stage"] = "collecting_details"
        session["waitingForUserAction"] = False
        
        # 해당 카테고리에 대한 질문 생성
        message = f"좋아! '{selected_category}' 활동에 대해 더 추가하고 싶은 내용이 있나요?"
        
        return ChatResponse(
            status="success",
            message=message,
            stage="collecting_details",
            currentCategory=selected_category
        )
    else:
        # 카테고리를 명확히 선택하지 않은 경우
        return ChatResponse(
            status="success",
            message="어떤 활동을 수정하고 싶으신가요? 카테고리명을 말씀해주세요.",
            stage="modification_mode",
            availableCategories=selected_categories
        )


def handle_add_more_tags(session: Dict) -> ChatResponse:
    """
    More 버튼 처리
    
    사용자가 현재 카테고리에 대해 추가 정보를 입력하고 싶을 때.
    같은 카테고리에 대한 추가 태그가 기존 태그와 병합됨
    
    Args:
        session: 세션 데이터
    
    Returns:
        추가 입력 요청 메시지
    """
    # 사용자 액션 대기 상태 해제
    session["waitingForUserAction"] = False
    
    current_index = session["currentCategoryIndex"]
    selected_categories = session["selectedCategories"]
    
    # 인덱스 범위 확인
    if current_index >= len(selected_categories):
        # 이미 완료된 상태 -> 결과 출력 확인 단계로
        session["stage"] = "confirming_results"
        session["waitingForUserAction"] = True  # Yes 버튼 대기
        return ChatResponse(
            status="success",
            message=RESPONSE_MESSAGES["start"]["all_completed"],
            stage="confirming_results",
            showYesNoButtons=True,  # Yes 버튼 표시
            yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"],
            availableCategories=selected_categories
        )
    
    current_category = selected_categories[current_index]
    
    return ChatResponse(
        status="success",
        message=RESPONSE_MESSAGES["start"]["add_more"].format(current_category=current_category),
        stage="collecting_details",
        currentCategory=current_category
    )


@app.post("/api/confirm-results", response_model=ChatResponse)
async def confirm_results(request: ChatRequest):
    """
    결과 출력 확인 엔드포인트 (레거시)
    
    현재는 /api/chat에서 모두 처리하므로 사용하지 않음.
    하위 호환성 유지를 위해 남겨둠
    """
    try:
        if request.sessionId not in sessions:
            raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
        
        session = sessions[request.sessionId]
        
        # Yes/No 응답 파싱
        is_yes = any(word in request.message.lower() for word in ["yes", "네", "넵", "예", "좋아", "좋아요", "그래", "맞아", "ㅇㅇ", "기기", "ㄱㄱ", "고고", "네네", "다음"])
        
        if is_yes:
            # 추천 생성
            recommendations_text = generate_recommendations(
                session["selectedCategories"],
                session["collectedTags"]
            )
            
            recommendations_dict = parse_recommendations(
                recommendations_text,
                session["selectedCategories"]
            )
            
            session["stage"] = "completed"
            
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["final_result"],
                stage="completed",
                recommendations=recommendations_dict
            )
        else:
            # 명확하지 않은 응답
            return ChatResponse(
                status="success",
                message=RESPONSE_MESSAGES["start"]["unclear_result_response"],
                stage="confirming_results",
                showYesNoButtons=True,
                yesNoQuestion=RESPONSE_MESSAGES["buttons"]["result_question"]
            )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"결과 확인 처리 중 오류 발생: {str(e)}")


# =============================================================================
# 디버깅용 엔드포인트
# =============================================================================

@app.get("/api/sessions")
async def list_sessions():
    """
    현재 활성 세션 목록 조회
    
    개발 및 디버깅 용도. 메모리에 저장된 모든 세션 ID 확인 가능
    프로덕션 배포 시 제거하거나 인증 필요
    """
    return {
        "total": len(sessions),
        "sessions": list(sessions.keys())
    }


@app.get("/api/sessions/{session_id}")
async def get_session(session_id: str):
    """
    특정 세션 상세 정보 조회
    
    세션의 모든 데이터를 반환. 디버깅 시 대화 흐름 추적에 유용
    프로덕션 배포 시 제거하거나 인증 필요
    
    Path Parameter:
        session_id: 조회할 세션 ID
    """
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")
    return sessions[session_id]


# =============================================================================
# 서버 실행
# =============================================================================

if __name__ == "__main__":
    import uvicorn
    # 개발 서버 실행 (Hot Reload 활성화)
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)