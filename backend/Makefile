.PHONY: test lint frontend-build build run worker

test:
	python3 -m pytest -q

lint:
	npm run lint
	uv run --locked --extra dev ruff check app tests scripts

frontend-build:
	npm run build

build: frontend-build
	uv build --wheel

run: frontend-build
	uv run python scripts/run_local.py

worker:
	uv run python scripts/run_local.py python -m app.worker
