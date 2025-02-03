defmodule Discrot.MessageStore do
  use GenServer

  # Start the GenServer and create the ETS table
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(:messages, [:named_table, :public, :set])
    {:ok, nil}
  end

  # Add a new message to the ETS table
  def add_message(server_id, message) do
    GenServer.call(__MODULE__, {:add_message, server_id, message})
  end

  # Get all messages for a server
  def get_messages(server_id) do
    GenServer.call(__MODULE__, {:get_messages, server_id})
  end

  @impl true
  def handle_call({:add_message, server_id, message}, _from, state) do
    case :ets.lookup(:messages, server_id) do
      [] -> :ets.insert(:messages, {server_id, [message]})
      [{^server_id, messages}] -> :ets.insert(:messages, {server_id, [message | messages]})
    end
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_messages, server_id}, _from, state) do
    messages = case :ets.lookup(:messages, server_id) do
      [{^server_id, messages}] -> Enum.reverse(messages)
      [] -> []
    end
    {:reply, messages, state}
  end
end
