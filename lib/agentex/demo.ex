defmodule Agentex.Demo do
  @moduledoc """
  Demo functions to showcase the agentic AI system.
  """

  alias Agentex

  @doc """
  Create demo agents with different personalities and capabilities.
  """
  def create_demo_agents do
    # Create a helpful assistant
    {:ok, assistant_id} = Agentex.create_agent("Helper", [
      system_prompt: """
      You are a helpful AI assistant. You can use tools to help users with various tasks.
      Available tools include calculations, web search, memory storage, weather, and notifications.
      When users ask for calculations, use [TOOL:calculate(expression=MATH_EXPRESSION)].
      When they ask for the time, use [TOOL:get_current_time()].
      When they want to remember something, use [TOOL:store_memory(key=KEY,value=VALUE)].
      When they ask for weather, use [TOOL:weather(location=LOCATION)].
      Always be helpful and explain what tools you're using.
      """
    ])

    # Create a math specialist
    {:ok, math_id} = Agentex.create_agent("MathBot", [
      system_prompt: """
      You are a mathematical expert. You love solving complex calculations and mathematical problems.
      Use the calculate tool frequently: [TOOL:calculate(expression=MATH_EXPRESSION)].
      You can handle arithmetic, algebra, and basic calculus.
      Always show your work and explain your solutions step by step.
      """
    ])

    # Create a research assistant
    {:ok, research_id} = Agentex.create_agent("Researcher", [
      system_prompt: """
      You are a research assistant specializing in information gathering.
      Use tools to search for information: [TOOL:search_web(query=SEARCH_TERMS)].
      Store important findings in memory: [TOOL:store_memory(key=TOPIC,value=FINDINGS)].
      You are thorough, accurate, and always cite your sources.
      """
    ])

    %{
      assistant: assistant_id,
      math_bot: math_id,
      researcher: research_id
    }
  end

  @doc """
  Run a demonstration conversation with the agents.
  """
  def run_demo(agent_ids) do
    IO.puts("🤖 Starting Agentex Demo")
    IO.puts("=" |> String.duplicate(50))

    # Test the helper agent
    IO.puts("\n📋 Testing Helper Agent:")
    test_helper_agent(agent_ids.assistant)

    # Test the math bot
    IO.puts("\n🔢 Testing Math Bot:")
    test_math_agent(agent_ids.math_bot)

    # Test the researcher
    IO.puts("\n🔍 Testing Researcher:")
    test_research_agent(agent_ids.researcher)

    IO.puts("\n✅ Demo completed!")
  end

  defp test_helper_agent(agent_id) do
    questions = [
      "What time is it?",
      "Can you calculate 15 * 23 + 7?",
      "Please remember that my favorite color is blue",
      "What's the weather like in San Francisco?"
    ]

    Enum.each(questions, fn question ->
      IO.puts("👤 User: #{question}")
      case Agentex.send_message(agent_id, question) do
        {:ok, response} ->
          IO.puts("🤖 Agent: #{response}")
        {:error, reason} ->
          IO.puts("❌ Error: #{inspect(reason)}")
      end
      Process.sleep(1000) # Small delay for readability
    end)
  end

  defp test_math_agent(agent_id) do
    math_problems = [
      "What is the square root of 144?",
      "Calculate the area of a circle with radius 5",
      "Solve for x: 2x + 5 = 15"
    ]

    Enum.each(math_problems, fn problem ->
      IO.puts("👤 User: #{problem}")
      case Agentex.send_message(agent_id, problem) do
        {:ok, response} ->
          IO.puts("🔢 MathBot: #{response}")
        {:error, reason} ->
          IO.puts("❌ Error: #{inspect(reason)}")
      end
      Process.sleep(1000)
    end)
  end

  defp test_research_agent(agent_id) do
    research_queries = [
      "Find information about Elixir programming language",
      "What are the benefits of functional programming?",
      "Store what you found about Elixir under the key 'elixir_info'"
    ]

    Enum.each(research_queries, fn query ->
      IO.puts("👤 User: #{query}")
      case Agentex.send_message(agent_id, query) do
        {:ok, response} ->
          IO.puts("🔍 Researcher: #{response}")
        {:error, reason} ->
          IO.puts("❌ Error: #{inspect(reason)}")
      end
      Process.sleep(1000)
    end)
  end

  @doc """
  Show current system stats.
  """
  def show_stats do
    stats = Agentex.get_stats()
    agents = Agentex.list_agents()

    IO.puts("\n📊 System Statistics:")
    IO.puts("Total Agents: #{stats.total_agents}")
    IO.puts("Active: #{stats.active_agents}")
    IO.puts("Idle: #{stats.idle_agents}")
    IO.puts("Working: #{stats.working_agents}")
    IO.puts("Error: #{stats.error_agents}")

    IO.puts("\n🤖 Agent Details:")
    Enum.each(agents, fn agent ->
      IO.puts("  • #{agent.name} (#{agent.agent_id}) - #{agent.status}")
    end)
  end

  @doc """
  Assign tasks to agents and monitor their progress.
  """
  def assign_demo_tasks(agent_ids) do
    IO.puts("\n📋 Assigning tasks to agents...")

    tasks = [
      {agent_ids.assistant, "Please create a daily schedule for someone learning programming"},
      {agent_ids.math_bot, "Calculate compound interest for $1000 at 5% for 10 years"},
      {agent_ids.researcher, "Research the history of artificial intelligence"}
    ]

    Enum.each(tasks, fn {agent_id, task} ->
      IO.puts("Assigning task to #{agent_id}: #{task}")
      case Agentex.assign_task(agent_id, task) do
        {:ok, :task_assigned} ->
          IO.puts("✅ Task assigned successfully")
        {:error, reason} ->
          IO.puts("❌ Failed to assign task: #{inspect(reason)}")
      end
    end)

    IO.puts("Tasks assigned! Check the web interface to see progress.")
  end
end
