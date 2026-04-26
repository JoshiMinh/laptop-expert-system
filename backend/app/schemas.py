from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


BudgetLevel = Literal["low", "medium", "high"]


class RecommendRequest(BaseModel):
    budget: BudgetLevel
    usage: list[str] = Field(min_length=1)
    brands: list[str] | None = None
    min_battery_hours: int | None = Field(default=None, ge=0)


class LaptopRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    brand: str
    price: int
    cpu: str
    ram: int
    gpu: str
    category: str
    weight_kg: float | None = None
    battery_hours: float | None = None
    has_dedicated_gpu: bool

class LaptopRecommendation(LaptopRead):
    score: float
    fit_reasons: list[str]


class RecommendationResponse(BaseModel):
    recommendations: list[LaptopRecommendation]
    explanation: list[str]


class ConditionModel(BaseModel):
    field: str
    operator: str
    value: Any


class RuleModel(BaseModel):
    id: str
    conditions: list[ConditionModel]
    conclusions: dict[str, Any]
    priority: int
