from __future__ import annotations

import os
from pathlib import Path
from tempfile import gettempdir

import pytest
from fastapi.testclient import TestClient


TEST_DB_PATH = Path(gettempdir()) / "laptop_expert_system_test.sqlite3"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH.as_posix()}"

from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    with TestClient(app) as test_client:
        yield test_client


def test_get_laptops_returns_seeded_catalog(client: TestClient):
    response = client.get("/laptops")

    assert response.status_code == 200
    payload = response.json()
    assert isinstance(payload, list)
    assert len(payload) >= 10


def test_recommend_endpoint_returns_explanations(client: TestClient):
    response = client.post(
        "/recommend",
        json={"budget": "medium", "usage": ["coding", "portable"]},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["recommendations"]
    assert payload["explanation"]
    assert len(payload["recommendations"]) <= 3
