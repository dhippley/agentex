defmodule Agentex.Memory.Embeddings do
  @moduledoc """
  Handles generating vector embeddings for text using sentence transformers.
  Uses Bumblebee with a pre-trained sentence transformer model for creating
  high-quality embeddings that can be used for semantic similarity search.
  """

  use GenServer
  require Logger

  @model_name "sentence-transformers/all-MiniLM-L6-v2"
  @embedding_size 384

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Generates a vector embedding for the given text.
  Returns a list of floats representing the embedding vector.
  """
  def generate_embedding(text) when is_binary(text) do
    GenServer.call(__MODULE__, {:generate_embedding, text}, 30_000)
  end

  @doc """
  Generates embeddings for a batch of texts.
  More efficient than calling generate_embedding/1 multiple times.
  """
  def generate_embeddings(texts) when is_list(texts) do
    GenServer.call(__MODULE__, {:generate_embeddings, texts}, 60_000)
  end

  @doc """
  Returns the size of the embedding vectors produced by this model.
  """
  def embedding_size, do: @embedding_size

  @impl true
  def init(_opts) do
    Logger.info("Loading embedding model: #{@model_name}")

    case load_model() do
      {:ok, model_info} ->
        Logger.info("Embedding model loaded successfully")
        {:ok, model_info}

      {:error, reason} ->
        Logger.error("Failed to load embedding model: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:generate_embedding, text}, _from, model_info) do
    result =
      case generate_embedding_internal([text], model_info) do
        {:ok, [embedding]} -> embedding
        {:error, reason} ->
          Logger.error("Failed to generate embedding: #{inspect(reason)}")
          # Return a zero vector as fallback
          List.duplicate(0.0, @embedding_size)
      end

    {:reply, result, model_info}
  end

  @impl true
  def handle_call({:generate_embeddings, texts}, _from, model_info) do
    result =
      case generate_embedding_internal(texts, model_info) do
        {:ok, embeddings} -> embeddings
        {:error, reason} ->
          Logger.error("Failed to generate embeddings: #{inspect(reason)}")
          # Return zero vectors as fallback
          Enum.map(texts, fn _ -> List.duplicate(0.0, @embedding_size) end)
      end

    {:reply, result, model_info}
  end

  # Private functions

  defp load_model do
    try do
      # Load the tokenizer
      {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @model_name})

      # Load the model
      {:ok, model} = Bumblebee.load_model({:hf, @model_name})

      # Create the serving for batch processing
      serving = Bumblebee.Text.TextEmbedding.text_embedding(model, tokenizer,
        output_pool: :mean_pooling,
        output_attribute: :hidden_state,
        embedding_processor: :l2_norm,
        compile: [batch_size: 32, sequence_length: 512],
        defn_options: [compiler: EXLA]
      )

      {:ok, %{serving: serving, tokenizer: tokenizer, model: model}}
    rescue
      error ->
        {:error, error}
    end
  end

  defp generate_embedding_internal(texts, %{serving: serving}) do
    try do
      # Process the texts through the model
      results = Nx.Serving.batched_run(serving, texts)

      # Extract embeddings and convert to lists
      embeddings =
        results
        |> Enum.map(fn %{embedding: embedding} ->
          embedding
          |> Nx.to_flat_list()
        end)

      {:ok, embeddings}
    rescue
      error ->
        {:error, error}
    end
  end
end
