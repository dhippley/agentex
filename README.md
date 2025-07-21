# Agentex
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

🧠 Tech Stack
Elixir/Phoenix — Real-time web and process orchestration
Nx/Axon — ML inference (if you're running lightweight models or using embedded logic)
External LLM API — For cognition, e.g. OpenAI, Anthropic, etc.
ETS/GenServers/Agents — Agent memory/state
Phoenix LiveView or Channels — Real-time UI or streaming interaction
