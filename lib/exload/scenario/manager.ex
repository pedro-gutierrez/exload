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
    :ok = :pg2.create({scenario, :vus})
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
    case data.pending do
      0 ->
        {:next_state, :starting, data, [
          {:reply, from, :ok}, 
          {:next_event, :internal, :start_vus}]}
      _ ->
        {:keep_state, data, [{:reply, from, :ok}]}
    end
  end
  
  @doc """
  Return the current scenario info
  """
  def scaling({:call, from}, :info, data) do
    {:keep_state, data, [{:reply, from, {:ok, scenario_info(data)}}]}
  end
  
  @doc """
  Kill some virtual users. Here we limit the max number of vus to 
  be killed to 10
  """
  def scaling({:call, from}, {:kill, vus}, data) do
    {:keep_state, data, [{:reply, from, kill_vus(vus, data)}]}
  end

  @doc """
  Instruct all vus to start performing their iterations
  """
  def starting(:internal, :start_vus, %__MODULE__{
    spec: %Exload{scenario: scenario}
  }=data) do
    ## TODO: Instruct all virtual users to start to
    ## perform their iterations. Since this is a load test,
    ## we might need a more scalable way to do this
    {scenario, :vus}
    |> :pg2.get_members
    |> Enum.each(fn pid -> 
      :ok = GenStateMachine.call(pid, :start)
    end)
    {:next_state, :running, data}
  end
  
  @doc """
  Return the current scenario info
  """
  def starting({:call, from}, :info, data) do
    {:keep_state, data, [{:reply, from, {:ok, scenario_info(data)}}]}
  end
  
  @doc """
  Kill some virtual users. Here we limit the max number of vus to 
  be killed to 10
  """
  def starting({:call, from}, {:kill, vus}, data) do
    {:keep_state, data, [{:reply, from, kill_vus(vus, data)}]}
  end

  @doc """
  Kill some virtual users. Here we limit the max number of vus to 
  be killed to 10
  """
  def running({:call, from}, {:kill, vus}, data) do
    {:keep_state, data, [{:reply, from, kill_vus(vus, data)}]}
  end
  

  @doc """
  Return the current scenario info
  """
  def running({:call, from}, :info, data) do
    {:keep_state, data, [{:reply, from, {:ok, scenario_info(data)}}]}
  end

  @doc """
  React when a virtual user process dies. Delete the entries
  in our bag, and update our internal state so that 
  in can later be returned to the user, via the info/1 api
  function
  """
  def running(:info, {:DOWN, ref, :process, pid, :killed}, %__MODULE__{
    bag: bag, 
    running: running,
    error: error
  }=data) do
    {:ok, bag} = Ets.Bag.delete(bag, {:vu, pid})
    Process.demonitor(ref)
    {:keep_state, %{ data | bag: bag, error: error+1, running: running-1}}
  end


  ## Translate the internal state into an external
  ## info datastructure
  defp scenario_info(%__MODULE__{
    error: error,
    running: running,
    pending: pending,
    spec: %Exload{scenario: scenario, vus: vus, iterations: iterations}
  }) do
    [
      scenario: scenario,
      vus: [
        total: vus,
        success: 0,
        running: running,
        pending: pending,
        failed: error
      ],
      iterations: iterations,
      latency: [
        ms10: 0,
        ms25: 0,
        ms50: 0,
        ms100: 0,
        ms250: 0,
        ms500: 0,
        ms1000: 0,
        inf: 0
      ]
    ]
  end
  
  defp kill_vus(vus, %__MODULE__{bag: bag}) when vus < 11 do
    {:ok, {pids, _}} = Ets.Bag.match(bag, {:vu, :"$1"}, vus)
    pids
    |> Enum.each(fn [pid] ->
       Process.exit(pid, :kill)
    end)
    {:ok, length(pids)}
  end

end
