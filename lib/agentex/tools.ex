defmodule Agentex.Tools do
  @moduledoc """
  Tools that agents can use to perform various tasks and gather information.
  """

  @doc """
  Returns the list of available tools for agents.
  """
  def available_tools do
    [
      %{
        name: "search_web",
        description: "Search the web for information",
        parameters: %{
          type: "object",
          properties: %{
            query: %{type: "string", description: "Search query"}
          },
          required: ["query"]
        }
      },
      %{
        name: "calculate",
        description: "Perform mathematical calculations",
        parameters: %{
          type: "object", 
          properties: %{
            expression: %{type: "string", description: "Mathematical expression to evaluate"}
          },
          required: ["expression"]
        }
      },
      %{
        name: "get_current_time",
        description: "Get the current date and time",
        parameters: %{
          type: "object",
          properties: %{
            timezone: %{type: "string", description: "Timezone (optional)", default: "UTC"}
          }
        }
      },
      %{
        name: "store_memory",
        description: "Store information in agent memory",
        parameters: %{
          type: "object",
          properties: %{
            key: %{type: "string", description: "Memory key"},
            value: %{type: "string", description: "Value to store"}
          },
          required: ["key", "value"]
        }
      },
      %{
        name: "retrieve_memory",
        description: "Retrieve information from agent memory",
        parameters: %{
          type: "object",
          properties: %{
            key: %{type: "string", description: "Memory key to retrieve"}
          },
          required: ["key"]
        }
      }
    ]
  end

  @doc """
  Execute a tool with the given parameters.
  """
  def execute_tool(tool_name, parameters, context \\ %{}) do
    case tool_name do
      "search_web" -> search_web(parameters)
      "calculate" -> calculate(parameters)
      "get_current_time" -> get_current_time(parameters)
      "store_memory" -> store_memory(parameters, context)
      "retrieve_memory" -> retrieve_memory(parameters, context)
      _ -> {:error, {:unknown_tool, tool_name}}
    end
  end

  ## Tool Implementations

  defp search_web(%{"query" => query}) do
    # Mock web search implementation
    # In a real implementation, you'd integrate with a search API
    results = [
      %{
        title: "Mock Search Result 1",
        url: "https://example.com/1",
        snippet: "This is a mock search result for: #{query}"
      },
      %{
        title: "Mock Search Result 2", 
        url: "https://example.com/2",
        snippet: "Another mock result related to: #{query}"
      }
    ]
    
    {:ok, %{query: query, results: results}}
  end

  defp search_web(_), do: {:error, :invalid_parameters}

  defp calculate(%{"expression" => expression}) do
    # Simple calculator - in production you'd want a safer evaluation method
    try do
      # Basic math operations only for security
      sanitized = String.replace(expression, ~r/[^0-9+\-*\/().\s]/, "")
      
      case Code.eval_string(sanitized) do
        {result, _} when is_number(result) -> 
          {:ok, %{expression: expression, result: result}}
        _ -> 
          {:error, :invalid_expression}
      end
    rescue
      _ -> {:error, :calculation_error}
    end
  end

  defp calculate(_), do: {:error, :invalid_parameters}

  defp get_current_time(parameters) do
    timezone = Map.get(parameters, "timezone", "UTC")
    
    case timezone do
      "UTC" ->
        time = DateTime.utc_now()
        {:ok, %{timezone: timezone, current_time: DateTime.to_iso8601(time)}}
      _ ->
        # For simplicity, just return UTC. In production, use a timezone library
        time = DateTime.utc_now()
        {:ok, %{timezone: "UTC", current_time: DateTime.to_iso8601(time)}}
    end
  end

  defp store_memory(%{"key" => key, "value" => value}, context) do
    agent_id = Map.get(context, :agent_id)
    
    if agent_id do
      # Store in ETS or agent state
      Agentex.Memory.store(agent_id, key, value)
      {:ok, %{key: key, stored: true}}
    else
      {:error, :no_agent_context}
    end
  end

  defp store_memory(_, _), do: {:error, :invalid_parameters}

  defp retrieve_memory(%{"key" => key}, context) do
    agent_id = Map.get(context, :agent_id)
    
    if agent_id do
      case Agentex.Memory.retrieve(agent_id, key) do
        {:ok, value} -> {:ok, %{key: key, value: value}}
        {:error, :not_found} -> {:ok, %{key: key, value: nil}}
        error -> error
      end
    else
      {:error, :no_agent_context}
    end
  end

  defp retrieve_memory(_, _), do: {:error, :invalid_parameters}
end
