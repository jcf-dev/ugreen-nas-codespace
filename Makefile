.PHONY: build config down logs pull shell up verify

build:
	docker compose -f docker-compose.yml -f compose/build.yml build --pull

config:
	docker compose config --quiet

down:
	docker compose down

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
