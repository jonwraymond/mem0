#!/bin/bash

# OpenMemory One-Click Installer
# This script downloads and sets up the complete OpenMemory stack

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Check if we're already in the project directory
if [ -f "setup-openmemory.sh" ] && [ -f "docker-compose.yml" ]; then
    log "Already in OpenMemory project directory"
    
    # Make sure setup script is executable
    chmod +x setup-openmemory.sh
    
    # Run the setup
    log "Running OpenMemory setup..."
    ./setup-openmemory.sh
else
    error "This script should be run from the OpenMemory project directory"
fi
