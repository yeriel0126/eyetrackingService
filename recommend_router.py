from fastapi import APIRouter, HTTPException
from perfume_backend.schemas.recommend import RecommendRequest
from perfume_backend.schemas.base import BaseResponse
import json
import os

router = APIRouter(prefix="/perfumes", tags=["Recommendation"])

# JSON 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(BASE_DIR, "../data/perfume_data.json")

@router.post("/recommend", response_model=BaseResponse, summary="향수 추천", description="성별, 감정, 계절, 시간에 따라 향수를 추천합니다.")
async def recommend_perfume(req: RecommendRequest):
    with open(data_path, "r", encoding="utf-8") as f:
        perfumes = json.load(f)

    matched = [
        p for p in perfumes
        if req.gender == p.get("gender")
        and req.emotion == p.get("emotion")
        and req.season == p.get("season")
        and req.time == p.get("time")
    ]

    if not matched:
        raise HTTPException(status_code=404, detail="추천 가능한 향수가 없습니다.")

    result = [
        {
            "id": p["id"],
            "name": p["name"],
            "brand": p["brand"],
            "image_url": p.get("image_url", "")
        }
        for p in matched
    ]

    return BaseResponse(
        code=200,
        message="향수 추천 결과입니다.",
        data={"recommended_perfumes": result}
    )
