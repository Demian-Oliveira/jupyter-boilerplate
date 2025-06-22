SERVICE=jupyter_service

.PHONY: up down build fix shell prune

up:
	docker-compose up -d 


down:
	docker-compose down


shell:
	docker-compose exec jupyter_service bash

# Fix Windows-style line endings and permissions in scripts
fix:
	@echo "[FIX] Ensuring UNIX line endings and executable flag on scripts/docker-entrypoint.sh"
	@sed -i 's/\r$$//' scripts/docker-entrypoint.sh
	@chmod +x scripts/docker-entrypoint.sh

# Build the image (runs fix first)
build: fix
	docker compose build

# Force-remove all containers and images related to the service
prune:
	@echo "[PRUNE] Removing containers and images tagged with '$(SERVICE)'"
	@docker ps -a --filter "name=$(SERVICE)" -q | xargs -r docker rm -f
	@docker images --format "{{.Repository}} {{.ID}}" | grep $(SERVICE) | awk '{print $$2}' | xargs -r docker rmi -f

# Opens Jupyter in the browser using the mapped host port
open:
	@PORT=$$(docker compose port $(SERVICE) 8085 2>/dev/null | cut -d: -f2); \
	if [ -n "$$PORT" ]; then \
		URL=http://localhost:$$PORT; \
		echo "[OPEN] Opening $$URL"; \
		sleep 1; \
		# Linux \
		if command -v xdg-open >/dev/null 2>&1; then xdg-open $$URL; \
		# macOS \
		elif command -v open >/dev/null 2>&1; then open $$URL; \
		# Windows (Git Bash/WSL): explorer.exe opens browser but exits with code 1, so add '|| true' to ignore it. \
		else explorer.exe $$URL || true; fi \
	else \
		echo "[OPEN] Container not running or port not exposed."; \
		exit 1; \
	fi