defmodule Agentex do
  @moduledoc """
  Agentex keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Agentex.AgentSupervisor
  alias Agentex.AgentServer

  ## Agent Management

  @doc """
  Create a new AI agent.
  """
  def create_agent(name, opts \\ []) do
    agent_id = generate_agent_id()
    system_prompt = Keyword.get(opts, :system_prompt)

    agent_opts = [
      agent_id: agent_id,
      name: name,
      system_prompt: system_prompt
    ]

    case AgentSupervisor.start_agent(agent_opts) do
      {:ok, _pid} -> {:ok, agent_id}
      error -> error
    end
  end

  @doc """
  Send a message to an agent and get a response.
  """
  def send_message(agent_id, message) do
    AgentServer.send_message(agent_id, message)
  end

  @doc """
  Assign a task to an agent.
  """
  def assign_task(agent_id, task) do
    try do
      AgentServer.assign_task(agent_id, task)
      {:ok, :task_assigned}
    rescue
      _ -> {:error, :agent_not_found}
    end
  end

  @doc """
  Get the current state of an agent.
  """
  def get_agent_state(agent_id) do
    try do
      state = AgentServer.get_state(agent_id)
      {:ok, state}
    rescue
      _ -> {:error, :agent_not_found}
    end
  end

  @doc """
  Stop an agent.
  """
  def stop_agent(agent_id) do
    AgentSupervisor.stop_agent(agent_id)
  end

  @doc """
  List all agents.
  """
  def list_agents do
    AgentSupervisor.list_agents()
  end

  @doc """
  Get system statistics.
  """
  def get_stats do
    AgentSupervisor.get_stats()
  end

  ## Private Functions

  defp generate_agent_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end
end
