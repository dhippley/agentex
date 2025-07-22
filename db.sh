#!/bin/bash

# Database management script for Agentex

set -e

# Use Docker Compose V2 (docker compose) instead of V1 (docker-compose)
DOCKER_COMPOSE="docker compose"

case "$1" in
  start)
    echo "Starting PostgreSQL with Docker Compose..."
    $DOCKER_COMPOSE up -d postgres
    echo "Waiting for database to be ready..."
    $DOCKER_COMPOSE exec postgres pg_isready -U postgres -d agentex_dev
    echo "PostgreSQL is ready!"
    ;;
  
  stop)
    echo "Stopping PostgreSQL..."
    $DOCKER_COMPOSE down
    ;;
  
  restart)
    echo "Restarting PostgreSQL..."
    $DOCKER_COMPOSE restart postgres
    ;;
  
  logs)
    echo "Showing PostgreSQL logs..."
    $DOCKER_COMPOSE logs -f postgres
    ;;
  
  shell)
    echo "Connecting to PostgreSQL shell..."
    $DOCKER_COMPOSE exec postgres psql -U postgres -d agentex_dev
    ;;
  
  setup)
    echo "Setting up database for the first time..."
    $DOCKER_COMPOSE up -d postgres
    echo "Waiting for database to be ready..."
    sleep 10
    $DOCKER_COMPOSE exec postgres pg_isready -U postgres -d agentex_dev || sleep 5
    echo "Creating database and running migrations..."
    mix ecto.create
    mix ecto.migrate
    echo "Database setup complete!"
    ;;
  
  reset)
    echo "Resetting database (WARNING: This will delete all data)..."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      $DOCKER_COMPOSE down
      docker volume rm agentex_postgres_data 2>/dev/null || true
      $DOCKER_COMPOSE up -d postgres
      echo "Waiting for database to be ready..."
      sleep 10
      mix ecto.create
      mix ecto.migrate
      echo "Database reset complete!"
    else
      echo "Cancelled."
    fi
    ;;
  
  migrate)
    echo "Running database migrations..."
    mix ecto.migrate
    ;;
  
  rollback)
    echo "Rolling back last migration..."
    mix ecto.rollback
    ;;
  
  status)
    echo "Database status:"
    $DOCKER_COMPOSE ps postgres
    ;;
  
  *)
    echo "Usage: $0 {start|stop|restart|logs|shell|setup|reset|migrate|rollback|status}"
    echo ""
    echo "Commands:"
    echo "  start    - Start PostgreSQL container"
    echo "  stop     - Stop PostgreSQL container"
    echo "  restart  - Restart PostgreSQL container"
    echo "  logs     - Show PostgreSQL logs"
    echo "  shell    - Connect to PostgreSQL shell"
    echo "  setup    - First-time database setup"
    echo "  reset    - Reset database (deletes all data)"
    echo "  migrate  - Run pending migrations"
    echo "  rollback - Rollback last migration"
    echo "  status   - Show container status"
    exit 1
    ;;
esac
