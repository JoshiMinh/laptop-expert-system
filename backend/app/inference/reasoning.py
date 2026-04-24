from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(slots=True)
class RuleCondition:
    field: str
    operator: str
    value: Any


@dataclass(slots=True)
class RuleDefinition:
    id: str
    conditions: list[RuleCondition]
    conclusions: dict[str, Any]
    priority: int

    @property
    def specificity(self) -> int:
        return len(self.conditions)


@dataclass(slots=True)
class FiredRule:
    rule_id: str
    specificity: int
    priority: int
    conditions: list[RuleCondition]
    conclusions: dict[str, Any]
    applied_conclusions: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class InferenceResult:
    facts: dict[str, Any]
    fired_rules: list[FiredRule]
