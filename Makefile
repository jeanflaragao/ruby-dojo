# Makefile for ruby-event-dojo
# WHY Makefile? Standardizes commands across the team

.PHONY: help build shell test demo demo-collections demo-repository coverage lint format clean

# Default target
help:
	@echo "Available commands:"
	@echo "  make build             - Build Docker image"
	@echo "  make shell             - Start interactive shell in container"
	@echo "  make test              - Run RSpec tests"
	@echo "  make demo              - Run Day 1 demonstration"
	@echo "  make demo-collections  - Run Day 2 collections tutorial"
	@echo "  make demo-repository   - Run Day 2 repository demo"
	@echo "  make coverage          - Open coverage report"
	@echo "  make lint              - Run Rubocop linter"
	@echo "  make format            - Auto-fix Rubocop issues"
	@echo "  make clean             - Remove coverage and temp files"

# Build Docker image
build:
	docker compose build

# Start interactive shell
shell:
	docker compose run --rm app /bin/bash

# Run tests
test:
	docker compose run --rm app bundle exec rspec

# Run demonstration
demo:
	docker compose run --rm app ruby demo/demo.rb

# Run Day 2 collections tutorial
demo-collections:
	docker compose run --rm app ruby lib/collections_tutorial.rb

# Run Day 2 repository demo
demo-repository:
	docker compose run --rm app ruby demo/repository_demo.rb

# Run Day 3 modules tutorial
demo-modules:
	docker compose run --rm app ruby lib/modules_tutorial.rb
 
# Run Day 3 method lookup demo
demo-method-lookup:
	docker compose run --rm app ruby demo/method_lookup_demo.rb

# Run Day 4 error handling tutorial
demo-errors:
	docker compose run --rm app ruby tutorial/error_handling.rb
 
# Run Day 4 booking service demo
demo-booking:
	docker compose run --rm app ruby demo/day_4.rb

# Open coverage report (requires running tests first)
coverage:
	@echo "Opening coverage report..."
	@open coverage/index.html || xdg-open coverage/index.html

# Run linter
lint:
	docker compose run --rm app bundle exec rubocop

# Auto-fix linter issues
format:
	docker compose run --rm app bundle exec rubocop -A

# Clean generated files
clean:
	rm -rf coverage/
	rm -f spec/examples.txt