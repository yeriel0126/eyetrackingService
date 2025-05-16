from fastapi import APIRouter, Query, HTTPException
from perfume_backend.schemas.base import BaseResponse
import json, os

router = APIRouter(prefix="/stores", tags=["Store"])

# JSON 파일 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
store_path = os.path.join(BASE_DIR, "../data/store_data.json")

with open(store_path, "r", encoding="utf-8") as f:
    store_data = json.load(f)

# 전체 매장 조회 (선택적으로 브랜드 필터링)
@router.get(
    "/",
    response_model=BaseResponse,
    summary="전체 매장 목록 조회",
    description="모든 매장의 정보를 조회하며, brand 파라미터를 통해 특정 브랜드 매장만 필터링할 수 있습니다.",
    response_description="매장 리스트 반환"
)
async def get_all_stores(brand: str = Query(None, description="선택적으로 브랜드 이름으로 필터링")):
    if brand:
        filtered = [s for s in store_data if s.get("brand") == brand]
    else:
        filtered = store_data

    return BaseResponse(
        code=200,
        message="매장 목록 조회 성공",
        data={"stores": filtered}
    )

# 특정 브랜드 매장 조회
@router.get(
    "/{brand}",
    response_model=BaseResponse,
    summary="브랜드별 매장 목록 조회",
    description="특정 브랜드 이름에 해당하는 매장 정보를 반환합니다.",
    response_description="브랜드 매장 리스트 반환"
)
async def get_stores_by_brand(brand: str):
    result = [s for s in store_data if s.get("brand") == brand]

    if not result:
        raise HTTPException(status_code=404, detail="해당 브랜드의 매장을 찾을 수 없습니다.")

    return BaseResponse(
        code=200,
        message=f"{brand} 브랜드의 매장 목록입니다.",
        data={"stores": result}
    )
