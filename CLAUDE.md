# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Tool Usage Philosophy

**ALWAYS START WITH MEMORY RETRIEVAL** - Every task begins with searching both memory systems
**USE THE RIGHT TOOL FOR THE JOB** - Each tool has specific strengths, use them appropriately
**STORE KNOWLEDGE CONTINUOUSLY** - Add learnings to both memory systems throughout work
**THINK STRUCTURALLY** - Use Sequential Thinking for complex problems, ast-grep for code patterns

## 🧠 Dual Memory Management System

### OpenMemory-Local (Cross-Application Memory)
- **Purpose**: Persistent knowledge shared across Claude Desktop, Claude Code, and Warp Terminal
- **Strengths**: User preferences, debugging solutions, configurations, cross-session continuity
- **Usage**: `mcp__openmemory-local__search_memory`, `mcp__openmemory-local__add_memories`
- **Best for**: Solutions that apply across projects, user workflows, environment configurations

### Serena Project Memories (Semantic Code Memory)
- **Purpose**: Project-specific semantic understanding and architectural knowledge
- **Strengths**: Code structure, symbol relationships, design patterns, refactoring plans
- **Usage**: `mcp__serena__read_memory`, `mcp__serena__write_memory`, `mcp__serena__list_memories`
- **Best for**: Architecture decisions, code organization patterns, project-specific knowledge

## 🎯 Automatic Tool Selection Guidelines

### Use ast-grep When:
- **Pattern Recognition**: "Find all instances of...", "Update deprecated APIs", "Consistent code style"
- **Structural Transformations**: Mass refactoring, syntax-aware replacements
- **Code Modernization**: Updating patterns across multiple files
- **Example Triggers**: "refactor", "update all", "find pattern", "consistent style"

```bash
# Use ast-grep for structural code operations
ast-grep -p 'console.log($ARG)' -l typescript
ast-grep -p 'def $FUNC($$$ARGS):' --rewrite 'async def $FUNC($$$ARGS):' -l python
```

### Use Serena Tools When:
- **Code Understanding**: "How does X work?", "Find all usages of Y", "Understand architecture"
- **Symbol Navigation**: Finding definitions, references, inheritance chains
- **Safe Refactoring**: Symbol-level changes that preserve meaning
- **Example Triggers**: "find definition", "show references", "understand structure"

```python
# Use Serena for semantic code operations
find_symbol("ClassName", symbol_type="class")
find_referencing_symbols("file.py", line=42)
get_symbols_overview("src/")
```

### Use Task Agent When:
- **Open-ended Search**: Scope unclear, exploration needed
- **Multi-step Analysis**: Complex investigations requiring coordination
- **Cross-codebase Operations**: Operations spanning multiple tools/files
- **Example Triggers**: "analyze", "investigate", "find all related", "understand codebase"

### Use Sequential Thinking When:
- **Complex Problem Solving**: Multi-step reasoning required
- **Architecture Design**: Planning major changes or new features
- **Debugging Complex Issues**: Root cause analysis with multiple factors
- **Example Triggers**: "design", "plan", "debug complex", "analyze deeply"

## 📋 Memory Lifecycle Management (MANDATORY)

### 🔍 Every Task Starts With Memory Retrieval
```python
# ALWAYS start tasks with memory search
mcp__openmemory-local__search_memory(query="relevant keywords")
mcp__serena__read_memory("relevant_memory_name")  # if project-specific
```

### ➕ Continuous Memory Addition
```python
# Store cross-application knowledge
mcp__openmemory-local__add_memories(text="Solution/configuration that applies across projects")

# Store project-specific knowledge  
mcp__serena__write_memory("memory_name", "Architecture decisions, code patterns, project insights")
```

### 🔄 Memory Updates
- Update memories when information changes or evolves
- Version important architectural decisions
- Keep debugging solutions current

### 🗑️ Memory Deletion
```python
# Clean up outdated information
mcp__serena__delete_memory("outdated_memory_name")
# Note: OpenMemory-local uses delete_all_memories for bulk cleanup
```

## 🛠️ Comprehensive Workflow Examples

