defmodule Agentex.Memory do
  @moduledoc """
  Memory management for agents using ETS for fast in-memory storage.
  Each agent has its own memory space.
  """
  use GenServer
  require Logger

  @table_name :agent_memory

  ## Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Store a key-value pair for a specific agent.
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
  Retrieve a value by key for a specific agent.
  """
  def retrieve(agent_id, key) do
    case :ets.match(@table_name, {agent_id, key, :"$1", :"$2"}) do
      [[value, _timestamp]] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Get all memory entries for a specific agent.
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
  Delete a specific memory entry for an agent.
  """
  def delete(agent_id, key) do
    pattern = {agent_id, key, :"$1", :"$2"}
    case :ets.match_delete(@table_name, pattern) do
      n when n > 0 -> {:ok, :deleted}
      0 -> {:error, :not_found}
    end
  end

  @doc """
  Clear all memory for a specific agent.
  """
  def clear_agent_memory(agent_id) do
    pattern = {agent_id, :"$1", :"$2", :"$3"}
    :ets.match_delete(@table_name, pattern)
    {:ok, :cleared}
  end

  @doc """
  Search memory entries by pattern.
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
    # Remove entries older than 7 days
    cutoff_date = DateTime.add(DateTime.utc_now(), -7, :day)
    
    all_entries = :ets.tab2list(@table_name)
    
    Enum.each(all_entries, fn {agent_id, key, _value, timestamp} ->
      if DateTime.compare(timestamp, cutoff_date) == :lt do
        pattern = {agent_id, key, :"$1", :"$2"}
        :ets.match_delete(@table_name, pattern)
      end
    end)
    
    Logger.debug("Memory cleanup completed")
  end
end
