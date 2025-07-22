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
- **ETS** — Fast in-memory storage for agent memory
- **Phoenix LiveView** — Real-time UI for agent interaction
- **Phoenix PubSub** — Real-time communication between agents and UI
- **External LLM API** — For AI cognition (OpenAI, Anthropic, etc.)
- **RESTful API** — Programmatic access to agents

## 🚀 Features

- **Multi-Agent System**: Create and manage multiple AI agents simultaneously
- **Real-time Communication**: Instant messaging with agents via LiveView
- **Tool Integration**: Agents can use tools like calculator, web search, memory storage
- **Task Assignment**: Assign complex tasks to agents for background processing
- **Memory Management**: Each agent has persistent memory using ETS
- **API Access**: Full REST API for programmatic interaction
- **Live Dashboard**: Real-time monitoring of agent states and activities

## 🛠️ Available Tools

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

4. Start the Phoenix server:
```bash
mix phx.server
```

5. Visit [`localhost:4000/agents`](http://localhost:4000/agents) for the web interface

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
- ETS-based storage for fast access
- Per-agent memory isolation
- Automatic cleanup of old entries
- Search and retrieval capabilities

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

## 🙏 Acknowledgments

- Phoenix Framework team
- Elixir community
- OpenAI and Anthropic for AI APIs
```
+-----------------+          +------------------+
|  User/Browser   | <------> |  Phoenix LiveView|  <- UI (optional)
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
                          |  (ETS / DB)     |
                          +----------------+
```
```
🧠 Tech Stack
Elixir/Phoenix — Real-time web and process orchestration
Nx/Axon — ML inference (if you're running lightweight models or using embedded logic)
External LLM API — For cognition, e.g. OpenAI, Anthropic, etc.
ETS/GenServers/Agents — Agent memory/state
Phoenix LiveView or Channels — Real-time UI or streaming interaction
```
