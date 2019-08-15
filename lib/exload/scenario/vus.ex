defmodule Exload.Scenario.Vus do
  @moduledoc """
  A supervisor module for all virtual users involved
  in a scenario
  """

  use DynamicSupervisor


  # Defines the name under which this supervisor will
  # be registered
  defp registered_name(scenario) do
    "#{scenario}_vus" |> String.to_atom
  end

  @doc """
  Start this supervisor. Initially it will not have any
  children, until it is scaled up
  """
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: registered_name(args[:scenario]))
  end

  @doc """
  Initialize the supervisor.
  """
  @impl true
  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [])
  end

  @doc """
  Add that amount of virtual users to the given scenario
  """
  def add(%{:scenario => scenario,
            :vus => vus,
            :iterations => its}) do
    spec = {Exload.Scenario.Vu, scenario: scenario, vus: vus, iterations: its}
    vus_supervisor = registered_name(scenario)
    1..vus |> Enum.each(fn _ ->
      DynamicSupervisor.start_child(vus_supervisor, spec)
    end)
  end



end
