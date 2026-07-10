import os
os.environ["DATABASE_URL"] = "sqlite:///./test.db"

import pytest
from fastapi.testclient import TestClient
from main import app


@pytest.fixture(scope="module")
def client():
    # Using TestClient as a context manager triggers FastAPI's lifespan
    # (startup/shutdown) events, so Base.metadata.create_all() actually runs.
    with TestClient(app) as c:
        yield c


def test_root(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "running"


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "healthy"}


def test_predict_flow(client):
    r = client.post("/predict", json={"input_text": "hello"})
    assert r.status_code == 200
    body = r.json()
    assert body["result"] == "processed:olleh"

    r2 = client.get(f"/predict/{body['id']}")
    assert r2.status_code == 200
