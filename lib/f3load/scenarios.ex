
defmodule F3load.Scenarios do
  @moduledoc """
  A supervisor for all scenarios
  """

  use DynamicSupervisor

  @doc """
  Start a new run of the given scenario, for the
  given number of virtual users and the given number of
  iterations, for each user. By default, if an instance
  of that scenario is already running, or paused, this
  function will return an error.
  """
  def run(scenario, vus, its) do
    F3load.Scenarios.add(scenario, vus, its)
  end

  # List all scenarios running
  def list do
    {:error, :not_implemented}
  end

  # Pause a scenario.
  def pause(_scenario) do
    {:error, :not_implemented}
  end

  # Resume a scenario
  def resume(_scenario) do
    {:error, :not_implemented}
  end

  # Cancel a scenario
  def cancel(_scenario) do
    {:error, :not_implemented}
  end

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
  Start a new scenario
  """
  def add(scenario, vus, its) do
    spec = {F3load.Scenario, scenario: scenario, vus: vus, iterations: its}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

end
