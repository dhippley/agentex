defmodule Agentex.AgentSupervisor do
  @moduledoc """
  DynamicSupervisor for managing multiple AI agent instances.
  """
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new agent with the given configuration.
  """
  def start_agent(opts) do
    child_spec = {Agentex.AgentServer, opts}
    
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        agent_id = Keyword.fetch!(opts, :agent_id)
        Logger.info("Started agent #{agent_id} with PID #{inspect(pid)}")
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        agent_id = Keyword.fetch!(opts, :agent_id)
        Logger.info("Agent #{agent_id} already started with PID #{inspect(pid)}")
        {:ok, pid}
      error ->
        Logger.error("Failed to start agent: #{inspect(error)}")
        error
    end
  end

  @doc """
  Stop an agent.
  """
  def stop_agent(agent_id) do
    case Registry.lookup(Agentex.AgentRegistry, agent_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  List all running agents.
  """
  def list_agents do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_id, pid, _type, _modules} ->
      case Registry.keys(Agentex.AgentRegistry, pid) do
        [agent_id] -> 
          state = Agentex.AgentServer.get_state(agent_id)
          %{
            agent_id: agent_id,
            pid: pid,
            name: state.name,
            status: state.status,
            created_at: state.created_at,
            last_activity: state.last_activity
          }
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Get statistics about all agents.
  """
  def get_stats do
    agents = list_agents()
    
    %{
      total_agents: length(agents),
      active_agents: Enum.count(agents, fn agent -> agent.status == :active end),
      idle_agents: Enum.count(agents, fn agent -> agent.status == :idle end),
      working_agents: Enum.count(agents, fn agent -> agent.status == :working end),
      error_agents: Enum.count(agents, fn agent -> agent.status == :error end)
    }
  end
end
