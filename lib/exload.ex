defmodule Exload do
  @moduledoc """
  Exload keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defstruct [scenario: :undef, spec: [], vus: 1, iterations: 1]  

  @doc """
  Kill all running scenarios
  """
  def kill_all() do
    Exload.Scenarios.kill_all()
    :ok
  end
  
  @scenarios Application.get_env(:Exload, :scenarios)

  @doc """
  Start a new run of the given scenario, for the
  given number of virtual users and the given number of
  iterations, for each user. By default, if an instance
  of that scenario is already running, or paused, this
  function will return an error.
  """
  def run(scenario, vus, its) do
    case Keyword.fetch(@scenarios, scenario) do
      {:ok, spec} ->
        case function_exported?(spec[:module], :__info__, 1) do
          true ->
            params = %Exload{
              scenario: scenario,
              spec: spec,
              vus: vus, 
              iterations: its
            }
            case Exload.Scenarios.add(params) do
              {:ok, _} ->
                Exload.Scenario.Manager.scale(scenario)
              other ->
                other
            end
          false ->
            {:error, :unknown_scenario_module}
        end
      :error ->
        {:error, :unknown_scenario}
      other ->
        {:error, other}
    end
  end

  @doc """
  Get a scenario info
  """
  def info(scenario) do
    Exload.Scenario.Manager.info(scenario)
  end

  @doc """
  Kill a virtual user in the given scenario. This might be
  useful when a virtual user gets stuck
  """
  def kill(scenario, vu) do
    Exload.Scenario.Manager.kill(scenario, vu)
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

end

