defmodule Discrot.ServerAgent do
  use Agent

  defmodule Server do
    @derive Jason.Encoder
    defstruct [:id, :name, :icon]
  end

  def start_link(initial_state \\ []) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def add_server(name, icon) do
    Agent.update(__MODULE__, fn state ->
      new_id = if state == [], do: 1, else: Enum.max_by(state, & &1.id).id + 1
      new_server = %Server{id: new_id, name: name, icon: icon}
      is_ada = state |> Enum.any?(fn e -> e.name == name end) |> IO.inspect()
      if !is_ada do
        state ++ [new_server]
      else
        state
      end
    end)
  end

  def list_servers do
    Agent.get(__MODULE__, & &1)
  end
end
