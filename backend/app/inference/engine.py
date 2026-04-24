from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from .reasoning import FiredRule, InferenceResult, RuleCondition, RuleDefinition


def _coerce_rule(rule: RuleDefinition | dict[str, Any]) -> RuleDefinition:
    if isinstance(rule, RuleDefinition):
        return rule

    return RuleDefinition(
        id=rule["id"],
        conditions=[RuleCondition(**condition) for condition in rule["conditions"]],
        conclusions=dict(rule["conclusions"]),
        priority=int(rule["priority"]),
    )


class ForwardChainingEngine:
    def matches(self, rule: RuleDefinition, facts: dict[str, Any]) -> bool:
        for condition in rule.conditions:
            if not self._match_condition(condition, facts):
                return False
        return True

    def run(
        self,
        initial_facts: dict[str, Any],
        rules: Iterable[RuleDefinition | dict[str, Any]],
    ) -> InferenceResult:
        working_memory = dict(initial_facts)
        fact_strengths: dict[str, tuple[int, int, str]] = {
            key: (-1, -1, "input") for key in working_memory
        }
        rule_objects = [_coerce_rule(rule) for rule in rules]
        fired_rules: list[FiredRule] = []
        fired_rule_ids: set[str] = set()

        while True:
            applicable_rules = [
                rule for rule in rule_objects if rule.id not in fired_rule_ids and self.matches(rule, working_memory)
            ]
            if not applicable_rules:
                break

            selected_rule = sorted(
                applicable_rules,
                key=lambda rule: (-rule.specificity, -rule.priority, rule.id),
            )[0]
            fired_rule_ids.add(selected_rule.id)

            applied_conclusions: dict[str, Any] = {}
            for fact_key, value in selected_rule.conclusions.items():
                existing_value = working_memory.get(fact_key)
                candidate_strength = (selected_rule.specificity, selected_rule.priority, selected_rule.id)
                current_strength = fact_strengths.get(fact_key, (-1, -1, ""))
                if existing_value == value:
                    continue
                if candidate_strength >= current_strength:
                    working_memory[fact_key] = value
                    fact_strengths[fact_key] = candidate_strength
                    applied_conclusions[fact_key] = value

            fired_rules.append(
                FiredRule(
                    rule_id=selected_rule.id,
                    specificity=selected_rule.specificity,
                    priority=selected_rule.priority,
                    conditions=selected_rule.conditions,
                    conclusions=selected_rule.conclusions,
                    applied_conclusions=applied_conclusions,
                )
            )

        return InferenceResult(facts=working_memory, fired_rules=fired_rules)

    def _match_condition(self, condition: RuleCondition, facts: dict[str, Any]) -> bool:
        value = facts.get(condition.field)

        if condition.operator == "eq":
            return value == condition.value
        if condition.operator == "ne":
            return value != condition.value
        if condition.operator == "gte":
            return value is not None and value >= condition.value
        if condition.operator == "lte":
            return value is not None and value <= condition.value
        if condition.operator == "contains_any":
            if not isinstance(value, list):
                return False
            expected = set(condition.value if isinstance(condition.value, list) else [condition.value])
            return bool(expected.intersection(value))
        if condition.operator == "contains_all":
            if not isinstance(value, list):
                return False
            expected = set(condition.value if isinstance(condition.value, list) else [condition.value])
            return expected.issubset(set(value))
        if condition.operator == "in":
            return value in condition.value
        if condition.operator == "exists":
            return value is not None

        raise ValueError(f"Unsupported operator: {condition.operator}")
