defmodule Exload.Scenario.Vu do
  @moduledoc """
  A worker process that manages the lifecycle of a single
  virtual user
  """

  use GenStateMachine, callback_mode: :state_functions, restart: :temporary

  alias Exload.Scenario.Manager
  
  defstruct [spec: %Exload{}, data: :undef, start: :undef, finish: :undef] 

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
  def init(%Exload{}=args) do
    data = %__MODULE__{spec: args}
    {:ok, :idle, data, [{:next_event, :internal, :notify}]}
  end

  @doc """
  Notify the manager process that the virtual user
  process is ready
  """
  def idle(:internal, :notify, %__MODULE__{spec: %Exload{scenario: scenario}}=data) do
    :ok = :pg2.join({scenario, :vus}, self())
    :ok = Manager.notify_vu_ready(scenario, self())
    {:next_state, :idle, data}
  end

  @doc """
  We are instructed to start running the scenario
  """
  def idle({:call, from}, :start, %__MODULE__{
    spec: %Exload{spec: [
      module: mod
    ]}
  }=data) do
    case mod.init() do
      {:ok, state} ->
        start = DateTime.utc_now()
        case mod.run(state) do
          :done ->
            finish = DateTime.utc_now()
            IO.puts "Elapsed: #{DateTime.diff(finish, start, :millisecond)}"
            {:next_state, :running, %{ data | 
              start: start,
              finish: finish,
              data: state}, [{:reply, from, :ok}]}
          other ->
            {:stop, :error, other}
        end
      other ->
        {:stop, :error, other} 
    end
  end

end
