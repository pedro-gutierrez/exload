defmodule F3load.Scenario do
  @moduledoc """
  A supervisor for a single scenario. A scenario
  is composed of a controller process, and
  many virtual user workers
  """

  use Supervisor

  @doc """
  Start this supervisor and add it to the supervision
  tree
  """
  def start_link([scenario: name, vus: _vus, iterations: _its]=args) do
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @doc """
  Define a new simple supervisor
  """
  @impl true
  def init(args) do
    Supervisor.init([
      {F3load.Scenario.Manager, args},
      {F3load.Scenario.Vus, args}
    ], strategy: :one_for_one)
  end

end
