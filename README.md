# Agentex

🧠 **An Agentic AI System built with Elixir and Phoenix**

Agentex is a powerful, real-time agentic AI platform that allows you to create, manage, and interact with multiple AI agents simultaneously. Each agent is a GenServer that maintains its own state, conversation history, and can use tools to perform various tasks.

## Architecture

```
+-----------------+          +------------------+
|  User/Browser   | <------> |  Phoenix LiveView|  <- Real-time UI
+-----------------+          +------------------+
                                  |
                                  v
                        +-------------------+
                        |    Agent Server    | <- GenServer per agent
                        +-------------------+
                                  |
           +------------------+  |   +----------------------+
           | LLM/AI API       |<---->|  Planning / Tools     |
           +------------------+     +----------------------+
                                  |
                          +----------------+
                          |  Persistent Store|
                          |  (ETS / Memory) |
                          +----------------+
```

## 🧠 Tech Stack

- **Elixir/Phoenix** — Real-time web and process orchestration
- **GenServers/Agents** — Agent memory/state management
- **PostgreSQL + pgvector** — Vector database for semantic memory search
- **Bumblebee + Nx** — Machine learning and embedding generation
- **EXLA** — Google XLA backend for fast tensor operations
- **ETS** — Fast in-memory storage for temporary agent memory
- **Phoenix LiveView** — Real-time UI for agent interaction
- **Phoenix PubSub** — Real-time communication between agents and UI
- **External LLM API** — For AI cognition (OpenAI, Anthropic, etc.)
- **RESTful API** — Programmatic access to agents
- **Docker Compose** — Containerized database deployment

## 🧮 Vector Storage & Semantic Memory

Agentex features a sophisticated **persistent memory system** with vector embeddings for semantic search:

### Key Features
- **🎯 Semantic Search**: Find memories by meaning, not just keywords
- **📊 Embedding Generation**: Automatic text-to-vector conversion using sentence transformers
- **⚡ Fast Similarity Search**: Optimized PostgreSQL with pgvector extension
- **🏆 Importance Scoring**: Prioritize valuable memories (0.0 - 1.0 scale)
- **🔄 Hybrid Storage**: ETS for fast temporary data, PostgreSQL for persistent knowledge
- **🐳 Docker Ready**: Easy setup with Docker Compose

### How It Works
```elixir
# Store important memories with semantic embeddings
{:ok, memory} = Agentex.Memory.store_persistent(
  "agent_123", 
  "Elixir's Actor model enables fault-tolerant systems", 
  %{source: "learning"}, 
  0.9  # importance score
)

# Search by semantic similarity
{:ok, results} = Agentex.Memory.search_semantic(
  "agent_123", 
  "fault tolerance programming", 
  limit: 5
)
# Returns memories about fault tolerance, Actor model, resilience, etc.
```

### Quick Database Setup
```bash
# Start PostgreSQL with pgvector
./db.sh start

# Set up database (first time)
./db.sh setup

# Test vector storage
iex -S mix
Agentex.VectorStoreTest.run_test()
```

See [`VECTOR_STORE.md`](VECTOR_STORE.md) for detailed documentation.

## 🚀 Features

- **Multi-Agent System**: Create and manage multiple AI agents simultaneously
- **Real-time Communication**: Instant messaging with agents via LiveView
- **Vector Memory Storage**: Semantic memory with PostgreSQL + pgvector for intelligent recall
- **Tool Integration**: Agents can use tools like calculator, web search, memory storage
- **Task Assignment**: Assign complex tasks to agents for background processing
- **Hybrid Memory Management**: Fast ETS + persistent vector database storage
- **API Access**: Full REST API for programmatic interaction
- **Live Dashboard**: Real-time monitoring of agent states and activities
- **Docker Integration**: Easy database setup with Docker Compose


## 🚧 Features in Progress

The following features are currently under development:

- **Retrieval-Augmented Generation (RAG)** - Integration with vector databases and document retrieval for knowledge-enhanced agent responses
- **Local Model Integration with Axon** - Support for running local ML models using Elixir's Axon library for privacy and reduced latency
- **Agent Planning/Goal-Setting Logic** - Advanced planning capabilities allowing agents to break down complex goals into actionable steps and track progress
- **Multi-agent Coordination (Swarm-like Behavior)** - Enable agents to collaborate, communicate, and coordinate tasks across multiple agents for complex problem solving
- **Goal Decomposition / Planning** - Sophisticated goal breakdown system that creates hierarchical task trees and execution strategies
- **Streaming Responses** - Real-time streaming of agent responses for improved user experience and faster feedback
- **Real-time Notifications** - Enhanced notification system with webhooks, email, and push notifications for agent events

## �🛠️ Available Tools

Each agent has access to these tools:

