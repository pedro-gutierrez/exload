defmodule Exload.Scenario.Manager do
  @moduledoc """
  A worker process that manages the lifecycle and
  all resources associated to a scenario.
  """

  use GenStateMachine, callback_mode: :state_functions


  defp registered_name(scenario) do
    "#{scenario}_manager" |> String.to_atom
  end

  @doc """
  A new virtual user process is ready. We should
  notify the manager for the scenario
  """
  def notify_vu_ready(scenario) do
    name = registered_name(scenario)
    GenStateMachine.call(name, :vu)
  end

  @doc """
  Start this scenario manager and add it to the supervision tree
  """
  def start_link(args)  do
    GenStateMachine.start_link(__MODULE__, args, name: registered_name(args[:scenario]))
  end

  @doc """
  Scale the scenario to the number of virtual users
  initially configured
  """
  def scale(scenario) do
    name = registered_name(scenario)
    GenStateMachine.call(name, :scale)
  end

  @impl true
  def init(args) do
    %{ :vus => vus } = data = args |> Enum.into(%{})
    {:ok, :idle, Map.put(data, :rem, vus)}
  end

  @doc """
  Start scaling the scenario
  """
  def idle({:call, from}, :scale, %{:rem => vus}=data) do
    Exload.Scenario.Vus.add(data)
    {:next_state, :scaling, %{ data | :rem => vus}, [{:reply, from, :ok}]}
  end

  @doc """
  We received a notification from one of the virtual
  user processes that it is ready.
  """
  def scaling({:call, from}, :vu, %{ :rem => 1 }=data) do
    IO.puts "scaled!"
    {:next_state, :ready, %{ data | :rem => 0}, [{:reply, from, :ok}]}
  end

  @doc """
  We received a notification from one of the virtual
  user processes that it is ready.
  """
  def scaling({:call, from}, :vu, %{ :rem => rem }=data) do
    {:next_state, :scaling, %{ data | :rem => rem-1}, [{:reply, from, :ok}]}
  end







end
