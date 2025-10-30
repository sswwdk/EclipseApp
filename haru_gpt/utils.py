"""
태그 추출, 추천 생성 함수
"""

import re
from typing import Dict, List, Optional
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

from .config import openai_api_key
from .prompts import SYSTEM_PROMPT, get_category_prompt, get_general_tagging_prompt
from .database import RECOMMENDATION_DATABASE


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
        ("system", SYSTEM_PROMPT),
        ("user", "{user_input}")
    ])
    
    output_parser = StrOutputParser()
    return prompt_template | llm | output_parser


# 전역 LLM 체인 인스턴스 (앱 시작 시 한 번만 초기화)
chain = setup_chain()


# =============================================================================
# 태그 추출 함수
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
        base_prompt = get_category_prompt(category, user_detail, people_count)
        
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
        tagging_prompt = get_general_tagging_prompt(user_detail)
        
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


# =============================================================================
# 추천 생성 함수
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


def generate_recommendations_by_category(category: str, tags: List[str]) -> str:
    """
    카테고리별 추천 생성 (하드코딩 버전 래퍼)
    
    추후 DB나 외부 API로 변경 시 이 함수만 수정하면 됨
    """
    return generate_recommendations_by_category_hardcoded(category, tags)


def generate_recommendations(selected_activities: List[str], collected_tags: Dict[str, List[str]], location: Optional[str] = None) -> str:
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
            if location:
                all_recommendations.append(f"{category} ({location}): {category_recommendations}")
            else:
                all_recommendations.append(f"{category}: {category_recommendations}")
        else:
            default_tags = ["일반적인", "추천", "인기"]
            category_recommendations = generate_recommendations_by_category(category, default_tags)
            if location:
                all_recommendations.append(f"{category} ({location}): {category_recommendations}")
            else:
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
                    place = re.sub(r'^\d+\.\s*', '', place)
                    if place:
                        places.append(place)
                
                result[category] = places
                break
    
    return result

