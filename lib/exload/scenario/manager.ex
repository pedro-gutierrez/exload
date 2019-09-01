defmodule Exload.Scenario.Manager do
  @moduledoc """
  A worker process that manages the lifecycle and
  all resources associated to a scenario.
  """

  use GenStateMachine, callback_mode: :state_functions
  
  defstruct [spec: %Exload{}, bag: :none, running: 0, pending: 0, error: 0]

  alias Exload.Scenario.Vus

  defp registered_name(scenario) do
    "#{scenario}_manager" |> String.to_atom
  end

  @doc """
  A new virtual user process is ready. We should
  notify the manager for the scenario
  """
  def notify_vu_ready(scenario, pid) do
    name = registered_name(scenario)
    GenStateMachine.call(name, {:vu, pid})
  end

  @doc """
  Start this scenario manager and add it to the supervision tree
  """
  def start_link(%Exload{scenario: name}=args)  do
    GenStateMachine.start_link(__MODULE__, args, name: registered_name(name))
  end

  @doc """
  Scale the scenario to the number of virtual users
  initially configured
  """
  def scale(scenario) do
    name = registered_name(scenario)
    GenStateMachine.call(name, :scale)
  end

  @doc """
  Return the current state of the scenario
  """
  def info(scenario) do
    name = registered_name(scenario)
    GenStateMachine.call(name, :info)
  end

  @doc """
  Kill the given vu in the given scenario
  """
  def kill(scenario, vu) do
    name = registered_name(scenario)
    GenStateMachine.call(name, {:kill, vu})
  end

  @impl true
  def init(%Exload{scenario: scenario, vus: vus}=spec) do
    {:ok, bag} = Ets.Bag.new(name: scenario, duplicate: true)
    data = %__MODULE__{spec: spec, bag: bag, pending: vus}
    {:ok, :idle, data}
  end

  @doc """
  Start scaling the scenario
  """
  def idle({:call, from}, :scale, data) do
    Vus.add(data)
    {:next_state, :scaling, data, [{:reply, from, :ok}]}
  end

  @doc """
  We received a notification from one of the virtual
  user processes that it is ready.
  """
  def scaling({:call, from}, {:vu, pid}, %__MODULE__{
    bag: bag, 
    running: running,
    pending: pending
  }=data) do
    ref = Process.monitor(pid)
    {:ok, ^bag} = Ets.Bag.add(bag, {:vu, pid})
    {:ok, ^bag} = Ets.Bag.add(bag, {:ref, ref})
    data = %{ data | pending: pending-1, running: (running+1)}
    next_state = case pending do
      1 -> :ready
      _ -> :scaling
    end
    {:next_state, next_state, data, [{:reply, from, :ok}]}
  end

  @doc """
  Kill some virtual users. Here we limit the max number of vus to 
  be killed to 10
  """
  def ready({:call, from}, {:kill, vus}, %__MODULE__{bag: bag}=data) 
  when vus < 11 do
    {:ok, {pids, _}} = Ets.Bag.match(bag, {:vu, :"$1"}, vus)
    pids
    |> Enum.each(fn [pid] ->
       Process.exit(pid, :kill)
      end)
    {:keep_state, data, [{:reply, from, {:ok, length(pids)}}]}
  end


  @doc """
  Return the current scenario info
  """
  def ready({:call, from}, :info, %__MODULE__{
    error: error,
    running: running,
    pending: pending,
    spec: %Exload{scenario: scenario, vus: vus, iterations: iterations}
  }=data) do
    info = [
        scenario: scenario,
        vus: [
          total: vus,
          success: 0,
          running: running,
          pending: pending,
          failed: error
        ],
        iterations: iterations,
    ]
    {:keep_state, data, [{:reply, from, {:ok, info}}]}
  end

  @doc """
  React when a virtual user process dies. Delete the entries
  in our bag, and update our internal state so that 
  in can later be returned to the user, via the info/1 api
  function
  """
  def ready(:info, {:DOWN, ref, :process, pid, :killed}, %__MODULE__{
    bag: bag, 
    running: running,
    error: error
  }=data) do
    {:ok, bag} = Ets.Bag.delete(bag, {:vu, pid})
    Process.demonitor(ref)
    {:keep_state, %{ data | bag: bag, error: error+1, running: running-1}}
  end

end