### Example 1: Adding New Feature
```python
# 1. Memory Retrieval
mcp__openmemory-local__search_memory("similar feature patterns")
mcp__serena__read_memory("architecture_patterns")

# 2. Code Understanding
get_symbols_overview("src/")
find_symbol("related_component", symbol_type="class")

# 3. Implementation (use Sequential Thinking for complex features)
# 4. Pattern Application
ast-grep -p 'existing_pattern' --rewrite 'new_pattern' -l python

# 5. Memory Storage
mcp__serena__write_memory("new_feature_pattern", "Design decisions and implementation approach")
mcp__openmemory-local__add_memories("Feature implementation technique that can be reused")
```

### Example 2: Debugging Session
```python
# 1. Search for similar issues
mcp__openmemory-local__search_memory("error message OR similar symptoms")

# 2. Understand code flow
find_symbol("problematic_function")
find_referencing_symbols("file.py", line=100)

# 3. Use Task agent if scope is unclear
# 4. Store solution
mcp__openmemory-local__add_memories("Bug: [description] Solution: [steps] Root cause: [analysis]")
```

### Example 3: Large Refactoring
```python
# 1. Use Sequential Thinking for planning
# 2. Find all affected code
find_symbol("target_symbol", symbol_type="function")
find_referencing_symbols("file.py", line=50)

# 3. Apply transformations
ast-grep -p 'old_pattern' --rewrite 'new_pattern' --interactive

# 4. Update architectural knowledge
mcp__serena__write_memory("refactoring_decision", "Why we changed X to Y, impact analysis")
```

## Project Overview

Mem0 is a long-term memory layer for AI agents and assistants, enabling personalized AI interactions. It remembers user preferences, adapts to individual needs, and continuously learns over time.

## Essential Development Commands

### Setup & Installation
```bash
# Install the main project
pip install -e .

# Install with all optional dependencies
pip install -e ".[graph,vector_stores,llms,extras,test,dev]"

# For development using hatch
hatch env create
make install_all  # Installs all optional dependencies
```

### Code Quality & Testing
```bash
# Format code (REQUIRED before committing)
make format
# or
hatch run format

# Sort imports
make sort
# or
hatch run isort mem0/

# Lint code (must pass)
make lint
# or
hatch run lint

# Run tests
make test                # Default Python version
make test-py-3.9        # Python 3.9
make test-py-3.10       # Python 3.10
make test-py-3.11       # Python 3.11

# Run specific test
hatch run test tests/test_memory.py::TestClass::test_method
```

### Build & Release
```bash
make build      # Build package
make publish    # Publish to PyPI
make clean      # Clean build artifacts
```

### Documentation
```bash
make docs       # Start local documentation server
```

## High-Level Architecture

### Core Components

1. **Memory System** (`mem0/memory/`)
   - `main.py`: Core Memory and AsyncMemory classes
   - `memgraph_memory.py`: Graph-based memory implementation
   - Memory operations: add, search, update, delete, history, reset

2. **Vector Stores** (`mem0/vector_stores/`)
   - Multiple implementations: Qdrant (default), ChromaDB, Weaviate, Pinecone, FAISS, etc.
   - Abstraction layer for different vector databases

3. **LLMs** (`mem0/llms/`)
   - Support for multiple providers: OpenAI (default), Groq, Together, Ollama, Google, etc.
   - Configurable through provider/config pattern

4. **Embeddings** (`mem0/embeddings/`)
   - Text embedding generation for memory storage
   - Multiple providers supported

5. **Graph Store** (`mem0/graphs/`)
   - Neo4j-based graph memory storage
   - Entity and relationship extraction

6. **Client** (`mem0/client/`)
   - MemoryClient and AsyncMemoryClient for API interactions
   - Handles authentication and remote memory operations

### Key Design Patterns

- **Provider Pattern**: LLMs, embeddings, and vector stores use a provider/config pattern for flexibility
- **Async Support**: All major operations have async variants (AsyncMemory, AsyncMemoryClient)
- **Metadata & Filtering**: Extensive metadata support for memory organization (user_id, agent_id, session_id)
- **Telemetry**: Built-in telemetry with PostHog for usage analytics (can be disabled)

### Memory Storage Architecture

