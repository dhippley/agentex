#!/usr/bin/env elixir

# Simple test script for Agentex

Mix.install([
  {:agentex, path: "."}
])

# Create demo agents
IO.puts("Creating demo agents...")
agent_ids = Agentex.Demo.create_demo_agents()
IO.inspect(agent_ids, label: "Created agents")

# Show system stats
Agentex.Demo.show_stats()

# Test a simple interaction
IO.puts("\nTesting agent interaction...")
case Agentex.send_message(agent_ids.assistant, "Hello! What can you do?") do
  {:ok, response} ->
    IO.puts("Agent response: #{response}")
  {:error, reason} ->
    IO.puts("Error: #{inspect(reason)}")
end

IO.puts("\nDemo completed!")
