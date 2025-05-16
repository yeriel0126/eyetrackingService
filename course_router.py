from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List
import math, os, json

router = APIRouter(prefix="/courses", tags=["Course"])

# BaseResponse 정의
class BaseResponse(BaseModel):
    status: int = Field(..., example=200)
    message: str = Field(..., example="Success")
    result: List[dict] = Field(...)

# 요청 바디 정의
class SimpleCourseRecommendRequest(BaseModel):
    latitude: float = Field(..., description="사용자 위도")
    longitude: float = Field(..., description="사용자 경도")
    perfumes: List[str] = Field(..., description="추천받은 향수 리스트 (5개 예상)")

# 거리 계산 함수
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # 지구 반지름 (km)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c  # 거리 (km)

# 데이터 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
store_path = os.path.join(BASE_DIR, "../data/store_data.json")

with open(store_path, "r", encoding="utf-8") as f:
    store_data = json.load(f)

# 코스 추천 API
@router.post("/recommend", response_model=BaseResponse, summary="향수 코스 추천", description="추천 향수 리스트 + 사용자 위치 기반으로 매장을 추천합니다.")
def recommend_course(request: SimpleCourseRecommendRequest):
    user_lat = request.latitude
    user_lon = request.longitude
    target_perfumes = set(request.perfumes)

    matched_stores = []

    for store in store_data:
        store_perfumes = set(store.get("perfumes", []))
        if store_perfumes & target_perfumes:
            distance = haversine(user_lat, user_lon, store["latitude"], store["longitude"])
            matched_stores.append({
                "store": store["store"],
                "address": store["address"],
                "latitude": store["latitude"],
                "longitude": store["longitude"],
                "matched_perfumes": list(store_perfumes & target_perfumes),
                "distance_km": round(distance, 2)
            })

    if not matched_stores:
        raise HTTPException(status_code=404, detail="추천 향수를 판매하는 매장을 찾을 수 없습니다.")

    # 거리 순 정렬 후 상위 3곳만 반환
    matched_stores.sort(key=lambda x: x["distance_km"])
    course = matched_stores[:3]

    return JSONResponse(status_code=200, content={
        "status": 200,
        "message": "향수 코스 추천 성공",
        "result": course
    })
