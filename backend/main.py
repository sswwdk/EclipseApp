from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from database import get_connection, test_connection, create_tables, insert_sample_data
from sqlalchemy import text
import os

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

@app.get("/restaurants")
async def get_restaurants():
    """모든 레스토랑 목록 조회 (category 테이블에서)"""
    try:
        with get_connection() as conn:
            query = text("SELECT * FROM category ORDER BY last_crawl DESC")
            result = conn.execute(query)
            data = [dict(row) for row in result]
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.get("/restaurants/{restaurant_id}")
async def get_restaurant(restaurant_id: str):
    """특정 레스토랑 상세 정보 조회 (category 테이블에서)"""
    try:
        with get_connection() as conn:
            query = text("SELECT * FROM category WHERE id = :id")
            result = conn.execute(query, {"id": restaurant_id})
            row = result.fetchone()

            if not row:
                raise HTTPException(status_code=404, detail="레스토랑을 찾을 수 없습니다")

            data = dict(row)
        return {"success": True, "data": data}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host=host, port=port)
