defmodule Agentex.Memory do
  @moduledoc """
  Memory management for agents using both ETS for fast in-memory storage
  and PostgreSQL with vector embeddings for persistent semantic memory.
  Each agent has its own memory space.
  """
  use GenServer
  require Logger
  alias Agentex.Memory.PersistentMemory

  @table_name :agent_memory

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Store a key-value pair for a specific agent in ETS.
  For conversational and temporary data.
  """
  def store(agent_id, key, value) do
    timestamp = DateTime.utc_now()
    entry = {agent_id, key, value, timestamp}

    case :ets.insert(@table_name, entry) do
      true -> {:ok, :stored}
      false -> {:error, :storage_failed}
    end
  end

  @doc """
  Store important memories persistently with vector embeddings.
  This enables semantic search and long-term retention.
  """
  def store_persistent(agent_id, content, metadata \\ %{}, importance \\ 0.5) do
    case PersistentMemory.store_memory(agent_id, content, metadata, importance) do
      {:ok, memory} ->
        Logger.debug("Stored persistent memory for agent #{agent_id}: #{String.slice(content, 0, 50)}...")
        {:ok, memory}
      {:error, changeset} ->
        Logger.error("Failed to store persistent memory: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  @doc """
  Search agent's persistent memories using semantic similarity.
  Returns memories most relevant to the query.
  """
  def search_semantic(agent_id, query, opts \\ []) do
    case PersistentMemory.search_memories(agent_id, query, opts) do
      memories when is_list(memories) ->
        Logger.debug("Found #{length(memories)} semantic matches for agent #{agent_id}")
        {:ok, memories}
      error ->
        Logger.error("Semantic search failed: #{inspect(error)}")
        {:ok, []}
    end
  end

  @doc """
  Get recent persistent memories for an agent.
  """
  def get_recent_persistent(agent_id, opts \\ []) do
    case PersistentMemory.get_recent_memories(agent_id, opts) do
      memories when is_list(memories) ->
        {:ok, memories}
      error ->
        Logger.error("Failed to get recent memories: #{inspect(error)}")
        {:ok, []}
    end
  end

  @doc """
  Get important persistent memories for an agent.
  """
  def get_important_persistent(agent_id, opts \\ []) do
    case PersistentMemory.get_important_memories(agent_id, opts) do
      memories when is_list(memories) ->
        {:ok, memories}
      error ->
        Logger.error("Failed to get important memories: #{inspect(error)}")
        {:ok, []}
    end
  end

  @doc """
  Auto-store important conversation turns as persistent memories.
  Analyzes conversation content and stores significant interactions.
  """
  def auto_store_conversation(agent_id, conversation_turn) do
    # Determine if this conversation turn is worth storing persistently
    importance = calculate_importance(conversation_turn)

    if importance > 0.3 do
      content = format_conversation_content(conversation_turn)
      metadata = %{
        type: "conversation",
        timestamp: DateTime.utc_now(),
        auto_generated: true
      }

      store_persistent(agent_id, content, metadata, importance)
    else
      # Store in ETS for short-term access
      store(agent_id, "conversation_#{System.unique_integer()}", conversation_turn)
    end
  end

  @doc """
  Retrieve a value by key for a specific agent from ETS.
  """
  def retrieve(agent_id, key) do
    case :ets.match(@table_name, {agent_id, key, :"$1", :"$2"}) do
      [[value, _timestamp]] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Get all memory entries for a specific agent from ETS.
  """
  def get_all(agent_id) do
    pattern = {agent_id, :"$1", :"$2", :"$3"}

    entries =
      :ets.match(@table_name, pattern)
      |> Enum.map(fn [key, value, timestamp] ->
        %{key: key, value: value, timestamp: timestamp}
      end)

    {:ok, entries}
  end

  @doc """
  Delete a specific memory entry for an agent from ETS.
  """
  def delete(agent_id, key) do
    pattern = {agent_id, key, :"$1", :"$2"}
    case :ets.match_delete(@table_name, pattern) do
      n when n > 0 -> {:ok, :deleted}
      0 -> {:error, :not_found}
    end
  end

  @doc """
  Clear all memory for a specific agent from ETS.
  """
  def clear_agent_memory(agent_id) do
    pattern = {agent_id, :"$1", :"$2", :"$3"}
    :ets.match_delete(@table_name, pattern)
    {:ok, :cleared}
  end

  @doc """
  Search memory entries by pattern in ETS.
  """
  def search(agent_id, search_term) do
    pattern = {agent_id, :"$1", :"$2", :"$3"}

    results =
      :ets.match(@table_name, pattern)
      |> Enum.filter(fn [key, value, _timestamp] ->
        key_match = String.contains?(to_string(key), search_term)
        value_match = String.contains?(to_string(value), search_term)
        key_match || value_match
      end)
      |> Enum.map(fn [key, value, timestamp] ->
        %{key: key, value: value, timestamp: timestamp}
      end)

    {:ok, results}
  end

  ## GenServer Callbacks

  @impl true
  def init(_args) do
    Logger.info("Starting Agent Memory system")

    # Create ETS table for agent memory
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    # Schedule periodic cleanup
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Logger.debug("Running memory cleanup")
    cleanup_old_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private Functions

  defp schedule_cleanup do
    # Run cleanup every hour
    Process.send_after(self(), :cleanup, 3_600_000)
  end

  defp cleanup_old_entries do
    # Remove ETS entries older than 7 days
    cutoff_date = DateTime.add(DateTime.utc_now(), -7, :day)

    all_entries = :ets.tab2list(@table_name)

    Enum.each(all_entries, fn {agent_id, key, _value, timestamp} ->
      if DateTime.compare(timestamp, cutoff_date) == :lt do
        pattern = {agent_id, key, :"$1", :"$2"}
        :ets.match_delete(@table_name, pattern)
      end
    end)

    Logger.debug("ETS memory cleanup completed")

    # Also cleanup old persistent memories for all agents
    cleanup_persistent_memories()
  end

  defp cleanup_persistent_memories do
    # This would typically be done per agent, but for now we'll just log
    Logger.debug("Persistent memory cleanup scheduled (implement per-agent cleanup)")
  end

  defp calculate_importance(%{user: user_msg, assistant: assistant_msg}) do
    # Simple heuristic for importance
    importance = 0.5

    # Questions tend to be more important
    importance = if String.contains?(user_msg, "?"), do: importance + 0.2, else: importance

    # Longer responses might be more informative
    msg_length = String.length(user_msg) + String.length(assistant_msg)
    importance = importance + min(msg_length / 1000, 0.3)

    # Cap at 1.0
    min(importance, 1.0)
  end

  defp calculate_importance(_), do: 0.5

  defp format_conversation_content(%{user: user_msg, assistant: assistant_msg}) do
    "User: #{user_msg}\nAssistant: #{assistant_msg}"
  end

  defp format_conversation_content(content) when is_binary(content), do: content
  defp format_conversation_content(content), do: inspect(content)
end
