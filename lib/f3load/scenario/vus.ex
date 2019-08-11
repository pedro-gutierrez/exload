defmodule F3load.Scenario.Vus do
  @moduledoc """
  A supervisor module for all virtual users involved
  in a scenario
  """

  use DynamicSupervisor


  # Defines the name under which this supervisor will
  # be registered
  defp registered_name(args) do
    "#{args[:scenario]}_vus" |> String.to_atom
  end

  @doc """
  Start this supervisor. Initially it will not have any
  children, until it is scaled up
  """
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: registered_name(args))
  end

  @doc """
  Initialize the supervisor.
  """
  @impl true
  def init(args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: args
    )
  end

  @doc """
  Add a new virtual user, with the given arguments
  """
  def add(args) do
    spec = {F3load.Scenario.Vu, []}
    DynamicSupervisor.start_child(registered_name(args), spec)
  end


end
