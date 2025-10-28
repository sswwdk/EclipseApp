"""
Haru GPT API 서버 실행 스크립트
"""

import uvicorn

if __name__ == "__main__":
    # 개발 서버 실행 (Hot Reload 활성화)
    uvicorn.run(
        "haru_gpt.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )

