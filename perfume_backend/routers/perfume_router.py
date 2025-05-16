from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse
from perfume_backend.schemas.perfume import PerfumeDetail
from perfume_backend.schemas.review import Review
from perfume_backend.schemas.base import BaseResponse
from enum import Enum
import json
import os

router = APIRouter(prefix="/perfumes", tags=["Perfume"])

# JSON 파일 경로
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(BASE_DIR, "../data/perfume_data.json")

# 정렬 기준 옵션
class PerfumeSortOptions(str, Enum):
    name = "name"
    brand = "brand"
    id = "id"

# 정렬 방향 옵션
class SortOrder(str, Enum):
    asc = "asc"
    desc = "desc"

# 향수 전체 조회
@router.get("/", response_model=BaseResponse, summary="향수 전체 목록 조회", description="전체 향수 목록을 조회합니다. 정렬 기준과 방향을 선택할 수 있습니다.")
async def get_all_perfumes(
    sort: PerfumeSortOptions = Query(PerfumeSortOptions.id, description="정렬 기준"),
    order: SortOrder = Query(SortOrder.asc, description="정렬 방향")
):
    with open(data_path, "r", encoding="utf-8") as f:
        perfumes = json.load(f)

    reverse = order == SortOrder.desc
    try:
        sorted_perfumes = sorted(perfumes, key=lambda x: x[sort.value], reverse=reverse)
    except KeyError:
        raise HTTPException(status_code=400, detail="정렬 키가 잘못되었습니다.")

    return BaseResponse(
        code=200,
        message="향수 목록을 정렬하여 반환합니다.",
        data={"perfumes": sorted_perfumes}
    )

# 향수 상세 조회
@router.get("/{perfume_id}", response_model=BaseResponse, summary="향수 상세 정보 조회", description="향수 ID를 기반으로 상세 정보를 반환합니다.")
async def get_perfume_detail(perfume_id: int):
    with open(data_path, "r", encoding="utf-8") as f:
        perfumes = json.load(f)

    for perfume in perfumes:
        if perfume["id"] == perfume_id:
            return BaseResponse(
                code=200,
                message="향수 상세 정보를 반환합니다.",
                data={"perfume": perfume}
            )

    raise HTTPException(status_code=404, detail="향수를 찾을 수 없습니다.")

# 리뷰 저장소 (임시)
review_store = {}

# 리뷰 등록
@router.post("/{perfume_id}/reviews", response_model=BaseResponse, summary="향수 리뷰 등록", description="해당 향수에 대한 리뷰를 등록합니다.")
async def post_review(perfume_id: int, review: Review):
    if perfume_id not in review_store:
        review_store[perfume_id] = []
    review_store[perfume_id].append(review)

    return BaseResponse(
        code=200,
        message="리뷰가 등록되었습니다.",
        data=None
    )

# 리뷰 조회
@router.get("/{perfume_id}/reviews", response_model=BaseResponse, summary="향수 리뷰 조회", description="해당 향수의 리뷰 목록을 반환합니다.")
async def get_reviews(perfume_id: int):
    reviews = review_store.get(perfume_id, [])
    return BaseResponse(
        code=200,
        message="해당 향수의 리뷰 목록을 반환합니다.",
        data={"reviews": reviews}
    )
