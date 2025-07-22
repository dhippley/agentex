defmodule Agentex.Memory.PersistentMemory do
  @moduledoc """
  Ecto schema for persistent memory storage with vector embeddings.
  Stores agent memories in PostgreSQL with pgvector for similarity search.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Agentex.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "memories" do
    field :agent_id, :string
    field :content, :string
    field :metadata, :map, default: %{}
    field :embedding, Pgvector.Ecto.Vector
    field :importance, :float, default: 0.5

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for memory creation and updates.
  """
  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [:agent_id, :content, :metadata, :embedding, :importance])
    |> validate_required([:agent_id, :content, :embedding])
    |> validate_length(:content, min: 1, max: 10_000)
    |> validate_number(:importance, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end

  @doc """
  Stores a new memory for an agent with vector embedding.
  """
  def store_memory(agent_id, content, metadata \\ %{}, importance \\ 0.5) do
    # Generate embedding for the content
    embedding = Agentex.Memory.Embeddings.generate_embedding(content)

    %__MODULE__{}
    |> changeset(%{
      agent_id: agent_id,
      content: content,
      metadata: metadata,
      embedding: embedding,
      importance: importance
    })
    |> Repo.insert()
  end

  @doc """
  Retrieves memories for an agent using vector similarity search.
  Returns memories sorted by relevance to the query.
  """
  def search_memories(agent_id, query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    threshold = Keyword.get(opts, :threshold, 0.7)

    # Generate embedding for the query
    query_embedding = Agentex.Memory.Embeddings.generate_embedding(query)

    from(m in __MODULE__,
      where: m.agent_id == ^agent_id,
      order_by: [desc: fragment("? <=> ?", m.embedding, ^query_embedding)],
      where: fragment("? <=> ?", m.embedding, ^query_embedding) < ^(1 - threshold),
      limit: ^limit,
      select: %{
        id: m.id,
        content: m.content,
        metadata: m.metadata,
        importance: m.importance,
        similarity: fragment("1 - (? <=> ?)", m.embedding, ^query_embedding),
        created_at: m.created_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Retrieves recent memories for an agent.
  """
  def get_recent_memories(agent_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(m in __MODULE__,
      where: m.agent_id == ^agent_id,
      order_by: [desc: m.created_at],
      limit: ^limit,
      select: %{
        id: m.id,
        content: m.content,
        metadata: m.metadata,
        importance: m.importance,
        created_at: m.created_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Retrieves important memories for an agent.
  """
  def get_important_memories(agent_id, opts \\ []) do
    min_importance = Keyword.get(opts, :min_importance, 0.8)
    limit = Keyword.get(opts, :limit, 10)

    from(m in __MODULE__,
      where: m.agent_id == ^agent_id and m.importance >= ^min_importance,
      order_by: [desc: m.importance, desc: m.created_at],
      limit: ^limit,
      select: %{
        id: m.id,
        content: m.content,
        metadata: m.metadata,
        importance: m.importance,
        created_at: m.created_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Updates the importance score of a memory.
  """
  def update_importance(memory_id, importance) do
    from(m in __MODULE__, where: m.id == ^memory_id)
    |> Repo.update_all(set: [importance: importance, updated_at: DateTime.utc_now()])
  end

  @doc """
  Deletes old memories for an agent, keeping only the most recent and important ones.
  """
  def cleanup_old_memories(agent_id, opts \\ []) do
    keep_recent = Keyword.get(opts, :keep_recent, 100)
    keep_important = Keyword.get(opts, :min_importance, 0.8)

    # Get IDs of memories to keep (recent ones)
    recent_ids =
      from(m in __MODULE__,
        where: m.agent_id == ^agent_id,
        order_by: [desc: m.created_at],
        limit: ^keep_recent,
        select: m.id
      )
      |> Repo.all()

    # Get IDs of memories to keep (important ones)
    important_ids =
      from(m in __MODULE__,
        where: m.agent_id == ^agent_id and m.importance >= ^keep_important,
        select: m.id
      )
      |> Repo.all()

    # Combine and get unique IDs to keep
    keep_ids = Enum.uniq(recent_ids ++ important_ids)

    # Delete memories not in the keep list
    from(m in __MODULE__,
      where: m.agent_id == ^agent_id and m.id not in ^keep_ids
    )
    |> Repo.delete_all()
  end
end
