defmodule DiscrotWeb.RoomChannel do
  alias Discrot.ServerAgent
  alias DiscrotWeb.Presence
  alias Discrot.MessageStore
  alias Discrot.DmStore
  use DiscrotWeb, :channel

  @channels %{
    "1": [
      %{ id: 1, name: "general" }
    ]
  }

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), "after_join")
      ServerAgent.add_server("General Server", "🌐")
      {:ok, socket |> assign(servers: ServerAgent.list_servers(),channels: @channels)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("room:" <> private_room, payload, socket) do
    private_room |> IO.inspect()
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("dm:" <> usernames, _payload, socket) do
    usernames = String.split(usernames, ":")
    [user1, user2] = usernames |> Enum.sort()
    {:ok, socket |> assign(:dm_users, {user1, user2})}
  end

  @impl true
  def handle_info("after_join", %{assigns: %{channels: channels}} = socket) do
    Presence.track(self(), "after_join", socket.id, %{})

    data =
      Presence.list("after_join")
      |> Enum.flat_map(fn {_id, %{metas: metas}} -> metas end) |> IO.inspect()

    servers = ServerAgent.list_servers()

    push(socket, "list_user", %{data: data})
    push(socket, "list_server", %{data: servers})
    push(socket, "list_channels", %{data: channels})
    {:noreply, socket}
  end

  def handle_in("join_notif", %{"server_name" => server_name, "username" => username}, socket) do
    server_name |> IO.inspect()
    username |> IO.inspect()
    broadcast(socket, "notif_join", %{server_name: server_name, username: username})
    {:noreply, socket}
  end

  def handle_in("newUser", %{"username" => username}, socket) do
    Presence.update(self(), "after_join", socket.id, %{
      id: inspect(socket.channel_pid),
      user: username
    }) |> IO.inspect()

    username |> IO.inspect()

    broadcast_from(socket, "newUser", %{newUser: username})
    {:noreply, socket}
  end

  def handle_in("message", %{"sender" => sender, "text" => text, "server_id" => server_id}, socket) do
    message = %{sender: sender, text: text}
    MessageStore.add_message(server_id, message)
    broadcast(socket, "message", message)
    {:noreply, socket}
  end

  def handle_in("fetch_messages", %{"server_id" => server_id}, socket) do
    messages = MessageStore.get_messages(server_id)
    push(socket, "load_messages", %{messages: messages})
    {:noreply, socket}
  end

  # %{assigns: %{servers: servers}} =
  def handle_in("new_server", %{"icon" => icon, "name" => name},  socket) do
    ServerAgent.add_server(name, icon)
    # new_channel = %{id: new_server.id, name: "general"}
    # updated_channels = Map.put_new(channels, "#{new_server.id}", [new_channel], fn existing_channels ->
    #   [new_channel | existing_channels]
    # end)
    servers = ServerAgent.list_servers()
    broadcast(socket, "list_server", %{data: servers})
    # broadcast(socket, "list_channels", %{data: updated_channels})
    {:noreply, socket}
  end

  # private chat event
   # Handle sending a DM message
   def handle_in("send_dm", %{"sender" => sender, "text" => text}, socket) do
    {user1, user2} = socket.assigns.dm_users
    message = %{sender: sender, text: text}

    # Save message to the MessageStore
    DmStore.add_dm(user1, user2, message)

    # Broadcast the message to both users
    broadcast_from!(socket, "new_dm", %{sender: sender, text: text})
    {:noreply, socket}
  end

  # Handle fetching DM history
  def handle_in("fetch_dm_history", _payload, socket) do
    {user1, user2} = socket.assigns.dm_users
    messages = DmStore.get_dms(user1, user2)
    push(socket, "dm_history", %{messages: messages})
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
