from fastapi import APIRouter
from fastapi.responses import JSONResponse
from perfume_backend.schemas.course import SimpleCourseRecommendRequest
from perfume_backend.schemas.base import BaseResponse
import json, math, os

router = APIRouter(prefix="/courses", tags=["Course"])

# JSON 파일 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
store_path = os.path.join(BASE_DIR, "../data/store_data.json")
perfume_path = os.path.join(BASE_DIR, "../data/perfume_data.json")

# JSON 데이터 로딩
with open(store_path, "r", encoding="utf-8") as f:
    store_data = json.load(f)

with open(perfume_path, "r", encoding="utf-8") as f:
    perfume_data = json.load(f)

# 거리 계산 함수 (Haversine 공식)
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # 단위: km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# 필드 비교 함수 (list 또는 string 모두 대응)
def is_match(field, value):
    if isinstance(field, list):
        return value in field
    return value == field

# 향수 코스 추천 API
@router.post(
    "/recommend",
    summary="향수 코스 추천",
    description="사용자의 성별, 감정, 계절, 시간 및 현재 위치를 기반으로 추천 향수와 가까운 매장을 반환합니다.",
    response_description="추천된 향수 및 매장 목록을 거리 순으로 정렬하여 반환합니다."
)
async def recommend_course(request: SimpleCourseRecommendRequest):
    try:
        filtered_perfumes = [
            p for p in perfume_data
            if is_match(p.get("gender"), request.gender)
            and is_match(p.get("emotion_tags", p.get("emotion")), request.emotion)
            and is_match(p.get("season_tags", p.get("season")), request.season)
            and is_match(p.get("time_tags", p.get("time")), request.time)
        ]

        course_list = []
        for perfume in filtered_perfumes:
            perfume_name = perfume.get("name", "")
            matching_stores = [s for s in store_data if perfume_name in s.get("perfumes", [])]

            for store in matching_stores:
                distance = haversine(
                    request.latitude,
                    request.longitude,
                    store.get("lat", 0.0),
                    store.get("lng", 0.0)
                )
                course_list.append({
                    "store": store.get("name", ""),
                    "address": store.get("address", ""),
                    "perfume_name": perfume.get("name", ""),
                    "brand": perfume.get("brand", ""),
                    "image_url": perfume.get("image_url", ""),
                    "distance_km": round(distance, 2)
                })

        sorted_course = sorted(course_list, key=lambda x: x["distance_km"])[:5]

        return JSONResponse(
            status_code=200,
            content={
                "message": "향수 코스 추천 성공",
                "data": sorted_course
            }
        )

    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "message": f"향수 코스 추천 실패: {str(e)}",
                "data": None
            }
        )
