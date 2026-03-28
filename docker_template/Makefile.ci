.PHONY: test lint coverage init upgrade upgrade-check migrate migrate-list migrate-dry-run clean help

# ── Development ──────────────────────────────────────────────────────────────

test: ## Run full CI (ShellCheck + Bats + Kcov) via docker compose
	./script/ci.sh

lint: ## Run ShellCheck only
	./script/ci.sh --lint-only

coverage: ## Run tests with Kcov coverage
	./script/ci.sh --coverage

clean: ## Remove coverage reports
	rm -rf coverage/

# ── Consumer repo setup ─────────────────────────────────────────────────────

init: ## Initialize symlinks for consumer repo (first-time setup)
	./script/init.sh

upgrade: ## Upgrade docker_template subtree to latest version
	./script/upgrade.sh

upgrade-check: ## Check if a newer docker_template version is available
	./script/upgrade.sh --check

# ── Batch management (template repo only) ────────────────────────────────────

migrate: ## Migrate all repos from docker_setup_helper to docker_template
	./script/migrate.sh --all

migrate-list: ## List repos and their migration status
	./script/migrate.sh --list

migrate-dry-run: ## Dry-run migration for all repos
	./script/migrate.sh --dry-run --all

# ── Help ─────────────────────────────────────────────────────────────────────

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
