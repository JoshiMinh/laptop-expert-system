from __future__ import annotations

from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..inference.engine import ForwardChainingEngine
from ..inference.reasoning import RuleCondition, RuleDefinition
from ..models import Laptop, Rule
from ..schemas import LaptopRead, LaptopRecommendation, RecommendRequest, RecommendationResponse


class LaptopRecommender:
    BUDGET_LIMITS = {"low": 800, "medium": 1600, "high": 4000}

    def __init__(self) -> None:
        self.engine = ForwardChainingEngine()

    def get_all_laptops(self, session: Session) -> list[LaptopRead]:
        rows = session.scalars(select(Laptop).order_by(Laptop.price.asc(), Laptop.id.asc())).all()
        return [LaptopRead.model_validate(row) for row in rows]

    def recommend(self, session: Session, request: RecommendRequest) -> RecommendationResponse:
        rules = self._load_rules(session)
        initial_facts: dict[str, Any] = {
            "budget": request.budget,
            "usage": request.usage,
        }
        if request.brand:
            initial_facts["brand"] = request.brand.strip().lower()
        if request.min_battery_hours is not None:
            initial_facts["min_battery_hours"] = request.min_battery_hours

        inference_result = self.engine.run(initial_facts, rules)
        candidates = session.scalars(select(Laptop)).all()
        ranked = self._rank_laptops(candidates, inference_result.facts, request)
        explanation = self._build_explanation(inference_result.fired_rules, ranked)
        return RecommendationResponse(recommendations=ranked, explanation=explanation)

    def _load_rules(self, session: Session) -> list[RuleDefinition]:
        rows = session.scalars(select(Rule).order_by(Rule.priority.desc(), Rule.id.asc())).all()
        rules: list[RuleDefinition] = []
        for row in rows:
            rules.append(
                RuleDefinition(
                    id=row.id,
                    priority=row.priority,
                    conditions=[RuleCondition(**condition) for condition in row.conditions],
                    conclusions=dict(row.conclusions),
                )
            )
        return rules

    def _rank_laptops(
        self,
        laptops: list[Laptop],
        facts: dict[str, Any],
        request: RecommendRequest,
    ) -> list[LaptopRecommendation]:
        max_price = min(self.BUDGET_LIMITS[request.budget], int(facts.get("max_price", self.BUDGET_LIMITS[request.budget])))
        preferred_category = facts.get("preferred_category")
        min_ram = int(facts.get("min_ram", 8))
        need_gpu = bool(facts.get("need_gpu", False))
        max_weight_kg = facts.get("max_weight_kg")
        brand_filter = request.brand.strip().lower() if request.brand else None
        min_battery_hours = request.min_battery_hours if request.min_battery_hours is not None else None

        ranked: list[LaptopRecommendation] = []
        for laptop in laptops:
            if brand_filter and laptop.brand.lower() != brand_filter:
                continue
            if min_battery_hours is not None and (laptop.battery_hours or 0) < min_battery_hours:
                continue

            score = 50.0
            reasons: list[str] = []

            if preferred_category and laptop.category == preferred_category:
                score += 30
                reasons.append(f"Matches the recommended {preferred_category} category")

            if laptop.ram >= min_ram:
                score += 20
                reasons.append(f"Provides {laptop.ram}GB RAM, meeting the minimum {min_ram}GB")
            else:
                score -= float((min_ram - laptop.ram) * 3)
                reasons.append(f"Has less RAM than requested ({laptop.ram}GB vs {min_ram}GB)")

            gpu_is_strong_enough = laptop.has_dedicated_gpu or "rtx" in laptop.gpu.lower() or "radeon" in laptop.gpu.lower()
            if need_gpu and gpu_is_strong_enough:
                score += 15
                reasons.append("Includes a dedicated GPU suitable for the workload")
            elif need_gpu:
                score -= 25
                reasons.append("Does not satisfy the GPU requirement")

            if laptop.price <= max_price:
                price_gap = max_price - laptop.price
                score += max(0.0, 10.0 - (price_gap / max_price) * 10.0)
                reasons.append(f"Stays within budget at ${laptop.price}")
            else:
                score -= ((laptop.price - max_price) / max_price) * 20.0
                reasons.append(f"Exceeds the target budget ceiling of ${max_price}")

            if max_weight_kg is not None and laptop.weight_kg is not None:
                if laptop.weight_kg <= max_weight_kg:
                    score += 8
                    reasons.append(f"Meets the portability target at {laptop.weight_kg:.2f}kg")
                else:
                    score -= (laptop.weight_kg - max_weight_kg) * 4

            if request.budget == "low" and laptop.price <= 700:
                score += 5
            if request.budget == "medium" and laptop.price <= 1400:
                score += 3
            if request.budget == "high" and laptop.price >= 1800:
                score += 3

            ranked.append(
                LaptopRecommendation(
                    **LaptopRead.model_validate(laptop).model_dump(),
                    score=round(score, 2),
                    fit_reasons=reasons,
                )
            )

        ranked.sort(key=lambda item: (-item.score, item.price, item.id))
        return ranked[:3]

    def _build_explanation(self, fired_rules: list[Any], ranked: list[LaptopRecommendation]) -> list[str]:
        explanation: list[str] = []

        for fired_rule in fired_rules:
            conditions = " AND ".join(
                self._describe_condition(condition) for condition in fired_rule.conditions
            )
            if fired_rule.applied_conclusions:
                conclusions = ", ".join(f"{key}={value}" for key, value in fired_rule.applied_conclusions.items())
                explanation.append(f"Rule {fired_rule.rule_id} fired because {conditions}; it set {conclusions}.")
            else:
                explanation.append(f"Rule {fired_rule.rule_id} matched because {conditions}; its conclusions were already satisfied.")

        for recommendation in ranked:
            reasons = "; ".join(recommendation.fit_reasons[:3])
            explanation.append(
                f"Selected {recommendation.name} with score {recommendation.score} because {reasons}."
            )

        if not explanation:
            explanation.append("No rules fired; recommendations were generated from the laptop inventory alone.")

        return explanation

    def _describe_condition(self, condition: RuleCondition) -> str:
        if condition.operator in {"contains_any", "contains_all"}:
            values = ", ".join(str(value) for value in condition.value)
            operator = "contains any of" if condition.operator == "contains_any" else "contains all of"
            return f"{condition.field} {operator} ({values})"
        return f"{condition.field} {condition.operator} {condition.value}"
