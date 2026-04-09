.PHONY: build run run-detach test runtime exec stop help

build: ## Build devel image
	./build.sh

run: ## Run container (interactive)
	./run.sh

run-detach: ## Run container in background
	./run.sh -d

test: ## Build and run smoke tests
	./build.sh test

runtime: ## Build runtime image
	./build.sh runtime

exec: ## Exec into running container (default: bash)
	./exec.sh

stop: ## Stop and remove containers
	./stop.sh

upgrade: ## Upgrade template subtree
	./template/script/upgrade.sh

upgrade-check: ## Check for template updates
	./template/script/upgrade.sh --check

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
