#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 OpenMemory Stack Installation Script${NC}"
echo "======================================="
echo "This will set up:"
echo "  • Qdrant (Vector Database) on port 6333"
echo "  • Memgraph (Graph Database) on port 7687"
echo "  • OpenMemory MCP Server on port 8765/8766"
echo "  • OpenMemory UI on port 3000"
echo "  • Python environment with mem0"
echo ""

# Check if running from the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: docker-compose.yml not found. Please run this script from the mem0 project root.${NC}"
    exit 1
fi

# Check for required tools
echo -e "${YELLOW}📋 Checking requirements...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}❌ Docker Compose is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}❌ Python 3 is required but not installed. Aborting.${NC}" >&2; exit 1; }
echo "✅ All requirements met"

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: .env file not found. Please create a .env file with your OPENAI_API_KEY.${NC}"
    echo "Example: echo 'OPENAI_API_KEY=\"sk-proj-...\"' > .env"
    exit 1
fi

# Verify API key is set
if grep -q "your-openai-api-key-here" .env || ! grep -q "OPENAI_API_KEY" .env; then
    echo -e "${RED}❌ Please set your OPENAI_API_KEY in the .env file${NC}"
    exit 1
fi

# Copy .env to OpenMemory API directory
echo -e "\n${YELLOW}🔧 Setting up environment...${NC}"
cp .env openmemory/api/.env
echo "✅ Environment configured"

# Create data directories
echo -e "\n${YELLOW}📁 Creating data directories...${NC}"
mkdir -p data/qdrant
mkdir -p data/memgraph
mkdir -p openmemory/data
echo "✅ Data directories created"

# Create patches directory and patch file if needed
echo -e "\n${YELLOW}🩹 Creating patches...${NC}"
mkdir -p openmemory/api/patches
cat > openmemory/api/patches/memgraph_memory.patch << 'EOF'
--- memgraph_memory.py.orig	2025-01-02 20:00:00.000000000 -0700
+++ memgraph_memory.py	2025-01-02 20:00:01.000000000 -0700
@@ -246,7 +246,7 @@
         
         return all_results
 
-    def _delete_entities(self, to_be_deleted, user_id):
+    def _delete_entities(self, to_be_deleted, filters):
         """
         Delete entities from the graph.
         
@@ -276,7 +276,7 @@
         return deleted_entities
     
 
-    def _add_entities(self, to_be_added, user_id, entity_type_map):
+    def _add_entities(self, to_be_added, filters, entity_type_map):
         """
         Add entities to the graph with their relationships.
         
EOF
echo "✅ Patch file created"

# Apply patches
echo -e "\n${YELLOW}🔨 Applying patches...${NC}"
cd mem0/memory
if ! grep -q "def _delete_entities(self, to_be_deleted, filters)" memgraph_memory.py 2>/dev/null; then
    patch -p0 < ../../openmemory/api/patches/memgraph_memory.patch || echo "⚠️  Patch may have already been applied"
else
    echo "✅ Patch already applied"
fi
cd ../..

# Stop any existing containers
echo -e "\n${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose down 2>/dev/null || true

