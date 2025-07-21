defmodule AgentexWeb.AgentLive do
  @moduledoc """
  LiveView for interacting with AI agents.
  """
  use AgentexWeb, :live_view
  
  alias Agentex
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to agent updates
      PubSub.subscribe(Agentex.PubSub, "agents")
    end

    socket = 
      socket
      |> assign(:agents, Agentex.list_agents())
      |> assign(:stats, Agentex.get_stats())
      |> assign(:selected_agent, nil)
      |> assign(:messages, [])
      |> assign(:current_message, "")
      |> assign(:task_input, "")
      |> assign(:new_agent_name, "")
      |> assign(:new_agent_prompt, "")
      |> assign(:show_create_form, false)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_agent", %{"agent_id" => agent_id}, socket) do
    # Subscribe to this agent's updates
    if socket.assigns.selected_agent do
      PubSub.unsubscribe(Agentex.PubSub, "agent:#{socket.assigns.selected_agent}")
    end
    
    PubSub.subscribe(Agentex.PubSub, "agent:#{agent_id}")
    
    # Get agent state and conversation history
    case Agentex.get_agent_state(agent_id) do
      {:ok, state} ->
        messages = Enum.reverse(state.conversation_history)
        
        socket = 
          socket
          |> assign(:selected_agent, agent_id)
          |> assign(:messages, messages)
        
        {:noreply, socket}
        
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Agent not found")}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    case socket.assigns.selected_agent do
      nil ->
        {:noreply, put_flash(socket, :error, "Please select an agent first")}
      
      agent_id when message != "" ->
        socket = assign(socket, :loading, true)
        
        # Send message asynchronously
        send(self(), {:send_message_async, agent_id, message})
        
        # Clear input and show loading
        socket = 
          socket
          |> assign(:current_message, "")
          |> assign(:loading, true)
        
        {:noreply, socket}
      
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("assign_task", %{"task" => task}, socket) do
    case socket.assigns.selected_agent do
      nil ->
        {:noreply, put_flash(socket, :error, "Please select an agent first")}
      
      agent_id when task != "" ->
        case Agentex.assign_task(agent_id, task) do
          {:ok, :task_assigned} ->
            socket = 
              socket
              |> assign(:task_input, "")
              |> put_flash(:info, "Task assigned to agent")
            
            {:noreply, socket}
          
          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to assign task: #{inspect(reason)}")}
        end
      
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_agent", %{"name" => name, "prompt" => prompt}, socket) do
    case name do
      "" ->
        {:noreply, put_flash(socket, :error, "Agent name is required")}
      
      _ ->
        opts = if prompt != "", do: [system_prompt: prompt], else: []
        
        case Agentex.create_agent(name, opts) do
          {:ok, _agent_id} ->
            socket = 
              socket
              |> assign(:new_agent_name, "")
              |> assign(:new_agent_prompt, "")
              |> assign(:show_create_form, false)
              |> assign(:agents, Agentex.list_agents())
              |> put_flash(:info, "Agent created successfully")
            
            {:noreply, socket}
          
          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to create agent: #{inspect(reason)}")}
        end
    end
  end

  @impl true
  def handle_event("toggle_create_form", _params, socket) do
    {:noreply, assign(socket, :show_create_form, not socket.assigns.show_create_form)}
  end

  @impl true
  def handle_event("stop_agent", %{"agent_id" => agent_id}, socket) do
    case Agentex.stop_agent(agent_id) do
      :ok ->
        socket = 
          socket
          |> assign(:agents, Agentex.list_agents())
          |> assign(:selected_agent, if(socket.assigns.selected_agent == agent_id, do: nil, else: socket.assigns.selected_agent))
          |> put_flash(:info, "Agent stopped")
        
        {:noreply, socket}
      
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to stop agent: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("update_message", %{"value" => value}, socket) do
    {:noreply, assign(socket, :current_message, value)}
  end

  @impl true
  def handle_event("update_task", %{"value" => value}, socket) do
    {:noreply, assign(socket, :task_input, value)}
  end

  @impl true
  def handle_event("update_agent_name", %{"value" => value}, socket) do
    {:noreply, assign(socket, :new_agent_name, value)}
  end

  @impl true
  def handle_event("update_agent_prompt", %{"value" => value}, socket) do
    {:noreply, assign(socket, :new_agent_prompt, value)}
  end

  @impl true
  def handle_info({:send_message_async, agent_id, message}, socket) do
    case Agentex.send_message(agent_id, message) do
      {:ok, _response} ->
        # The response will come through PubSub
        {:noreply, assign(socket, :loading, false)}
      
      {:error, reason} ->
        socket = 
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Failed to send message: #{inspect(reason)}")
        
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:agent_state_update, state}, socket) do
    if state.agent_id == socket.assigns.selected_agent do
      messages = Enum.reverse(state.conversation_history)
      socket = assign(socket, :messages, messages)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:task_completed, %{agent_id: agent_id}}, socket) do
    if agent_id == socket.assigns.selected_agent do
      socket = put_flash(socket, :info, "Task completed!")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:task_error, %{agent_id: agent_id, reason: reason}}, socket) do
    if agent_id == socket.assigns.selected_agent do
      socket = put_flash(socket, :error, "Task failed: #{inspect(reason)}")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_msg, socket) do
    # Update agents list and stats periodically
    socket = 
      socket
      |> assign(:agents, Agentex.list_agents())
      |> assign(:stats, Agentex.get_stats())
    
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-8">Agentex - AI Agent System</h1>
        
        <!-- Stats Dashboard -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-700">Total Agents</h3>
            <p class="text-3xl font-bold text-blue-600"><%= @stats.total_agents %></p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-700">Active</h3>
            <p class="text-3xl font-bold text-green-600"><%= @stats.active_agents %></p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-700">Working</h3>
            <p class="text-3xl font-bold text-yellow-600"><%= @stats.working_agents %></p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-700">Idle</h3>
            <p class="text-3xl font-bold text-gray-600"><%= @stats.idle_agents %></p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Agent List -->
          <div class="bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <div class="flex justify-between items-center">
                <h2 class="text-xl font-semibold text-gray-800">Agents</h2>
                <button 
                  phx-click="toggle_create_form"
                  class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                >
                  + New Agent
                </button>
              </div>
              
              <%= if @show_create_form do %>
                <div class="mt-4 p-4 bg-gray-50 rounded">
                  <input 
                    type="text" 
                    placeholder="Agent name"
                    phx-keyup="update_agent_name"
                    value={@new_agent_name}
                    class="w-full p-2 mb-2 border rounded"
                  />
                  <textarea 
                    placeholder="System prompt (optional)"
                    phx-keyup="update_agent_prompt"
                    class="w-full p-2 mb-2 border rounded h-20"
                  ><%= @new_agent_prompt %></textarea>
                  <div class="flex space-x-2">
                    <button 
                      phx-click="create_agent"
                      phx-value-name={@new_agent_name}
                      phx-value-prompt={@new_agent_prompt}
                      class="bg-green-500 hover:bg-green-700 text-white font-bold py-1 px-3 rounded"
                    >
                      Create
                    </button>
                    <button 
                      phx-click="toggle_create_form"
                      class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-1 px-3 rounded"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
            
            <div class="p-6">
              <%= for agent <- @agents do %>
                <div class={[
                  "p-4 mb-4 border rounded-lg cursor-pointer hover:bg-gray-50",
                  if(@selected_agent == agent.agent_id, do: "border-blue-500 bg-blue-50", else: "border-gray-300")
                ]}>
                  <div phx-click="select_agent" phx-value-agent_id={agent.agent_id}>
                    <h3 class="font-semibold text-gray-800"><%= agent.name %></h3>
                    <p class="text-sm text-gray-600">ID: <%= agent.agent_id %></p>
                    <div class="flex justify-between items-center mt-2">
                      <span class={[
                        "px-2 py-1 rounded text-xs font-semibold",
                        case agent.status do
                          :active -> "bg-green-100 text-green-800"
                          :working -> "bg-yellow-100 text-yellow-800"
                          :idle -> "bg-gray-100 text-gray-800"
                          :error -> "bg-red-100 text-red-800"
                        end
                      ]}>
                        <%= String.upcase(to_string(agent.status)) %>
                      </span>
                      <button 
                        phx-click="stop_agent"
                        phx-value-agent_id={agent.agent_id}
                        class="text-red-500 hover:text-red-700 text-sm"
                      >
                        Stop
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
              
              <%= if @agents == [] do %>
                <p class="text-gray-500 text-center">No agents running. Create one to get started!</p>
              <% end %>
            </div>
          </div>

          <!-- Chat Interface -->
          <div class="lg:col-span-2 bg-white rounded-lg shadow">
            <div class="p-6 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-800">
                <%= if @selected_agent do %>
                  Chat with Agent
                <% else %>
                  Select an agent to start chatting
                <% end %>
              </h2>
            </div>
            
            <%= if @selected_agent do %>
              <!-- Messages -->
              <div class="p-6 h-96 overflow-y-auto" id="messages">
                <%= for message <- @messages do %>
                  <div class={[
                    "mb-4 p-3 rounded-lg max-w-xs",
                    if message.role == :user do
                      "ml-auto bg-blue-500 text-white"
                    else
                      "mr-auto bg-gray-200 text-gray-800"
                    end
                  ]}>
                    <div class="text-sm"><%= message.content %></div>
                    <div class="text-xs mt-1 opacity-75">
                      <%= Calendar.strftime(message.timestamp, "%H:%M") %>
                    </div>
                  </div>
                <% end %>
                
                <%= if @loading do %>
                  <div class="mr-auto bg-gray-200 text-gray-800 mb-4 p-3 rounded-lg max-w-xs">
                    <div class="animate-pulse">Agent is thinking...</div>
                  </div>
                <% end %>
              </div>

              <!-- Message Input -->
              <div class="p-6 border-t border-gray-200">
                <form phx-submit="send_message" class="flex space-x-2">
                  <input 
                    type="text"
                    name="message"
                    placeholder="Type your message..."
                    phx-keyup="update_message"
                    value={@current_message}
                    disabled={@loading}
                    class="flex-1 p-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button 
                    type="submit" 
                    disabled={@loading || @current_message == ""}
                    class="bg-blue-500 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-3 px-6 rounded-lg"
                  >
                    Send
                  </button>
                </form>
              </div>

              <!-- Task Assignment -->
              <div class="p-6 border-t border-gray-200 bg-gray-50">
                <h3 class="text-sm font-semibold text-gray-700 mb-2">Assign Task</h3>
                <form phx-submit="assign_task" class="flex space-x-2">
                  <input 
                    type="text"
                    name="task"
                    placeholder="Describe a task for the agent..."
                    phx-keyup="update_task"
                    value={@task_input}
                    class="flex-1 p-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button 
                    type="submit"
                    disabled={@task_input == ""}
                    class="bg-green-500 hover:bg-green-700 disabled:bg-gray-400 text-white font-bold py-2 px-4 rounded"
                  >
                    Assign
                  </button>
                </form>
              </div>
            <% else %>
              <div class="p-6 flex items-center justify-center h-96">
                <p class="text-gray-500 text-center">
                  Select an agent from the list to start a conversation or assign tasks.
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
