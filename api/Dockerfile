FROM python:3.12-slim

LABEL org.opencontainers.image.name="mem0/openmemory-mcp"

WORKDIR /usr/src/openmemory

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY config.json .
COPY . .

# Apply patches to fix mem0 Memgraph integration after pip install
RUN if [ -f patches/memgraph_memory.py ]; then \
    cp patches/memgraph_memory.py /usr/local/lib/python3.12/site-packages/mem0/memory/memgraph_memory.py; \
    fi

EXPOSE 8765
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8765"]