1. **Calculator** - Perform mathematical calculations
2. **Current Time** - Get current date and time
3. **Memory Storage** - Store and retrieve information
4. **Web Search** - Search for information (mock implementation)
5. **Weather** - Get weather information (mock implementation)
6. **ID Generator** - Generate unique identifiers
7. **Notifications** - Send alerts and notifications

## 🚀 Getting Started

### Prerequisites

- Elixir 1.14+
- Phoenix 1.7+
- Node.js (for assets)
- Docker & Docker Compose (for database)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/agentex.git
cd agentex
```

2. Install dependencies:
```bash
mix deps.get
```

3. Install Node.js dependencies:
```bash
cd assets && npm install && cd ..
```

4. Set up the PostgreSQL database with vector support:
```bash
# Start database container
./db.sh start

# Create database and run migrations (first time only)
./db.sh setup
```

5. Start the Phoenix server:
```bash
mix phx.server
```

6. Visit [`localhost:4000/agents`](http://localhost:4000/agents) for the web interface

### Database Management

Use the convenient `db.sh` script for database operations:

```bash
./db.sh start      # Start PostgreSQL container
./db.sh stop       # Stop PostgreSQL container
./db.sh logs       # View database logs
./db.sh shell      # Connect to PostgreSQL shell
./db.sh status     # Check container status
./db.sh reset      # Reset database (WARNING: deletes all data)
```

### API Configuration (Optional)

To use real AI models instead of mock responses, set environment variables:

```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

## 📖 Usage Examples

### Web Interface

1. Open [`localhost:4000/agents`](http://localhost:4000/agents)
2. Click "New Agent" to create an agent
3. Select an agent to start chatting
4. Assign tasks using the task input field

### API Usage

#### Create an Agent
```bash
curl -X POST http://localhost:4000/api/agents 
  -H "Content-Type: application/json" 
  -d '{"name": "MyAgent", "system_prompt": "You are a helpful assistant."}'
```

#### Send a Message
```bash
curl -X POST http://localhost:4000/api/agents/{agent_id}/message 
  -H "Content-Type: application/json" 
  -d '{"message": "Hello! What can you do?"}'
```

#### Assign a Task
```bash
curl -X POST http://localhost:4000/api/agents/{agent_id}/task 
  -H "Content-Type: application/json" 
  -d '{"task": "Calculate the fibonacci sequence up to 10 numbers"}'
```

### Elixir Console

```elixir
# Start IEx
iex -S mix

# Create demo agents
agent_ids = Agentex.Demo.create_demo_agents()

# Run demonstrations
Agentex.Demo.run_demo(agent_ids)

# Assign tasks
Agentex.Demo.assign_demo_tasks(agent_ids)

# Test vector storage functionality
Agentex.VectorStoreTest.run_test()

# Store a persistent memory with semantic embedding
{:ok, memory} = Agentex.Memory.store_persistent(
  "agent_123", 
  "Phoenix LiveView enables real-time web applications", 
  %{category: "web-dev"}, 
  0.8
)

# Search memories semantically
{:ok, results} = Agentex.Memory.search_semantic(
  "agent_123", 
  "real-time web development", 
  limit: 5
)

# Check system stats
Agentex.Demo.show_stats()
```

## 🛠️ Development

### Running Tests
```bash
mix test
```

### Code Formatting
```bash
mix format
```

### Starting IEx
```bash
iex -S mix
```

## 🏗️ Architecture Details

### Agent Server (GenServer)
Each agent is a GenServer that maintains:
- Conversation history
- Current task state
- Memory storage
- Tool capabilities
- System prompt/personality

### Memory System
- **Hybrid Storage**: ETS for fast temporary memory + PostgreSQL for persistent knowledge
- **Vector Embeddings**: Automatic semantic embedding generation using sentence transformers
- **Similarity Search**: Fast vector similarity search with pgvector extension
- **Importance Scoring**: Weighted memory retention based on importance (0.0-1.0)
- **Per-agent Isolation**: Each agent maintains separate memory spaces
- **Automatic Cleanup**: Intelligent retention policies for memory management
- **Semantic Retrieval**: Find memories by meaning, not just exact keyword matches

### Tool System
- Modular tool architecture
- Easy to add new tools
- Context-aware execution
- Error handling and reporting

### Real-time Updates
- Phoenix PubSub for live updates
- LiveView for reactive UI
- Agent state broadcasting
- Task completion notifications

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents` | List all agents |
| POST | `/api/agents` | Create new agent |
| GET | `/api/agents/:id` | Get agent details |
| DELETE | `/api/agents/:id` | Stop agent |
| POST | `/api/agents/:id/message` | Send message |
| POST | `/api/agents/:id/task` | Assign task |
| GET | `/api/agents/stats` | System statistics |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

