# OpenMemory MCP Server

A complete memory management system with MCP (Model Context Protocol) integration for AI applications.

## 🎯 Features

- **MCP Server Integration**: Full MCP protocol support with prefixed tool names
- **Vector Memory Storage**: Qdrant-powered semantic memory search
- **REST API**: Complete HTTP API for memory operations
- **Docker Stack**: Containerized deployment with health monitoring
- **Auto-categorization**: AI-powered memory categorization
- **Web UI**: Optional web interface for memory management
- **Conflict Resolution**: Prefixed MCP tools (`openmemory_*`) avoid naming conflicts

## 🚀 One-Click Installation

### ⚡ Super Quick Start (Recommended)

```bash
# One command to rule them all!
./install.sh
```

**That's it!** The script will:
- ✅ Check all prerequisites (Docker, etc.)
- ✅ Prompt for your OpenAI API key
- ✅ Set up the complete stack automatically
- ✅ Test all functionality
- ✅ Show you the status and next steps

### 🔧 Alternative: Direct Setup

```bash
# Run the setup script directly
./setup-openmemory.sh
```

### 📋 Manual Setup (if needed)

1. **Prerequisites**
   ```bash
   # Install Docker Desktop
   # Install Docker Compose
   # Install curl and jq (optional)
   ```

2. **Environment Setup**
   ```bash
   # Create .env file
   cat > .env << EOF
   OPENAI_API_KEY=your_openai_api_key_here
   OPENAI_OR_KEY=your_openai_api_key_here
   OPENAI_EMBED_KEY=your_openai_api_key_here
   USER=your_username
   EOF
   ```

3. **Start the Stack**
   ```bash
   docker-compose up -d --build
   ```

## 🛠️ MCP Tools

The OpenMemory MCP server provides these tools with `openmemory_` prefix to avoid conflicts:

### `openmemory_add_memories`
Add new memories to the system.

```python
# Example usage
result = await call_mcp_tool("openmemory_add_memories", {
    "text": "I prefer working in quiet coffee shops for coding"
})
```

### `openmemory_search_memory`
Search through stored memories using semantic similarity.

```python
# Example usage
memories = await call_mcp_tool("openmemory_search_memory", {
    "query": "work preferences"
})
```

### `openmemory_list_memories`
List all stored memories with metadata.

```python
# Example usage
all_memories = await call_mcp_tool("openmemory_list_memories", {})
```

### `openmemory_delete_all_memories`
Delete all memories (with permissions).

```python
# Example usage
result = await call_mcp_tool("openmemory_delete_all_memories", {})
```

## 📊 API Endpoints

### Memory Operations
- `POST /api/v1/memories/` - Add new memory
- `POST /api/v1/memories/filter` - Search/filter memories
- `GET /api/v1/memories/{id}` - Get specific memory
- `DELETE /api/v1/memories/{id}` - Delete memory

### MCP Protocol
- `GET /mcp/{client_name}/sse/{user_id}` - SSE connection for MCP
- `POST /mcp/messages/` - MCP message endpoint

### Health & Status
- `GET /health` - Health check
- `GET /docs` - API documentation

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │────│ OpenMemory MCP  │────│   Qdrant DB     │
│  (Warp/Agent)   │    │     Server      │    │ (Vector Store)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                         ┌─────────────────┐
                         │   SQLite DB     │
                         │  (Metadata)     │
                         └─────────────────┘
```

## 🧪 Testing

### Test MCP Tools
```bash
# Test via curl
curl -X POST "http://localhost:8766/mcp/test/sse/jraymond/messages/" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "openmemory_add_memories",
      "arguments": {"text": "Test memory"}
    },
    "id": 1
  }'
```

### Test REST API
```bash
# Add memory
curl -X POST "http://localhost:8766/api/v1/memories/" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test memory", "user_id": "jraymond"}'

# Search memories  
curl -X POST "http://localhost:8766/api/v1/memories/filter" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "jraymond", "search_query": "test"}'
```

**Quick Links:**
- 🌐 **API Docs**: http://localhost:8766/docs
- 🔍 **Vector DB**: http://localhost:6334
- 🖥️ **Web UI**: http://localhost:3000
- ❤️ **Health**: http://localhost:8766/health

---

## 🧩 Project Structure

This repository contains the complete Mem0 ecosystem with enhanced OpenMemory capabilities:

- **`/api/`** - Enhanced OpenMemory backend with MCP server integration
- **`/ui/`** - Next.js frontend for memory management
- **`/mem0/`** - Core Mem0 library
- **`/docs/`** - Documentation
- **`/examples/`** - Usage examples
- **`/embedchain/`** - EmbedChain integration
- **Root level** - Enhanced OpenMemory deployment with one-click installation

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📄 License

See [LICENSE](LICENSE) for license information.
