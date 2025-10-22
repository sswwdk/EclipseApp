# database.py
import os
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from typing import Optional
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

_ENGINE: Optional[Engine] = None

def _dsn() -> str:
    dialect = os.getenv("DB_DIALECT", "mysql+pymysql")
    user    = os.getenv("DB_USER", "")
    pw      = os.getenv("DB_PASSWORD", "")
    host    = os.getenv("DB_HOST", "127.0.0.1")
    port    = os.getenv("DB_PORT", "3306")
    name    = os.getenv("DB_NAME", "")

    # ← 반드시 URL 인코딩!
    user_q = quote_plus(user)
    pw_q   = quote_plus(pw)
    name_q = quote_plus(name)

    return f"{dialect}://{user_q}:{pw_q}@{host}:{port}/{name_q}?charset=utf8mb4"

def get_engine() -> Engine:
    global _ENGINE
    if _ENGINE is None:
        _ENGINE = create_engine(
            _dsn(),
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,
        )
    return _ENGINE

def get_connection():
    """
    SQLAlchemy 엔진을 통해 데이터베이스 연결을 반환합니다.
    """
    return get_engine().connect()

def test_connection() -> bool:
    """
    데이터베이스 연결을 테스트합니다.
    """
    try:
        with get_connection() as conn:
            result = conn.execute(text("SELECT 1"))
            result.fetchone()
        print("데이터베이스 연결 성공!")
        return True
    except Exception as e:
        print(f"데이터베이스 연결 테스트 실패: {e}")
        return False

def create_tables():
    """
    필요한 테이블들을 생성합니다.
    """
    try:
        with get_connection() as conn:
            # restaurants 테이블 생성
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS restaurants (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    address VARCHAR(500),
                    phone VARCHAR(20),
                    rating DECIMAL(3,2) DEFAULT 0.0,
                    description TEXT,
                    image_url VARCHAR(500),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """))
            
            # users 테이블 생성
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS users (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    username VARCHAR(100) UNIQUE NOT NULL,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """))
            
            # todos 테이블 생성 (Foreign Key 제거)
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS todos (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT,
                    title VARCHAR(255) NOT NULL,
                    description TEXT,
                    completed BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """))
            
        print("테이블 생성 완료!")
        
    except Exception as e:
        print(f"테이블 생성 오류: {e}")
        raise e

def insert_sample_data():
    """
    샘플 데이터를 삽입합니다.
    """
    try:
        with get_connection() as conn:
            # 샘플 레스토랑 데이터 삽입
            conn.execute(text("""
                INSERT IGNORE INTO restaurants (name, address, phone, rating, description, image_url) VALUES
                ('맛있는 치킨집', '서울시 강남구 테헤란로 123', '02-1234-5678', 4.5, '바삭한 치킨과 다양한 소스가 인기', 'https://example.com/chicken.jpg'),
                ('정통 파스타', '서울시 홍대입구역 456', '02-2345-6789', 4.2, '이탈리안 정통 파스타 전문점', 'https://example.com/pasta.jpg'),
                ('한우 스테이크', '서울시 강남구 압구정로 789', '02-3456-7890', 4.8, '프리미엄 한우 스테이크 전문점', 'https://example.com/steak.jpg'),
                ('신선한 회', '서울시 강동구 천호동 101', '02-4567-8901', 4.3, '매일 신선한 활어회와 초밥', 'https://example.com/sushi.jpg'),
                ('따뜻한 국수', '서울시 마포구 홍대 202', '02-5678-9012', 4.0, '정성스럽게 끓인 국수와 만두', 'https://example.com/noodles.jpg')
            """))
            
            # 샘플 사용자 데이터 삽입
            conn.execute(text("""
                INSERT IGNORE INTO users (username, email, password_hash) VALUES
                ('testuser1', 'user1@example.com', 'hashed_password_1'),
                ('testuser2', 'user2@example.com', 'hashed_password_2'),
                ('testuser3', 'user3@example.com', 'hashed_password_3')
            """))
            
            # 샘플 할일 데이터 삽입
            conn.execute(text("""
                INSERT IGNORE INTO todos (user_id, title, description, completed) VALUES
                (1, '치킨집 방문하기', '맛있는 치킨집에서 치킨 먹기', FALSE),
                (1, '운동하기', '헬스장에서 1시간 운동', FALSE),
                (2, '책 읽기', '프로그래밍 책 1장 읽기', TRUE),
                (2, '영화 보기', '최신 영화 극장에서 보기', FALSE),
                (3, '친구 만나기', '오랜만에 친구들과 만나서 식사', TRUE)
            """))
            
        print("샘플 데이터 삽입 완료!")
        
    except Exception as e:
        print(f"샘플 데이터 삽입 오류: {e}")
        raise e