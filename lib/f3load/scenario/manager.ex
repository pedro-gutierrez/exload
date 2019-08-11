defmodule F3load.Scenario.Manager do
  @moduledoc """
  A worker process that manages the lifecycle and
  all resources associated to a scenario.
  """

  use GenServer


  defp registered_name(args) do
    "#{args[:scenario]}_manager" |> String.to_atom
  end

  @doc """
  Start this scenario manager and add it to the supervision tree
  """
  def start_link(args)  do
    GenServer.start_link(__MODULE__, args, name: registered_name(args))
  end


  @impl true
  def init(args) do
    IO.puts "started scenario manager #{args[:scenario]}"
    {:ok, args}
  end


end
