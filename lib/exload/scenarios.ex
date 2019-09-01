
defmodule Exload.Scenarios do
  @moduledoc """
  A supervisor for all scenarios
  """

  use DynamicSupervisor

  @doc """
  Start this supervisor and add it to the supervision
  tree
  """
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Define a new dynamic supervisor, so that we
  can add scenarios later on
  """
  @impl true
  def init(args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: args
    )
  end
  
  @doc """
  Start a new scenario for the given params
  """
  def add(params) do
    spec = {Exload.Scenario, params}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end


  @doc """
  Terminates all children. This function might perform
  badly if there are many scenarios running, which is not 
  expected anyway
  """
  def kill_all() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)
  end

end
