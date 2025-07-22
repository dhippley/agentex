defmodule Agentex.Repo.Migrations.CreateMemoriesTable do
  use Ecto.Migration

  def change do
    # Enable the pgvector extension
    execute "CREATE EXTENSION IF NOT EXISTS vector", "DROP EXTENSION IF EXISTS vector"

    create table(:memories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :agent_id, :string, null: false
      add :content, :text, null: false
      add :metadata, :map, default: %{}
      add :embedding, :vector, size: 384, null: false
      add :importance, :float, default: 0.5
      add :created_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:memories, [:agent_id])
    create index(:memories, [:created_at])
    create index(:memories, [:importance])

    # Create a vector similarity index for fast nearest neighbor search
    execute """
    CREATE INDEX memories_embedding_cosine_idx
    ON memories
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100)
    """, "DROP INDEX IF EXISTS memories_embedding_cosine_idx"
  end
end
