defmodule Exload.Scenario.Vu do
  @moduledoc """
  A worker process that manages the lifecycle of a single
  virtual user
  """

  use GenStateMachine, callback_mode: :state_functions, restart: :temporary

  alias Exload.Scenario.Manager


  @doc """
  Start this scenario manager and add it to the supervision tree
  """
  def start_link(args)  do
    GenStateMachine.start_link(__MODULE__, args)
  end

  @doc """
  Initialize the virtual user worker.
  """
  @impl true
  def init(args) do
    {:ok, :idle, args, [{:next_event, :internal, :notify}]}
  end


  @doc """
  Notify the manager process that the virtual user
  process is ready
  """
  def idle(:internal, :notify, %Exload{scenario: scenario}=data) do
    :ok = Manager.notify_vu_ready(scenario, self())
    {:next_state, :idle, data}
  end

end
