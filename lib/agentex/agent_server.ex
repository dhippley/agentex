defmodule Agentex.AgentServer do
  @moduledoc """
  GenServer that manages individual AI agent instances.
  Each agent maintains its own state, conversation history, and planning context.
  """
  use GenServer
  require Logger

  alias Agentex.LLMClient
  alias Agentex.Tools

  defstruct [
    :agent_id,
    :name,
    :system_prompt,
    :conversation_history,
    :current_task,
    :tools,
    :memory,
    :status,
    :created_at,
    :last_activity
  ]

  ## Client API

  def start_link(opts) do
    agent_id = Keyword.fetch!(opts, :agent_id)
    name = Keyword.get(opts, :name, "Agent-#{agent_id}")
    system_prompt = Keyword.get(opts, :system_prompt, default_system_prompt())
    
    GenServer.start_link(__MODULE__, 
      %__MODULE__{
        agent_id: agent_id,
        name: name,
        system_prompt: system_prompt,
        conversation_history: [],
        current_task: nil,
        tools: Tools.available_tools(),
        memory: %{},
        status: :idle,
        created_at: DateTime.utc_now(),
        last_activity: DateTime.utc_now()
      }, 
      name: via_tuple(agent_id)
    )
  end

  def send_message(agent_id, message) do
    GenServer.call(via_tuple(agent_id), {:send_message, message})
  end

  def assign_task(agent_id, task) do
    GenServer.cast(via_tuple(agent_id), {:assign_task, task})
  end

  def get_state(agent_id) do
    GenServer.call(via_tuple(agent_id), :get_state)
  end

  def stop(agent_id) do
    GenServer.stop(via_tuple(agent_id))
  end

  ## Server Callbacks

  @impl true
  def init(state) do
    Logger.info("Starting agent: #{state.name} (#{state.agent_id})")
    schedule_health_check()
    {:ok, state}
  end

  @impl true
  def handle_call({:send_message, user_message}, _from, state) do
    Logger.info("Agent #{state.agent_id} received message: #{user_message}")
    
    # Add user message to conversation history
    updated_history = [
      %{role: :user, content: user_message, timestamp: DateTime.utc_now()}
      | state.conversation_history
    ]
    
    # Process with LLM
    case process_with_llm(state, user_message) do
      {:ok, response} ->
        # Add assistant response to history
        final_history = [
          %{role: :assistant, content: response, timestamp: DateTime.utc_now()}
          | updated_history
        ]
        
        new_state = %{state | 
          conversation_history: final_history,
          status: :active,
          last_activity: DateTime.utc_now()
        }
        
        # Broadcast state update
        broadcast_state_update(new_state)
        
        {:reply, {:ok, response}, new_state}
        
      {:error, reason} ->
        Logger.error("LLM processing failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:assign_task, task}, state) do
    Logger.info("Agent #{state.agent_id} assigned task: #{inspect(task)}")
    
    new_state = %{state | 
      current_task: task,
      status: :working,
      last_activity: DateTime.utc_now()
    }
    
    # Start working on the task asynchronously
    send(self(), {:work_on_task, task})
    
    broadcast_state_update(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:work_on_task, task}, state) do
    Logger.info("Agent #{state.agent_id} starting work on task")
    
    case execute_task(state, task) do
      {:ok, result} ->
        Logger.info("Agent #{state.agent_id} completed task: #{inspect(result)}")
        
        new_state = %{state | 
          status: :idle,
          current_task: nil,
          last_activity: DateTime.utc_now()
        }
        
        broadcast_task_completion(state.agent_id, task, result)
        broadcast_state_update(new_state)
        {:noreply, new_state}
        
      {:error, reason} ->
        Logger.error("Agent #{state.agent_id} task failed: #{inspect(reason)}")
        
        new_state = %{state | 
          status: :error,
          last_activity: DateTime.utc_now()
        }
        
        broadcast_task_error(state.agent_id, task, reason)
        broadcast_state_update(new_state)
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:health_check, state) do
    # Periodic health check and cleanup
    schedule_health_check()
    
    # Update memory and perform cleanup if needed
    updated_state = %{state | last_activity: DateTime.utc_now()}
    
    {:noreply, updated_state}
  end

  ## Private Functions

  defp via_tuple(agent_id) do
    {:via, Registry, {Agentex.AgentRegistry, agent_id}}
  end

  defp process_with_llm(state, user_message) do
    # Prepare messages for LLM
    messages = prepare_messages_for_llm(state, user_message)
    
    # Call LLM API
    LLMClient.chat_completion(messages, %{
      system: state.system_prompt,
      tools: state.tools,
      memory: state.memory
    })
  end

  defp prepare_messages_for_llm(state, user_message) do
    # Get recent conversation history (last 10 messages to avoid token limits)
    recent_history = 
      state.conversation_history
      |> Enum.take(10)
      |> Enum.reverse()
      |> Enum.map(fn msg -> 
        %{role: msg.role, content: msg.content} 
      end)
    
    # Add current message
    recent_history ++ [%{role: :user, content: user_message}]
  end

  defp execute_task(state, task) do
    # This is where the agent would use tools and planning to execute tasks
    # For now, we'll use the LLM to process the task
    task_prompt = """
    You have been assigned the following task: #{inspect(task)}
    
    Please analyze this task and provide a detailed response on how you would approach it.
    Consider what tools you might need and break it down into steps.
    """
    
    case process_with_llm(state, task_prompt) do
      {:ok, response} -> {:ok, %{task: task, response: response, completed_at: DateTime.utc_now()}}
      error -> error
    end
  end

  defp broadcast_state_update(state) do
    Phoenix.PubSub.broadcast(
      Agentex.PubSub,
      "agent:#{state.agent_id}",
      {:agent_state_update, state}
    )
  end

  defp broadcast_task_completion(agent_id, task, result) do
    Phoenix.PubSub.broadcast(
      Agentex.PubSub,
      "agent:#{agent_id}",
      {:task_completed, %{agent_id: agent_id, task: task, result: result}}
    )
  end

  defp broadcast_task_error(agent_id, task, reason) do
    Phoenix.PubSub.broadcast(
      Agentex.PubSub,
      "agent:#{agent_id}",
      {:task_error, %{agent_id: agent_id, task: task, reason: reason}}
    )
  end

  defp schedule_health_check do
    Process.send_after(self(), :health_check, 60_000) # Every minute
  end

  defp default_system_prompt do
    """
    You are an intelligent AI assistant agent. You can help with various tasks including:
    - Answering questions and providing information
    - Planning and breaking down complex tasks
    - Using tools to gather information or perform actions
    - Maintaining context across conversations
    
    Be helpful, accurate, and communicate clearly. When given a task, think through it step by step.
    """
  end
end