# Ask about data cleanup
read -p "Do you want to clean up existing data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🧹 Cleaning up old volumes...${NC}"
    docker volume rm mem0_qdrant_storage mem0_memgraph_data mem0_openmemory_data 2>/dev/null || true
    rm -rf data/qdrant/* data/memgraph/* 2>/dev/null || true
fi

# Start the stack
echo -e "\n${YELLOW}🚀 Starting OpenMemory stack...${NC}"
docker-compose up -d --build

# Wait for services to be ready
echo -e "\n${YELLOW}⏳ Waiting for services to start...${NC}"
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""

# Check service health
echo -e "\n${YELLOW}🏥 Checking service status...${NC}"
services=(
    "openmemory-qdrant:6333:Qdrant"
    "openmemory-memgraph:7687:Memgraph"
    "openmemory-mcp-server:8765:MCP Server"
    "openmemory-ui:3000:UI"
)

all_healthy=true
for service_info in "${services[@]}"; do
    IFS=':' read -r container port name <<< "$service_info"
    if docker ps | grep -q "$container"; then
        echo "✅ $name is running on port $port"
    else
        echo -e "${RED}❌ $name is not running${NC}"
        all_healthy=false
    fi
done

# Setup Python virtual environment
echo -e "\n${YELLOW}🐍 Setting up Python environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Created virtual environment"
fi

source venv/bin/activate
echo "✅ Activated virtual environment"

# Install Python dependencies
echo -e "\n${YELLOW}📦 Installing Python dependencies...${NC}"
pip install -q --upgrade pip
pip install -q -e .
pip install -q langchain-memgraph rank-bm25 python-dotenv
echo "✅ Python dependencies installed"

# Initialize Memgraph with correct vector index
echo -e "\n${YELLOW}🔗 Initializing Memgraph...${NC}"
sleep 5
docker exec openmemory-memgraph mgconsole --eval "CREATE VECTOR INDEX IF NOT EXISTS memzero ON :Entity(embedding) WITH CONFIG {dimension: 3072, capacity: 1000, metric: 'cos'};" 2>/dev/null || echo "⚠️  Vector index may already exist"

# Configure Claude Code MCP (if claude command exists)
if command -v claude >/dev/null 2>&1; then
    echo -e "\n${YELLOW}🤖 Configuring Claude Code MCP...${NC}"
    # Check if already configured
    if ! claude mcp list | grep -q "openmemory-local"; then
        claude mcp add openmemory-local -s user -t sse http://localhost:8766/mcp/claude/sse/jraymond
        echo "✅ Added OpenMemory MCP server to Claude Code"
    else
        echo "✅ OpenMemory MCP server already configured"
    fi
fi

# Create activation script
echo -e "\n${YELLOW}📝 Creating helper scripts...${NC}"
cat > activate.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
export PYTHONPATH="$PWD:$PYTHONPATH"
echo "✅ Virtual environment activated for mem0 project"
echo ""
echo "Quick commands:"
echo "  docker-compose up -d     # Start services"
echo "  docker-compose down      # Stop services"
echo "  docker-compose logs -f   # View logs"
echo "  docker-compose restart   # Restart all services"
EOF
chmod +x activate.sh

# Create test script
cat > test-openmemory.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing OpenMemory Stack..."
echo ""

# Test Qdrant
echo -n "Testing Qdrant... "
if curl -s http://localhost:6333/health > /dev/null; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test Memgraph
echo -n "Testing Memgraph... "
if docker exec openmemory-memgraph mgconsole --eval "MATCH (n) RETURN count(n);" > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test MCP Server
echo -n "Testing MCP Server... "
if curl -s http://localhost:8765/docs > /dev/null; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test UI
echo -n "Testing UI... "
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi
EOF
chmod +x test-openmemory.sh

# Display final status
echo -e "\n${GREEN}✨ Installation Complete!${NC}"
echo "========================"
echo ""
echo "📍 Service Endpoints:"
echo "  • OpenMemory UI: ${GREEN}http://localhost:3000${NC}"
echo "  • MCP Server: ${GREEN}http://localhost:8765${NC}"
echo "  • MCP SSE Endpoint: ${GREEN}http://localhost:8766/mcp/claude/sse/jraymond${NC}"
echo "  • Qdrant Dashboard: ${GREEN}http://localhost:6333/dashboard${NC}"
echo "  • Memgraph Lab: ${GREEN}http://localhost:3001${NC}"
echo "  • Memgraph: ${GREEN}bolt://localhost:7687${NC}"
echo ""
echo "🔧 Management Commands:"
echo "  ${YELLOW}source activate.sh${NC}       # Activate Python environment"
echo "  ${YELLOW}./test-openmemory.sh${NC}     # Test all services"
echo "  ${YELLOW}docker-compose logs -f${NC}   # View logs"
echo "  ${YELLOW}docker-compose restart${NC}   # Restart services"
echo "  ${YELLOW}docker-compose down${NC}      # Stop services"
echo ""

if command -v claude >/dev/null 2>&1; then
    echo "🤖 Claude Code MCP Integration:"
    echo "  Restart Claude Code to use MCP tools:"
    echo "  • add_memories"
    echo "  • search_memory"
    echo "  • list_memories"
    echo "  • delete_all_memories"
    echo ""
fi

if [ "$all_healthy" = true ]; then
    echo -e "${GREEN}✅ All services are running successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may need more time to start. Run ./test-openmemory.sh to check again.${NC}"
fi
echo ""