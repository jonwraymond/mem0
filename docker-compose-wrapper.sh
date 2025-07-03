#!/bin/bash

# OpenMemory Docker Compose Wrapper Script
# This script sets up the required environment variables and calls docker compose

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required environment variables are set
check_env_vars() {
    local missing_vars=()
    
    if [[ -z "${OPENAI_OR_KEY}" ]]; then
        missing_vars+=("OPENAI_OR_KEY")
    fi
    
    if [[ -z "${OPENAI_EMBED_KEY}" ]]; then
        missing_vars+=("OPENAI_EMBED_KEY")
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo
        print_warning "Please set these environment variables before running the script:"
        for var in "${missing_vars[@]}"; do
            echo "  export $var=\"your_${var,,}_here\""
        done
        echo
        print_warning "Or create a .env file in the api directory with these variables."
        exit 1
    fi
}

# Function to set default environment variables
set_default_env_vars() {
    export USER="${USER:-$(whoami)}"
    export NEXT_PUBLIC_USER_ID="${USER}"
    export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://localhost:8765}"
}

# Function to display current environment
show_env() {
    print_status "Current environment variables:"
    echo "  USER: ${USER}"
    echo "  NEXT_PUBLIC_USER_ID: ${NEXT_PUBLIC_USER_ID}"
    echo "  NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL}"
    echo "  OPENAI_OR_KEY: ${OPENAI_OR_KEY:0:8}..." # Only show first 8 chars
    echo "  OPENAI_EMBED_KEY: ${OPENAI_EMBED_KEY:0:8}..." # Only show first 8 chars
    echo
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  up        Start the containers (default)"
    echo "  down      Stop the containers and remove volumes"
    echo "  stop      Stop the containers and remove volumes (alias for down)"
    echo "  logs      Show container logs"
    echo "  restart   Restart the containers"
    echo "  status    Show container status"
    echo "  env       Show current environment variables"
    echo "  help      Show this help message"
    echo
    echo "Environment Variables Required:"
    echo "  OPENAI_OR_KEY      - OpenAI API key for reasoning"
    echo "  OPENAI_EMBED_KEY   - OpenAI API key for embeddings"
    echo
    echo "Optional Environment Variables:"
    echo "  NEXT_PUBLIC_API_URL - API URL (default: http://localhost:8765)"
    echo "  USER               - User ID (default: current user)"
}

# Main script logic
main() {
    local command="${1:-up}"
    
    case "$command" in
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        "env")
            set_default_env_vars
            show_env
            exit 0
            ;;
        "up"|"start")
            print_status "Starting OpenMemory containers..."
            check_env_vars
            set_default_env_vars
            show_env
            docker compose up "$@"
            ;;
        "down"|"stop")
            print_status "Stopping OpenMemory containers..."
            docker compose down -v
            rm -f api/openmemory.db
            print_success "Containers stopped and volumes removed"
            ;;
        "logs")
            docker compose logs -f "${@:2}"
            ;;
        "restart")
            print_status "Restarting OpenMemory containers..."
            check_env_vars
            set_default_env_vars
            docker compose down -v
            rm -f api/openmemory.db
            docker compose up "${@:2}"
            ;;
        "status")
            docker compose ps
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Check if docker and docker compose are available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    exit 1
fi

# Run main function with all arguments
main "$@"
