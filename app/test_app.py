import pytest

from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as test_client:
        yield test_client


def test_home_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Welcome to DevOps CI/CD Project" in response.data


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.is_json
    assert response.get_json() == {
        "status": "healthy",
        "application": "devops-project",
    }


def test_unknown_route_returns_404(client):
    assert client.get("/does-not-exist").status_code == 404
