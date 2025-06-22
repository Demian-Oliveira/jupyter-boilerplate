SERVICE ?= jupyter_service
PORT ?= 8085

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
	@$(open_jupyter)

# === CROSS-PLATFORM URL OPENER ===

define open_jupyter
	echo "[OPEN] Resolving port for service '$(SERVICE)'..."; \
	MAPPED_PORT=$$(docker compose port $(SERVICE) $(PORT) 2>/dev/null | cut -d: -f2); \
	if [ -z "$$MAPPED_PORT" ]; then \
		echo "[OPEN][ERROR] Service '$(SERVICE)' is not running or port $$PORT is not exposed."; \
		echo "[OPEN][ERROR] Port not mapped."; exit 1; \
	fi; \
	echo "[ OK ] Mapped to localhost:$$MAPPED_PORT"; \
	echo "[OPEN] Checking logs for access token..."; \
	TOKEN=$$(docker compose logs $(SERVICE) 2>&1 | grep -oE 'token=[a-z0-9]+' | tail -n1); \
	if [ -z "$$TOKEN" ]; then \
		echo "[WARN] No token found. Falling back to base URL."; \
		URL="http://localhost:$$MAPPED_PORT"; \
	else \
		echo "[ OK ] Token located"; \
		URL="http://localhost:$$MAPPED_PORT/?$$TOKEN"; \
	fi; \
	echo "[ACTION] Opening $$URL"; \
	sleep 1;  \
	$(call open_url,$$URL)
endef

define open_url
	if command -v xdg-open >/dev/null 2>&1; then \
		echo "[BROWSER] Launching via: xdg-open (Linux)"; \
		xdg-open "$1"; \
	elif command -v powershell.exe >/dev/null 2>&1; then \
		echo "[BROWSER] Launching via: PowerShell (Windows)"; \
		powershell.exe -NoProfile -Command "Start-Process '$1'"; \
	elif command -v rundll32.exe >/dev/null 2>&1; then \
		echo "[BROWSER] Launching via: rundll32 (Windows)"; \
		rundll32.exe url.dll,FileProtocolHandler "$1"; \
	else \
		echo "[FAIL] No browser launcher detected."; \
	fi
endef