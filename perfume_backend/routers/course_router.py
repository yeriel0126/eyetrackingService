from fastapi import APIRouter
from fastapi.responses import JSONResponse
from perfume_backend.schemas.course import SimpleCourseRecommendRequest, CourseItem
import json, math, os

router = APIRouter(prefix="/courses", tags=["Course"])

# JSON 파일 경로
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
    R = 6371  # km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# 필드 매칭 함수 (str 또는 list 모두 지원)
def is_match(field, value):
    if isinstance(field, list):
        return value in field
    return value == field

@router.post("/recommend", summary="향수 코스 추천", description="사용자 선호와 매장 위치 기반으로 향수 추천 코스를 제공합니다.")
async def recommend_course(request: SimpleCourseRecommendRequest):
    try:
        # 필터링 (각 필드 타입이 문자열 또는 리스트일 경우 모두 대응)
        filtered_perfumes = [
            p for p in perfume_data
            if is_match(p.get("gender"), request.gender)
            and is_match(p.get("emotion_tags", p.get("emotion")), request.emotion)
            and is_match(p.get("season_tags", p.get("season")), request.season)
            and is_match(p.get("time_tags", p.get("time")), request.time)
        ]

        # 매장과 가까운 순서로 추천 코스 생성 (perfume name 기준 매칭)
        course_list = []
        for perfume in filtered_perfumes:
            perfume_name = perfume.get("name", "")
            matching_stores = [s for s in store_data if perfume_name in s.get("perfumes", [])]

            for store in matching_stores:
                distance = haversine(
                    request.latitude, request.longitude,
                    store.get("lat", 0.0), store.get("lng", 0.0)
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
            content={"message": "향수 코스 추천 성공", "data": sorted_course},
            status_code=200
        )

    except Exception as e:
        return JSONResponse(
            content={"message": f"향수 코스 추천 실패: {str(e)}"},
            status_code=500
        )
