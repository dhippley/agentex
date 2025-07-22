# Agentex - Vector Store Setup

This document explains how to use the PostgreSQL vector store with Docker Compose for persistent agent memory.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose V2
- Elixir and Phoenix (already set up)

### Database Setup

1. **Start PostgreSQL with vector support:**
   ```bash
   ./db.sh start
   ```

2. **Set up the database (first time only):**
   ```bash
   ./db.sh setup
   ```

3. **Start the Phoenix application:**
   ```bash
   mix phx.server
   ```

## 🗄️ Database Management

The `db.sh` script provides convenient commands for managing the PostgreSQL database:

```bash
./db.sh start      # Start PostgreSQL container
./db.sh stop       # Stop PostgreSQL container
./db.sh restart    # Restart PostgreSQL container
./db.sh logs       # Show PostgreSQL logs
./db.sh shell      # Connect to PostgreSQL shell
./db.sh setup      # First-time database setup
./db.sh reset      # Reset database (deletes all data)
./db.sh migrate    # Run pending migrations
./db.sh rollback   # Rollback last migration
./db.sh status     # Show container status
```

## 🧠 Vector Store Features

### Persistent Memory with Embeddings

The application now supports persistent memory storage with vector embeddings for semantic search:

1. **Automatic Embedding Generation:** Text is automatically converted to vector embeddings using sentence transformers
2. **Semantic Search:** Find similar memories based on meaning, not just keywords
3. **Importance Scoring:** Memories have importance scores for prioritization
4. **Efficient Storage:** PostgreSQL with pgvector extension for fast similarity search

### Memory Types

- **ETS Memory:** Fast in-memory storage for temporary/conversation data
- **Persistent Memory:** Database storage with vector embeddings for long-term knowledge

### API Usage

```elixir
# Store a persistent memory with importance
{:ok, memory} = Agentex.Memory.store_persistent(
  "agent_123", 
  "I learned that Elixir has excellent concurrency", 
  %{source: "conversation"}, 
  0.8
)

# Search for similar memories
{:ok, results} = Agentex.Memory.search_semantic(
  "agent_123", 
  "concurrent programming", 
  limit: 5
)

# Get recent memories
{:ok, recent} = Agentex.Memory.get_recent_persistent("agent_123", limit: 10)

# Get important memories
{:ok, important} = Agentex.Memory.get_important_persistent(
  "agent_123", 
  min_importance: 0.7
)
```

## 🧪 Testing Vector Store

Test the vector store functionality:

```bash
# Start IEx with the application
iex -S mix

# Run the test
Agentex.VectorStoreTest.run_test()
```

## 🏗️ Architecture

### Components

1. **PostgreSQL + pgvector:** Vector database for similarity search
2. **Bumblebee + Nx:** ML framework for generating embeddings
3. **EXLA:** Backend for fast tensor operations
4. **Ecto:** Database ORM for data management

### Embedding Model

- **Model:** `sentence-transformers/all-MiniLM-L6-v2`
- **Embedding Size:** 384 dimensions
- **Features:** Lightweight, fast, good quality embeddings

### Database Schema

The `memories` table includes:
- `id`: Unique identifier
- `agent_id`: Agent the memory belongs to
- `content`: The text content
- `embedding`: Vector embedding (384 dimensions)
- `importance`: Importance score (0.0 - 1.0)
- `metadata`: Additional JSON metadata
- `created_at`/`updated_at`: Timestamps

## 🔧 Configuration

### Environment Variables

The database connection is configured in `config/dev.exs`:

```elixir
config :agentex, Agentex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "agentex_dev",
  port: 5432
```

### Docker Compose

The `docker-compose.yml` file configures:
- PostgreSQL 16 with pgvector extension
- Persistent data storage
- Health checks
- Port mapping (5432:5432)

## 🚨 Troubleshooting

### Common Issues

1. **Database connection failed:**
   ```bash
   ./db.sh status  # Check if container is running
   ./db.sh logs    # Check container logs
   ```

2. **Migration errors:**
   ```bash
   ./db.sh shell   # Connect to database
   # Check if pgvector extension is available
   ```

3. **Embedding model loading issues:**
   - First run downloads the model (may take time)
   - Check logs for embedding service errors
   - Ensure sufficient memory for model loading

### Performance Tips

1. **Embedding Generation:** 
   - Use batch processing for multiple texts
   - First run will be slower due to model download

2. **Vector Search:**
   - The ivfflat index improves search performance
   - Consider tuning the `lists` parameter for larger datasets

3. **Memory Management:**
   - Regular cleanup of old memories
   - Importance-based retention policies

## 🔮 Future Enhancements

- [ ] RAG (Retrieval Augmented Generation) integration
- [ ] Multi-agent knowledge sharing
- [ ] Advanced memory consolidation
- [ ] Distributed vector storage
- [ ] Custom embedding models
