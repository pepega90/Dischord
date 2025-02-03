defmodule Discrot.DmStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(:dm_messages, [:named_table, :public, :set])
    {:ok, nil}
  end

  # Add a DM
  def add_dm(user1, user2, message) do
    GenServer.call(__MODULE__, {:add_dm, user1, user2, message})
  end

  # Get DM history
  def get_dms(user1, user2) do
    GenServer.call(__MODULE__, {:get_dms, user1, user2})
  end

  @impl true
  def handle_call({:add_dm, user1, user2, message}, _from, state) do
    # Ensure consistent key order
    key = {Enum.min([user1, user2]), Enum.max([user1, user2])}

    case :ets.lookup(:dm_messages, key) do
      [] -> :ets.insert(:dm_messages, {key, [message]})
      [{^key, messages}] -> :ets.insert(:dm_messages, {key, [message | messages]})
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_dms, user1, user2}, _from, state) do
    key = {Enum.min([user1, user2]), Enum.max([user1, user2])}

    messages = case :ets.lookup(:dm_messages, key) do
      [{^key, messages}] -> Enum.reverse(messages)
      [] -> []
    end

    {:reply, messages, state}
  end
end
