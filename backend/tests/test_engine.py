from app.inference.engine import ForwardChainingEngine


def test_specific_rule_wins_over_generic_budget_rule():
    engine = ForwardChainingEngine()
    rules = [
        {
            "id": "R1",
            "priority": 10,
            "conditions": [{"field": "budget", "operator": "eq", "value": "medium"}],
            "conclusions": {"max_price": 1600},
        },
        {
            "id": "R2",
            "priority": 55,
            "conditions": [
                {"field": "budget", "operator": "eq", "value": "medium"},
                {"field": "usage", "operator": "contains_any", "value": ["coding"]},
            ],
            "conclusions": {"preferred_category": "coding", "min_ram": 16},
        },
    ]

    result = engine.run({"budget": "medium", "usage": ["coding"]}, rules)

    assert result.facts["preferred_category"] == "coding"
    assert result.fired_rules[0].rule_id == "R2"


def test_higher_priority_wins_for_equal_specificity():
    engine = ForwardChainingEngine()
    rules = [
        {
            "id": "R1",
            "priority": 5,
            "conditions": [{"field": "budget", "operator": "eq", "value": "high"}],
            "conclusions": {"max_price": 3500},
        },
        {
            "id": "R2",
            "priority": 80,
            "conditions": [{"field": "budget", "operator": "eq", "value": "high"}],
            "conclusions": {"max_price": 4500},
        },
    ]

    result = engine.run({"budget": "high", "usage": ["gaming"]}, rules)

    assert result.facts["max_price"] == 4500
    assert result.fired_rules[0].rule_id == "R2"
