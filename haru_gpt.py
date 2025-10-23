import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# ==================== 환경 설정 ====================
load_dotenv()
openai_api_key = os.getenv("OPENAI_API_KEY")

# ==================== 시스템 프롬프트 ====================
system_prompt = """
당신의 이름은 '하루'입니다.  
당신은 사용자의 '오늘 활동 계획'을 함께 정리하고 추천하는 챗봇입니다.  
입력된 사용자 답변을 정제하고, 태그화하여, 다음 대화(질문)을 자연스럽게 이어가는 것이 목표입니다.
사용자에게 "대화"로 인식하도록 응답하세요.

────────────────────────────
[시스템 명세 - JSON 구조 정의]
────────────────────────────
아래는 당신이 반드시 따라야 할 내부 처리 파이프라인입니다.  
각 단계를 순서대로 수행하고, 출력은 지정된 JSON 스키마를 따르세요.

{{
  "role": "assistant",
  "process_pipeline": [
    "1. 사용자 답변 필터링",
    "2. LLM 태그화",
    "3. 태그 결과 필터링",
    "4. 프롬프트 규칙 검증"
  ],
  "stage_description": {{
    "1. 사용자 답변 필터링": "입력의 길이, 개인정보, 특수문자, 반복문자를 제거하여 깨끗한 텍스트로 만든다.",
    "2. LLM 태그화": "사용자의 의도를 4~6개의 의미 있는 태그로 요약한다.",
    "3. 태그 결과 필터링": "금지 단어, 의미 없는 태그, 중복 태그를 제거한다.",
    "4. 프롬프트 규칙 검증": "서비스 정책(비속어, 불쾌한 표현 등)에 위배되지 않는지 확인한다."
  }},
  "output_format": {{
    "category": "<카페|음식점|콘텐츠 중 하나>",
    "tags": ["키워드1", "키워드2", "키워드3"],
    "filtering_reason": "<필요 시, 제거/보정 사유>"
  }}
}}

────────────────────────────
[행동 지침 - 대화 스타일 & 로직 수행 방식]
────────────────────────────
1. **하루의 말투**
   - 따뜻하고 친근하게, 친구처럼 자연스럽게 대화하세요.
   - 질문은 한 번에 하나씩만 합니다.
   - 사용자가 헷갈리지 않게, 짧고 명확하게 질문합니다.

2. **태그화 규칙**
   - 사용자의 문장을 "의미 있는 핵심 단어" 중심으로 태그화합니다.
   - 감정적이거나 추상적인 단어('좋은', '멋진' 등)는 제거하고, 구체적인 상황/공간/행동 중심으로 정리합니다.

3. **규칙 위반 또는 불명확 입력 처리**
   - 욕설, 비방, 개인정보 포함 등 서비스 위반 문장은 거부하고 재질문합니다.

────────────────────────────
[핵심 원칙]
────────────────────────────
- **한국어**를 사용하세요. 무조건 한국어만 사용하세요.
- 구조적으로 생각하되, 사용자에게는 자연스러운 대화로 표현하세요.
- 사용자에게 제공하는 답변은 대화로 인식하도록 응답하세요.
- 항상 친근하고 긍정적인 말투를 유지하세요.
"""

# ==================== LLM 체인 설정 ====================
def setup_chain():
    """LLM 체인을 초기화합니다."""
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=openai_api_key,
        temperature=0.1
    )
    
    prompt_template = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("user", "{user_input}")
    ])
    
    output_parser = StrOutputParser()
    return prompt_template | llm | output_parser


# ==================== 유틸리티 함수 ====================
def get_valid_activities(activity_input):
    """사용자 입력에서 유효한 활동만 필터링합니다."""
    valid_activities = ["카페", "음식점", "콘텐츠"]
    selected = [
        activity.strip() 
        for activity in activity_input.split(",") 
        if activity.strip() in valid_activities
    ]
    return selected


def extract_tags(chain, user_detail):
    """사용자 답변에서 태그를 추출합니다."""
    tagging_prompt = f"""
    사용자가 "{user_detail}"라고 말했어.

    이 문장에서 핵심 키워드를 5~6개만 추출해서 쉼표로 구분해서 알려줘.
    다른 설명 없이 키워드만 나열해줘.

    예시: 조용한, 공부하기 좋은, 와이파이, 디저트, 창가 자리
    """
    
    tag_response = chain.invoke({"user_input": tagging_prompt})
    tag_list = [tag.strip() for tag in tag_response.split(",")]
    return tag_list


