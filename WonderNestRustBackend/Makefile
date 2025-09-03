# WonderNest Rust Backend Makefile
# Provides convenient commands for development, testing, and deployment

.PHONY: help test test-all test-quick test-unit test-integration test-security test-coppa \
        test-live coverage docker-build docker-rebuild docker-quick docker-status docker-logs \
        docker-stop run dev clean install lint fmt check

# Default target
help:
	@echo "WonderNest Rust Backend - Available Commands"
	@echo "============================================"
	@echo ""
	@echo "Testing:"
	@echo "  make test          - Run all tests (comprehensive)"
	@echo "  make test-quick    - Run quick unit tests"
	@echo "  make test-unit     - Run unit tests only"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-security - Run security tests"
	@echo "  make test-coppa    - Run COPPA compliance tests"
	@echo "  make test-live     - Run live endpoint tests"
	@echo "  make coverage      - Generate test coverage report"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build  - Full Docker rebuild"
	@echo "  make docker-quick  - Quick Docker rebuild (cached)"
	@echo "  make docker-status - Check container status"
	@echo "  make docker-logs   - View container logs"
	@echo "  make docker-stop   - Stop all containers"
	@echo ""
	@echo "Development:"
	@echo "  make run           - Run the application locally"
	@echo "  make dev           - Run in development mode with auto-reload"
	@echo "  make build         - Build the application"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make install       - Install dependencies"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint          - Run linter (clippy)"
	@echo "  make fmt           - Format code"
	@echo "  make check         - Check code without building"

# Testing targets
test: test-all

test-all:
	@echo "🧪 Running comprehensive test suite..."
	@./scripts/run_all_tests.sh

test-quick:
	@echo "⚡ Running quick tests..."
	@./scripts/test_quick.sh

test-unit:
	@echo "🧮 Running unit tests..."
	@cargo test --lib -- --quiet

test-integration:
	@echo "🔗 Running integration tests..."
	@cargo test --test '*' -- --quiet

test-security:
	@echo "🔒 Running security tests..."
	@cargo test security -- --nocapture

test-coppa:
	@echo "👶 Running COPPA compliance tests..."
	@cargo test coppa -- --nocapture

test-live:
	@echo "🔐 Running live endpoint tests..."
	@./scripts/test-auth-rust.sh

coverage:
	@echo "📊 Generating test coverage..."
	@cargo tarpaulin --out Html --output-dir coverage
	@echo "Coverage report generated at: coverage/index.html"

# Docker targets
docker-build: docker-rebuild

docker-rebuild:
	@echo "🐳 Rebuilding Docker containers..."
	@./scripts/rebuild-docker.sh

docker-quick:
	@echo "⚡ Quick Docker rebuild..."
	@./scripts/quick-rebuild.sh

docker-status:
	@echo "📊 Docker container status..."
	@./scripts/docker-status.sh

docker-logs:
	@echo "📝 Docker container logs..."
	@./scripts/docker-logs.sh

docker-stop:
	@echo "🛑 Stopping Docker containers..."
	@docker stop wondernest-rust-backend 2>/dev/null || true
	@docker-compose down

# Development targets
run:
	@echo "🚀 Starting WonderNest backend..."
	@cargo run

dev:
	@echo "🔄 Starting in development mode..."
	@cargo watch -x run

build:
	@echo "🔨 Building application..."
	@cargo build --release

clean:
	@echo "🧹 Cleaning build artifacts..."
	@cargo clean
	@rm -rf coverage/
	@rm -rf target/

install:
	@echo "📦 Installing dependencies..."
	@cargo fetch
	@cargo build --tests

# Code quality targets
lint:
	@echo "🔍 Running clippy linter..."
	@cargo clippy -- -D warnings

fmt:
	@echo "✨ Formatting code..."
	@cargo fmt

check:
	@echo "✓ Checking code..."
	@cargo check

# Database targets
db-migrate:
	@echo "🔄 Running database migrations..."
	@sqlx migrate run

db-reset:
	@echo "♻️  Resetting database..."
	@sqlx database reset -y

# Benchmarks
bench:
	@echo "📈 Running benchmarks..."
	@cargo bench

# Watch mode for development
watch:
	@echo "👁️  Starting watch mode..."
	@cargo watch -x test -x run

# Combined commands
ci: lint check test

all: clean install lint test build

# Install development tools
install-tools:
	@echo "🔧 Installing development tools..."
	@cargo install cargo-watch
	@cargo install cargo-tarpaulin
	@cargo install sqlx-cli
	@cargo install cargo-edit
	@cargo install cargo-expand

.DEFAULT_GOAL := help