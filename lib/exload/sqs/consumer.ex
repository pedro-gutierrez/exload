# A simple SQS consumer GenServer
# that continuously reads from a given queue
# and yields received messages to a different process
defmodule Exload.Sqs.Consumer do
  use GenServer

  # To be called from a supervisor spec
  def start_link(queue, m, f) do
    __MODULE__ |> GenServer.start_link([Exload.Sqs.config(), m, f, queue])
  end


  # The struct that defines the state of this
  # consumer. A SqsConsumer has:
  # (a) a callback module, and function
  # (b) the queue it consumes from
  # (c) the AWS config as defined by Erlcloud
  defmodule Data do
    defstruct callback: :undef, queue: :undef, config: :undef
  end

  @impl true
  # Initialize the state of the GenServer and
  # start receiving
  #
  # TODO: monitor the owner. If the owner crashes
  # then we can decide what to do (crash ourselves,
  # or wait for a new owner to be set -- not
  # implemented yet)
  def init([config, m, f, queue]) do
    {:ok, %Data{
      callback: {m, f},
      queue: Atom.to_string(queue),
      config: config}, {:continue, :receive}}
  end

  @impl true
  # Start receiving, as soon as this GenServer is ready
  # This is to avoid blocking the init callback
  def handle_continue(:receive, data) do
    recv(data)
  end

  @impl true
  # Start a new receive iteration
  def handle_info(:receive, data) do
    recv(data)
  end

  # Receive, yield and restart
  defp recv(%Data{config: config, callback: {mod, fun}, queue: queue}=data) do
    case config |> Exload.Sqs.receive(queue) do
      {:ok, messages} ->
        # Deliver the messages
        # in a separate process.
        # TODO: Monitor it, in case
        # the delivery failed
        _pid = spawn(mod, fun, [queue, messages])
        :ok

      :nodata ->
        # Do nothing
        :ok
      {:error, reason} ->
        # log it, for now, or send it to an error
        # channel
        IO.inspect reason
        :ok
    end

    # Remember ourselves to start listening
    # again for new messages
    self() |> send(:receive)
    {:noreply, data}
  end


end