Memories are stored with:
- Vector embeddings for semantic search
- Metadata for filtering and organization
- Optional graph relationships for complex memory structures
- History tracking for memory evolution

### OpenMemory

A separate self-hosted memory server implementation in `openmemory/`:
- API server for memory operations
- MCP (Model Context Protocol) server support
- React-based UI for memory visualization
- Docker-based deployment

## Code Style & Conventions

- **Python 3.9+ required**
- **Type hints**: Use Pydantic models for data validation
- **Line length**: 120 characters (configured in ruff)
- **Import sorting**: Use isort with black profile
- **Excluded from linting**: embedchain/ and openmemory/ directories
- **Pre-commit hooks**: Ensure ruff and isort pass before committing

## Testing Guidelines

- Tests located in `tests/` directory, mirroring source structure
- Use pytest with fixtures for test setup
- Mock external services (LLMs, vector stores) in tests
- Test files named `test_*.py`
- Use `pytest-asyncio` for async tests
- Coverage expected for new features

## 🔧 ast-grep Integration Guide

### Quick ast-grep Commands
```bash
# Find patterns in Python code
ast-grep -p 'def $FUNC($$$ARGS):' -l python

# Find and replace across TypeScript files
ast-grep -p 'console.log($ARG)' --rewrite 'logger.info($ARG)' -l typescript --interactive

# Find class definitions
ast-grep -p 'class $CLASS:' -l python

# Find async functions
ast-grep -p 'async def $FUNC($$$ARGS):' -l python

# Find React components
ast-grep -p 'function $COMPONENT($PROPS) { return <$$$JSX> }' -l tsx
```

### ast-grep Pattern Syntax
- `$VAR` - matches single named node
- `$$VAR` - includes unnamed nodes (punctuation, operators)  
- `$$$VAR` - matches multiple nodes (spread operator)

### Language Support
- Python: `-l python`
- TypeScript/TSX: `-l typescript` or `-l tsx`
- JavaScript: `-l javascript`
- Rust: `-l rust`
- Go: `-l go`

## 🤖 MCP Tool Integration

### Available MCP Tools
- **Sequential Thinking**: `mcp__MCP_DOCKER__sequentialthinking` - Structured problem solving
- **Task Agent**: For complex multi-step operations and open-ended search
- **OpenMemory-local**: Cross-application persistent memory
- **Serena**: Semantic code analysis and project-specific memory
- **Browser automation**, **Git operations**, **File operations**, **Search tools**

### When to Use Each MCP Tool
```python
# Use Sequential Thinking for complex reasoning
mcp__MCP_DOCKER__sequentialthinking(thought="Analysis step", nextThoughtNeeded=True)

# Use Task agent for exploration
Task(description="Find files", prompt="Search for specific patterns across codebase")

# Always use memory tools for knowledge management
mcp__openmemory-local__search_memory(query="relevant context")
mcp__serena__read_memory("project_knowledge")
```

## Common Development Tasks

### Adding a New Vector Store
1. **Memory Check**: `mcp__openmemory-local__search_memory("vector store implementation")`
2. **Code Analysis**: `find_symbol("VectorStore", symbol_type="class")` 
3. Create new file in `mem0/vector_stores/`
4. **Pattern Application**: Use ast-grep to ensure consistent patterns
5. **Memory Storage**: Store implementation patterns for future use

### Adding a New LLM Provider  
1. **Memory Retrieval**: Search for existing LLM provider patterns
2. **Semantic Analysis**: `get_symbols_overview("mem0/llms/")`
3. Implement provider following existing patterns
4. **Consistency Check**: Use ast-grep for consistent configuration patterns
5. **Knowledge Storage**: Document provider-specific decisions

### Working with Memory Operations
- **Always start with memory search** for existing patterns
- Use metadata for additional context
- **Use Serena** to understand memory operation relationships
- **Use ast-grep** for consistent memory API usage patterns
- **Store insights** about memory operation optimizations

## Important Notes

- Default LLM is OpenAI's gpt-4o-mini (requires OPENAI_API_KEY)
- Default vector store is Qdrant
- Graph functionality requires Neo4j setup
- Telemetry can be disabled by setting environment variables
- The project supports both package installation and hosted platform usage