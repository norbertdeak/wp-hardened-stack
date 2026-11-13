SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[1m%-14s\033[0m %s\n", $$1, $$2}'

key: ## generate .env secrets (idempotent, never overwrites a filled value)
	@bash scripts/05-keygen.sh

gate: ## security version gate (fails closed on a vulnerable pin)
	@WRITE=$(WRITE) bash scripts/00-preflight.sh

up: gate ## build and start the stack
	docker compose up -d --build
	@echo "→ http://localhost:$${HTTP_PORT:-8080}"

down: ## stop the stack
	docker compose down

harden-wp: ## apply idempotent WordPress hardening
	@bash scripts/20-harden-wp.sh

backup: ## dump database + files into ./backups
	@bash scripts/backup.sh

health: ## end-to-end health checks
	@bash scripts/healthcheck.sh

test: ## static checks + unit tests
	python3 -m pytest -q tests/ || python3 -m unittest discover -s tests -v
	@bash -n scripts/*.sh && echo "shell syntax: ok"

lint: ## shellcheck + compose config
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || echo "shellcheck not installed"
	@docker compose config -q && echo "compose config: ok"

logs: ## tail all logs
	docker compose logs -f --tail=100

.PHONY: help key gate up down harden-wp backup health test lint logs
