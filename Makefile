.PHONY: build build-slim config down hash-password logs pull shell up verify verify-slim

build:
	docker compose -f docker-compose.yml -f compose/build.yml build --pull

build-slim:
	IMAGE_VARIANT=slim docker compose -f docker-compose.yml -f compose/build.yml build --pull

config:
	docker compose config --quiet

down:
	docker compose down

hash-password:
	./scripts/generate-hashed-password.sh

logs:
	docker compose logs --follow codespace

pull:
	docker compose pull

shell:
	docker compose exec codespace bash

up:
	docker compose -f docker-compose.yml -f compose/build.yml up -d --build

verify:
	docker compose exec codespace bash -lc 'code-server --version && nvm --version && node --version && npm --version && pnpm --version && yarn --version && tsc --version && python3 --version && pipx --version && uv --version && git --version && gh --version | head -n1 && docker --version && docker buildx version && docker compose version && claude --version && codex --version && opencode --version'

verify-slim:
	docker compose exec codespace bash -lc 'code-server --version && nvm --version && node --version && npm --version && pnpm --version && yarn --version && tsc --version && python3 --version && pipx --version && git --version && gh --version | head -n1 && test -x /usr/local/bin/install-ai-tools'
