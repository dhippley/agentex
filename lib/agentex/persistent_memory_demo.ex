defmodule Agentex.PersistentMemoryDemo do
  @moduledoc """
  Demonstration of persistent memory capabilities with vector embeddings.
  """
  
  alias Agentex.AgentSupervisor
  alias Agentex.AgentServer
  alias Agentex.Memory
  
  def run_demo do
    IO.puts("🚀 Starting Persistent Memory Demo...")
    
    # Create a demo agent
    agent_id = "demo_agent_#{System.unique_integer()}"
    IO.puts("📱 Creating agent: #{agent_id}")
    
    {:ok, _pid} = AgentSupervisor.start_agent(
      agent_id: agent_id,
      name: "Knowledge Bot",
      system_prompt: "You are a helpful AI assistant that learns and remembers important information."
    )
    
    # Test 1: Store some important knowledge
    IO.puts("\n📚 Testing knowledge storage...")
    store_sample_knowledge(agent_id)
    
    # Wait for embeddings to be generated
    Process.sleep(3000)
    
    # Test 2: Search for knowledge semantically
    IO.puts("\n🔍 Testing semantic search...")
    test_semantic_search(agent_id)
    
    # Test 3: Send messages to the agent (will auto-store important ones)
    IO.puts("\n💬 Testing conversation auto-storage...")
    test_conversation_auto_storage(agent_id)
    
    # Test 4: Use agent tools for knowledge management
    IO.puts("\n🛠️ Testing knowledge management tools...")
    test_knowledge_tools(agent_id)
    
    # Clean up
    AgentServer.stop(agent_id)
    
    IO.puts("\n✅ Persistent Memory Demo completed!")
  end
  
  defp store_sample_knowledge(agent_id) do
    knowledge_items = [
      {"Elixir is a dynamic, functional programming language designed for building maintainable and scalable applications", 0.9},
      {"Phoenix Framework is a web development framework written in Elixir that follows the Model-View-Controller pattern", 0.8},
      {"GenServers are the foundation of OTP and provide a way to build stateful processes in Elixir", 0.9},
      {"Vector databases enable semantic search by storing and comparing high-dimensional embeddings", 0.8},
      {"PostgreSQL with pgvector extension allows storing and querying vector embeddings efficiently", 0.7}
    ]
    
    Enum.each(knowledge_items, fn {content, importance} ->
      case Memory.store_persistent(agent_id, content, %{source: "demo", type: "knowledge"}, importance) do
        {:ok, _} -> IO.puts("  ✅ Stored: #{String.slice(content, 0, 50)}...")
        {:error, error} -> IO.puts("  ❌ Failed: #{inspect(error)}")
      end
    end)
  end
  
  defp test_semantic_search(agent_id) do
    search_queries = [
      "functional programming languages",
      "web development frameworks", 
      "database vector search",
      "concurrent programming"
    ]
    
    Enum.each(search_queries, fn query ->
      case Memory.search_semantic(agent_id, query, limit: 3) do
        {:ok, results} ->
          IO.puts("  🔍 Query: '#{query}'")
          Enum.each(results, fn result ->
            similarity = Float.round(result.similarity, 3)
            preview = String.slice(result.content, 0, 60)
            IO.puts("    📄 [#{similarity}] #{preview}...")
          end)
      end
    end)
  end
  
  defp test_conversation_auto_storage(agent_id) do
    # Have some conversations that should trigger auto-storage
    conversations = [
      "Can you explain the differences between GenServer and GenStage in Elixir?",
      "How does Phoenix LiveView handle real-time updates?", 
      "What are the benefits of using pgvector for vector storage?",
      "Explain the actor model in Elixir and OTP supervision trees"
    ]
    
    IO.puts("🤖 Testing auto-storage during conversations:")
    
    Enum.each(conversations, fn message ->
      case AgentServer.send_message(agent_id, message) do
        {:ok, response} ->
          IO.puts("  � User: #{message}")
          preview = String.slice(response, 0, 80)
          IO.puts("  🤖 Agent: #{preview}...")
          # Check if memories were auto-stored
          case Memory.search_semantic(agent_id, message, limit: 1) do
            {:ok, [memory | _]} ->
              IO.puts("  ✅ Auto-stored with importance: #{Float.round(memory.importance, 2)}")
            {:ok, []} ->
              IO.puts("  ⏳ Not yet stored (below importance threshold)")
          end
      end
      Process.sleep(500) # Brief pause between conversations
    end)
  end
  
  defp test_knowledge_tools(agent_id) do
    # Test storing knowledge via tool
    store_result = Agentex.Tools.execute_tool(
      "store_knowledge",
      %{
        "content" => "Machine learning models can be integrated with Elixir using Nx and Axon libraries",
        "importance" => 0.85,
        "category" => "ML"
      },
      %{agent_id: agent_id}
    )
    
    case store_result do
      {:ok, result} -> 
        IO.puts("  🛠️ Stored knowledge via tool: #{result.message}")
      {:error, error} -> 
        IO.puts("  ❌ Tool storage failed: #{inspect(error)}")
    end
    
    # Wait for embedding generation
    Process.sleep(2000)
    
    # Test searching knowledge via tool
    search_result = Agentex.Tools.execute_tool(
      "search_knowledge",
      %{"query" => "machine learning", "limit" => 3},
      %{agent_id: agent_id}
    )
    
    case search_result do
      {:ok, result} ->
        IO.puts("  🔍 Tool search: #{result.message}")
        Enum.each(result.results, fn item ->
          preview = String.slice(item.content, 0, 50)
          IO.puts("    📄 [#{item.similarity}] #{preview}...")
        end)
      {:error, error} ->
        IO.puts("  ❌ Tool search failed: #{inspect(error)}")
    end
    
    # Test recalling important knowledge
    recall_result = Agentex.Tools.execute_tool(
      "recall_important_knowledge",
      %{"min_importance" => 0.8, "limit" => 5},
      %{agent_id: agent_id}
    )
    
    case recall_result do
      {:ok, result} ->
        IO.puts("  ⭐ Important memories: #{result.message}")
        Enum.each(result.results, fn item ->
          preview = String.slice(item.content, 0, 50)
          IO.puts("    📄 [#{item.importance}] #{preview}...")
        end)
      {:error, error} ->
        IO.puts("  ❌ Recall failed: #{inspect(error)}")
    end
  end
end
