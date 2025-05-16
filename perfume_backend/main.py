from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.exception_handlers import request_validation_exception_handler

# 각 기능별 라우터 임포트
from perfume_backend.routers.perfume_router import router as perfume_router
from perfume_backend.routers.store_router import router as store_router
from perfume_backend.routers.course_router import router as course_router
from perfume_backend.routers.recommend_router import router as recommend_router
from perfume_backend.routers.diary_router import router as diary_router

app = FastAPI()

# 모든 라우터 등록
app.include_router(perfume_router)      # 향수 목록, 상세, 리뷰
app.include_router(store_router)        # 매장 전체, 브랜드별 조회
app.include_router(course_router)       # 향수 코스 추천
app.include_router(recommend_router)    # 향수 추천 (성별/감정/계절/시간 기반)
app.include_router(diary_router)        # 시향 일기 저장

# (선택) 유효성 검사 에러 커스텀 응답 처리
# @app.exception_handler(RequestValidationError)
# async def validation_exception_handler(request: Request, exc: RequestValidationError):
#     return JSONResponse(
#         status_code=422,
#         content={"message": "입력값이 유효하지 않습니다. notes는 문자열 리스트여야 합니다."},
#     )

# 루트 엔드포인트 (서버 확인용)
@app.get(
    "/",
    summary="루트",
    description="서버 동작 확인용 엔드포인트입니다.",
    response_description="서버 작동 메시지 반환"
)
def read_root():
    return {"message": "Hello, FastAPI is working!"}
