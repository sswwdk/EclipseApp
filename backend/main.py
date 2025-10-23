from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import test_connection, create_tables, insert_sample_data
import os

# 라우터 임포트
from routers import auth, users, service, community, history, chat, like, inquiries, notice

app = FastAPI(
    title="WhatToDo API",
    description="Flutter 앱을 위한 REST API",
    version="1.0.0"
)

# Flutter 접근 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(service.router)
app.include_router(community.router)
app.include_router(history.router)
app.include_router(chat.router)
app.include_router(like.router)
app.include_router(inquiries.router)
app.include_router(notice.router)

@app.on_event("startup")
async def startup_event():
    """서버 시작 시 데이터베이스 연결 테스트 및 테이블 생성"""
    print("서버 시작 중...")
    if test_connection():
        create_tables()
        try:
            insert_sample_data()
        except Exception as e:
            print(f"샘플 데이터 삽입 실패 (무시): {e}")
        print("서버 시작 완료!")
    else:
        print("데이터베이스 연결 실패!")

@app.get("/")
async def root():
    """API 상태 확인"""
    return {"message": "WhatToDo API가 정상적으로 실행 중입니다!"}

@app.get("/health")
async def health_check():
    """데이터베이스 연결 상태 확인"""
    try:
        if test_connection():
            return {"status": "healthy", "database": "connected"}
        else:
            return {"status": "unhealthy", "database": "disconnected"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host=host, port=port)
