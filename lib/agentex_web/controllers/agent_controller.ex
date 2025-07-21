defmodule AgentexWeb.AgentController do
  use AgentexWeb, :controller

  alias Agentex

  def index(conn, _params) do
    agents = Agentex.list_agents()
    json(conn, %{agents: agents})
  end

  def show(conn, %{"id" => agent_id}) do
    case Agentex.get_agent_state(agent_id) do
      {:ok, state} ->
        json(conn, %{agent: state})
      {:error, :agent_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found"})
    end
  end

  def create(conn, %{"name" => name} = params) do
    opts = []
    opts = if Map.has_key?(params, "system_prompt"), do: [system_prompt: params["system_prompt"]] ++ opts, else: opts

    case Agentex.create_agent(name, opts) do
      {:ok, agent_id} ->
        conn
        |> put_status(:created)
        |> json(%{agent_id: agent_id, message: "Agent created successfully"})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def delete(conn, %{"id" => agent_id}) do
    case Agentex.stop_agent(agent_id) do
      :ok ->
        json(conn, %{message: "Agent stopped successfully"})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found"})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def send_message(conn, %{"id" => agent_id, "message" => message}) do
    case Agentex.send_message(agent_id, message) do
      {:ok, response} ->
        json(conn, %{response: response})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def assign_task(conn, %{"id" => agent_id, "task" => task}) do
    case Agentex.assign_task(agent_id, task) do
      {:ok, :task_assigned} ->
        json(conn, %{message: "Task assigned successfully"})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def stats(conn, _params) do
    stats = Agentex.get_stats()
    json(conn, %{stats: stats})
  end
end