def generate_recommendations(chain, selected_activities, collected_tags):
    """수집된 태그를 바탕으로 추천 장소를 생성합니다."""
    # 태그 정보를 텍스트로 정리
    tags_text = ""
    for category, tags in collected_tags.items():
        tags_text += f"\n- {category}: {', '.join(tags)}"
    
    # 선택된 카테고리 목록 문자열로 변환
    categories_list = "', '".join(selected_activities)
    
    # LLM에게 추천 장소 생성 요청
    recommend_prompt = f"""
    아래 정보를 바탕으로 추천 장소를 만들어줘.

    [사용자가 선택한 활동 (이것만 출력해야 함)]
    {', '.join(selected_activities)}

    [각 활동별 선호 키워드]
    {tags_text}

    [중요: 출력 규칙]
    1. **'{categories_list}' 카테고리에 대해서만** 각 3개씩 추천해줘
    2. 선택되지 않은 다른 카테고리는 **절대 출력하지 마**
    3. 실제 있을 법한 창의적인 장소 이름을 만들어줘
    4. 추천 이유나 설명은 쓰지 말고 **장소 이름만** 써줘
    5. 각 카테고리는 반드시 다음 형식으로만 작성: "카테고리명: 1. 장소명, 2. 장소명, 3. 장소명"
    
    출력 예시:
    {selected_activities[0]}: 1. 장소명A, 2. 장소명B, 3. 장소명C
    """
    
    recommendations = chain.invoke({"user_input": recommend_prompt})
    return recommendations


def filter_recommendations(recommendations, selected_activities):
    """선택한 카테고리만 포함되도록 추천 결과를 필터링합니다."""
    result_lines = recommendations.split('\n')
    filtered_lines = []
    
    for line in result_lines:
        # 빈 줄은 그대로 포함
        if not line.strip():
            continue
        
        # 선택한 카테고리로 시작하는 줄만 포함
        if any(line.strip().startswith(cat) for cat in selected_activities):
            filtered_lines.append(line)
    
    return '\n'.join(filtered_lines)


# ==================== 메인 실행 로직 ====================
def main():
    """메인 실행 함수"""
    try:
        # LLM 체인 초기화
        chain = setup_chain()
        
        # 1. 인원 수 입력
        print("하루: 안녕! 나는 너의 하루를 계획하는 걸 도와줄 챗봇 하루야.")
        print("하루: 오늘 누구랑 함께할 거야? (예: 혼자 / 2명 / 친구랑)")
        people = input("나: ")
        print(f"사용자 답변: {people}")
        
        # 2. 활동 선택 입력
        print("\n하루: 그렇구나! 어떤 활동을 하고 싶어? ('카페', '음식점', '콘텐츠' 중에서 원하는 만큼 알려줘. 쉼표로 구분해도 좋아!)")
        activity_input = input("나: ")
        print(f"사용자 답변: {activity_input}")
        
        # 3. 유효한 활동만 필터링
        selected_activities = get_valid_activities(activity_input)
        
        if not selected_activities:
            print("하루: 활동을 하나라도 골라줘야 추천을 도와줄 수 있어!")
            return
        
        # 4. 각 활동별 세부 정보 수집 및 태그화
        collected_tags = {}
        
        for activity in selected_activities:
            print(f"\n하루: 좋아! '{activity}' 활동에 대해 좀 더 자세히 말해줄 수 있을까? 어떤 걸 원해?")
            detail = input("나: ")
            print(f"사용자 답변: {detail}")
            
            # 태그 추출
            tag_list = extract_tags(chain, detail)
            collected_tags[activity] = tag_list
            
            print(f"사용자 답변 태그화: '{activity}' 활동에 대한 태그 -> {', '.join(tag_list)}")
        
        # 5. 추천 장소 생성
        if collected_tags:
            print("\n하루: 좋아! 이제 너를 위한 추천을 만들어볼게. 잠시만 기다려줘!")
            
            # 추천 생성
            recommendations = generate_recommendations(chain, selected_activities, collected_tags)
            
            # 선택한 카테고리만 필터링
            filtered_recommendations = filter_recommendations(recommendations, selected_activities)
            
            # 결과 출력
            print("\n" + "=" * 50)
            print("하루: 짜잔! 오늘의 추천 리스트야!")
            print(filtered_recommendations)
            print("=" * 50)
            print("\n하루: 이 중에서 마음에 드는 게 있으면 좋겠다! 즐거운 하루 보내!")
        else:
            print("\n하루: 아직 태그가 없어서 추천을 만들 수 없어. 다시 한 번 시도해보자!")
    
    except Exception as e:
        print(f"\n이런, 대화 중에 문제가 생겼어: {e}")
        print("모델 이름이나 API 키가 올바른지 다시 확인해줘.")


# ==================== 프로그램 시작 ====================
if __name__ == "__main__":
    main()