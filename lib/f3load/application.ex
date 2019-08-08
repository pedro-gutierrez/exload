defmodule F3load.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    
    # Build a consumer per configured queue
    children = [ F3loadWeb.Endpoint |
      F3load.Sqs.consumers()
      |> Enum.map(fn [name: q, opts: opts] ->
        worker(F3load.SqsConsumer, [q|opts], name: q)
      end)
    ]
    
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: F3load.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    F3loadWeb.Endpoint.config_change(changed, removed)
    :ok
  end


  def print_sqs(queue, messages) do
    IO.puts "messages from " <> queue
    IO.inspect messages
  end
end
