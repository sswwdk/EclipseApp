#!/usr/bin/env python3
"""
서버 실행 스크립트
"""
import uvicorn
from config import SERVER_CONFIG

if __name__ == "__main__":
    print(f"서버를 시작합니다...")
    print(f"호스트: {SERVER_CONFIG['host']}")
    print(f"포트: {SERVER_CONFIG['port']}")
    print(f"API 문서: http://{SERVER_CONFIG['host']}:{SERVER_CONFIG['port']}/docs")
    
    uvicorn.run(
        "main:app",
        host=SERVER_CONFIG['host'],
        port=SERVER_CONFIG['port'],
        reload=True,  # 개발 모드에서 자동 재시작
        log_level="info"
    )
