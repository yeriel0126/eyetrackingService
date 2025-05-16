from fastapi import APIRouter
from datetime import datetime
from perfume_backend.schemas.diary import DiaryEntry, DiaryCreateRequest
from perfume_backend.schemas.base import BaseResponse
import os, json

router = APIRouter(prefix="/diary", tags=["Diary"])

# JSON 저장 경로
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "../data/diary_data.json")

# 파일에서 일기 불러오기
def load_diaries() -> list[DiaryEntry]:
    if not os.path.exists(DATA_PATH):
        return []
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
        return [DiaryEntry(**d) for d in data]

# 파일에 일기 저장하기 (datetime → JSON 문자열 대응)
def save_diaries(entries: list[DiaryEntry]):
    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(
            [entry.model_dump(mode="json") for entry in entries],
            f, ensure_ascii=False, indent=2
        )

# ✅ 시향 일기 저장
@router.post("/", response_model=BaseResponse, summary="시향 일기 저장", description="향수를 시향한 후 일기를 작성해 저장합니다.")
async def save_diary(entry: DiaryCreateRequest):
    entries = load_diaries()
    new_entry = DiaryEntry(
        user_id=entry.user_id,
        perfume_name=entry.perfume_name,
        emotion=entry.emotion,
        memo=entry.memo,
        created_at=datetime.utcnow()
    )
    entries.append(new_entry)
    save_diaries(entries)
    return BaseResponse(
        code=200,
        message="시향 일기가 저장되었습니다.",
        data=None
    )

# ✅ 사용자별 시향 일기 조회
@router.get("/{user_id}", response_model=BaseResponse, summary="사용자별 시향 일기 조회", description="특정 사용자의 시향 일기를 조회합니다.")
async def get_user_diaries(user_id: str):
    entries = load_diaries()
    user_entries = [e for e in entries if e.user_id == user_id]
    return BaseResponse(
        code=200,
        message=f"{user_id}님의 시향 일기 목록입니다.",
        data={"entries": user_entries}
    )
