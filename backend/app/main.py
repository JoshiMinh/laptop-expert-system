from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .database import get_db, init_db
from .schemas import LaptopRead, RecommendRequest, RecommendationResponse
from .services.recommender import LaptopRecommender


recommender = LaptopRecommender()


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title="Laptop Expert System", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/laptops", response_model=list[LaptopRead])
def get_laptops(session: Session = Depends(get_db)) -> list[LaptopRead]:
    return recommender.get_all_laptops(session)


@app.post("/recommend", response_model=RecommendationResponse)
def recommend(payload: RecommendRequest, session: Session = Depends(get_db)) -> RecommendationResponse:
    return recommender.recommend(session, payload)
